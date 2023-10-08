defmodule MediaSearchDemo.Clip.Servings.Bumblebee.Text do
  alias MediaSearchDemo.Clip.Servings.Constants

  @spec get_serving :: Nx.Serving.t()
  def get_serving() do
    model_info = clip_text_embeddings_model()
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, Constants.clip_hf_model()})

    Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer,
      output_attribute: :embedding,
      output_pool: nil,
      embedding_processor: nil
    )
  end

  def run_embeddings(text) do
    serving = MediaSearchDemo.Clip.Bumblebee.TextServing

    Nx.Serving.batched_run(
      serving,
      [text]
    )
  end

  defp clip_text_embeddings_model() do
    # CLIP model for text embeddings
    # same as Text.ClipText from bumblebee
    # but `with` the final projection layer

    {:ok, %{model: _multimodal_model, params: multimodal_params, spec: _multimodal_spec}} =
      Bumblebee.load_model({:hf, Constants.clip_hf_model()},
        architecture: :base
      )

    {:ok, %{model: text_model, params: text_params, spec: text_spec}} =
      Bumblebee.load_model({:hf, Constants.clip_hf_model()},
        module: Bumblebee.Text.ClipText,
        architecture: :base
      )

    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    text_model_with_projection_head =
      text_model
      |> Axon.nx(& &1.pooled_state)
      |> Axon.dense(dimension, use_bias: false, name: "text_projection")
      # temporary workaround until Bumblebee bug is fixed
      |> Axon.nx(fn x -> %{embedding: x} end)

    # extract the text projection layer's params from the multimodal model's params
    text_projection_params = multimodal_params["text_projection"]

    # text projection layer params that will be needed for the "text_projection" layer we added
    text_params_with_text_projection =
      put_in(text_params["text_projection"], text_projection_params)

    %{
      model: text_model_with_projection_head,
      params: text_params_with_text_projection,
      spec: text_spec
    }
  end
end
