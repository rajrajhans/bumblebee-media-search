defmodule MediaSearchDemo.Clip.Servings.Vision do
  alias MediaSearchDemo.Clip.Servings.Constants

  @spec get_serving :: Nx.Serving.t()
  def get_serving() do
    defn_options = [compiler: EXLA]

    %{model: model, params: params, featurizer: featurizer} = clip_vision_embeddings_model()

    Nx.Serving.new(
      # Nx.Serving.new expects a function that receives the compiler options and returns a JIT or AOT compiled
      # one-arity function as argument. This function will be called with the arguments returned by the client_preprocessing callback
      fn defn_options ->
        init_serving(%{
          model: model,
          params: params,
          defn_options: defn_options,
          batch_size: Constants.clip_vision_batch_size()
        })
      end,
      defn_options
    )
    |> Nx.Serving.process_options(batch_size: Constants.clip_vision_batch_size())
    |> Nx.Serving.client_preprocessing(&client_preprocessing(&1, featurizer))
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

    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, Constants.clip_hf_model()})

    {:ok, %{model: vision_model, params: vision_params, spec: _spec}} =
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
      featurizer: featurizer
    }
  end

  defp init_serving(%{
         model: model,
         params: params,
         defn_options: defn_options,
         batch_size: batch_size
       }) do
    {_init_fun, predict_fn} = Axon.build(model)

    # For CLIP Vision, we have one "input": pixel_values
    # - pixel_values
    #   - A 4D tensor representing the RGB values of each pixel in the input image
    #   - The tensor's shape is {batch_size, height, width, num_channels}, where height and width are the dimensions of the image, and num_channels is 3 for RGB images
    # Here, we are just creating the placeholder tensor for pixel_values. The actual values will be passed in by the client_preprocessing callback, and then fed into the model by the serving function
    inputs = %{"pixel_values" => Nx.template({batch_size, 224, 224, 3}, :f32)}

    # predict_fn of model we built takes arguments: trained parameters and inputs
    # here, we create a "template" for params and inputs. The template is a data structure that describes the shape and type of the tensors, but doesn't contain any actual values
    # templates are useful when you want to compile a function that will operate on tensors of a certain shape and type, but you don't have the actual values of the tensors yet
    template_args = [params, inputs] |> Enum.map(fn x -> Nx.to_template(x) end)
    embedding_fun = Nx.Defn.compile(predict_fn, template_args, defn_options)

    # now, we are returning a one-arity function that will be called by Nx.Serving
    # here, inputs is Nx batch of the actual values of input tensors, and params are the actual trained parameters
    fn inputs ->
      # pads the inputs (if necessary) to ensure that the size of the batch matches the expected batch_size
      inputs = Nx.Batch.pad(inputs, batch_size - inputs.size)

      # calls the compiled function on trained parameters and the padded inputs batch
      embedding_fun.(params, inputs)
    end
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
