defmodule MediaSearchDemo.Clip.Servings.Bumblebee.Vision do
  alias MediaSearchDemo.Clip.Servings.Constants

  @spec get_serving :: Nx.Serving.t()
  def get_serving() do
    model_info = clip_vision_embeddings_model()
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, Constants.clip_hf_model()})

    Bumblebee.Vision.ImageEmbedding.image_embedding(model_info, featurizer,
      output_attribute: nil,
      embedding_processor: nil
    )
  end

  def run_embeddings(image) do
    serving = MediaSearchDemo.Clip.VisionServing

    Nx.Serving.batched_run(
      serving,
      [image]
    )
  end

  defp clip_vision_embeddings_model() do
    # CLIP model for vision embeddings
    # same as Vision.ClipVision from bumblebee
    # but `with` the final projection layer

    {:ok, %{model: _multimodal_model, params: multimodal_params, spec: _multimodal_spec}} =
      Bumblebee.load_model({:hf, Constants.clip_hf_model()},
        architecture: :base
      )

    {:ok, %{model: vision_model, params: vision_params, spec: vision_spec}} =
      Bumblebee.load_model({:hf, Constants.clip_hf_model()},
        module: Bumblebee.Vision.ClipVision,
        architecture: :base
      )

    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    vision_model_with_projection_head =
      vision_model
      |> Axon.nx(& &1.pooled_state)
      |> Axon.dense(dimension, use_bias: false, name: "visual_projection")

    # extract the visual projection layer's params from the multimodal model's params
    visual_projection_params = multimodal_params["visual_projection"]

    # visual projection layer params that will be needed for the "visual_projection" layer we added
    params_with_visual_projection =
      put_in(vision_params["visual_projection"], visual_projection_params)

    %{
      model: vision_model_with_projection_head,
      params: params_with_visual_projection,
      vision_spec: vision_spec
    }
  end
end
