defmodule MediaSearchDemo.Clip.Servings.Text do
  alias MediaSearchDemo.Clip.Servings.Constants

  @spec get_serving :: Nx.Serving.t()
  def get_serving() do
    defn_options = [compiler: EXLA]

    %{model: model, params: params, tokenizer: tokenizer} = clip_text_embeddings_model()

    Nx.Serving.new(
      # Nx.Serving.new expects a function that receives the compiler options and returns a JIT or AOT compiled
      # one-arity function as argument. This function will be called with the arguments returned by the client_preprocessing callback
      fn defn_options ->
        init_serving(%{
          model: model,
          params: params,
          defn_options: defn_options,
          batch_size: Constants.clip_text_batch_size(),
          sequence_length: Constants.sequence_length()
        })
      end,
      defn_options
    )
    |> Nx.Serving.process_options(batch_size: Constants.clip_text_batch_size())
    |> Nx.Serving.client_preprocessing(
      &client_preprocessing(&1, tokenizer, Constants.sequence_length())
    )
  end

  def run_embeddings(text) do
    serving = MediaSearchDemo.Clip.TextServing

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

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, Constants.clip_hf_model()})

    {:ok, %{model: text_model, params: text_params, spec: _spec}} =
      Bumblebee.load_model({:hf, Constants.clip_hf_model()},
        module: Bumblebee.Text.ClipText,
        architecture: :base
      )

    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    text_model_with_projection_head =
      text_model
      |> Axon.nx(& &1.pooled_state)
      |> Axon.dense(dimension, use_bias: false, name: "text_projection")

    # extract the text projection layer's params from the multimodal model's params
    text_projection_params = multimodal_params["text_projection"]

    # text projection layer params that will be needed for the "text_projection" layer we added
    text_params_with_text_projection =
      put_in(text_params["text_projection"], text_projection_params)

    %{
      model: text_model_with_projection_head,
      params: text_params_with_text_projection,
      tokenizer: tokenizer
    }
  end

  defp init_serving(%{
         model: model,
         params: params,
         defn_options: defn_options,
         batch_size: batch_size,
         sequence_length: sequence_length
       }) do
    {_init_fun, predict_fn} = Axon.build(model)

    # for CLIP Text (like many transformer-based models), we have two "inputs": input_ids and attention_mask
    # - input_ids
    #   - integer identifiers corresponding to each token in the input text
    #   - texts are usually tokenized into smaller units (like words or subwords), and each unique token is assigned a unique integer ID. The input_ids tensor contains these IDs, and is used by the model to look up the embeddings for each token
    # - attention_mask
    #   - a binary mask indicating which tokens are "real" and which are "padding"
    #   - The attention_mask helps the model distinguish between real tokens and padding tokens, so it doesn't waste computational resources on the padding
    # Here, we are just creating the placeholder tensors for input_ids and attention_mask. The actual values will be passed in by the client_preprocessing callback, and then fed into the model by the serving function
    inputs = %{
      "input_ids" => Nx.template({batch_size, sequence_length}, :u32),
      "attention_mask" => Nx.template({batch_size, sequence_length}, :u32)
    }

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

  defp client_preprocessing(inputs, tokenizer, sequence_length) do
    inputs =
      Bumblebee.apply_tokenizer(
        tokenizer,
        inputs,
        # max
        length: sequence_length,
        return_token_type_ids: false
      )

    {Nx.Batch.concatenate([inputs]), %{}}
  end
end
