defmodule MediaSearchDemo.Clip.Text do
  @moduledoc """
  Module wrapping text parts of the CLIP model
  """

  @batch_size 10
  @sequence_length 42

  alias MediaSearchDemo.Clip.Layers

  def embeddings(clip, tokenizer, opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    sequence_length = Keyword.get(opts, :sequence_length, @sequence_length)
    defn_options = [compiler: EXLA]

    model = embeddings_model(clip)

    # Build the prediction defn function
    {_init_fun, predict_fun} = Axon.build(model)

    Nx.Serving.new(
      fn -> init(predict_fun, clip.params, batch_size, sequence_length, defn_options) end,
      batch_size: batch_size,
      batch_timeout: 20
    )
    |> Nx.Serving.client_preprocessing(&client_preprocessing(&1, tokenizer, sequence_length))
  end

  def run_embeddings(text, serving \\ MediaSearchDemo.Clip.Text.Serving) do
    Nx.Serving.batched_run(
      serving,
      [text]
    )
    |> Nx.to_flat_list()
  end

  defp init(predict_fun, clip_params, batch_size, sequence_length, defn_options) do
    inputs_template = %{"input_ids" => Nx.template({batch_size, sequence_length}, :s64)}
    template_args = [Nx.to_template(clip_params), inputs_template]

    # Compile the prediction function upfront for the configured batch_size
    predict_fun = Nx.Defn.compile(predict_fun, template_args, defn_options)

    # The returned function is called for every accumulated batch
    fn inputs ->
      inputs = Nx.Batch.pad(inputs, batch_size - inputs.size)
      predict_fun.(clip_params, inputs)
    end
  end

  defp embeddings_model(clip) do
    # CLIP model for text embeddings
    # same as Text.ClipText from bumblebee
    # but `with` the final projection layer and a custom normalization layer

    Bumblebee.Text.ClipText.model(clip.spec.text_spec)
    |> Axon.nx(& &1.pooled_state)
    |> Axon.dense(512, use_bias: false, name: "text_projection")
    |> Layers.normalize()
  end

  defp client_preprocessing(inputs, tokenizer, sequence_length) do
    inputs =
      Bumblebee.apply_tokenizer(
        tokenizer,
        inputs,
        # max
        length: sequence_length,
        return_token_type_ids: false,
        return_attention_mask: false
      )

    {Nx.Batch.concatenate([inputs]), %{}}
  end
end
