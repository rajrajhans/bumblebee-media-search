defmodule MediaSearchDemo.Clip.Image do
  @moduledoc """
  Module wrapping image parts of the CLIP model
  """

  @batch_size 16

  alias MediaSearchDemo.Clip.Layers

  def embeddings(clip, featurizer, opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, @batch_size)
    defn_options = [compiler: EXLA]

    model = embeddings_model(clip)

    # Build the prediction defn function
    {_init_fun, predict_fun} = Axon.build(model)

    Nx.Serving.new(
      fn -> init(predict_fun, clip.params, batch_size, defn_options) end,
      batch_size: batch_size,
      batch_timeout: 20
    )
    |> Nx.Serving.client_preprocessing(&client_preprocessing(&1, featurizer))
  end

  def run_embeddings(image, serving \\ MediaSearchDemo.Clip.Image.Serving) do
    Nx.Serving.batched_run(
      serving,
      [image]
    )
    |> Nx.to_flat_list()
  end

  defp init(predict_fun, clip_params, batch_size, defn_options) do
    inputs_template = %{"pixel_values" => Nx.template({batch_size, 224, 224, 3}, :f32)}
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
    # CLIP model for image embeddings
    # same as Vision.ClipVision from bumblebee
    # but `with` the final projection layer and a custom normalization layer

    Bumblebee.Vision.ClipVision.model(clip.spec.vision_spec)
    |> Axon.nx(& &1.pooled_state)
    |> Axon.dense(512, use_bias: false, name: "visual_projection")
    |> Layers.normalize()
  end

  defp client_preprocessing(inputs, featurizer) do
    inputs =
      Bumblebee.apply_featurizer(
        featurizer,
        inputs
      )

    {Nx.Batch.concatenate([inputs]), %{}}
  end
end
