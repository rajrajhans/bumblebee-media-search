defmodule MediaSearchDemo.Vectorizer do
  @moduledoc """
  A module for vectorizing images and text. (abstraction over MediaSearchDemo.Clip.Image and MediaSearchDemo.Clip.Text)
  """

  require Logger
  alias MediaSearchDemo.Clip.ModelAgent

  @type ok_tuple :: {:ok, any()}
  @type error_tuple :: {:error, any()}

  @spec vectorize_text(String.t()) :: ok_tuple | error_tuple
  def vectorize_text(text) do
    # todo -> explore using a custom Nx serving instead of agent

    tokenizer = ModelAgent.get_tokenizer()
    model = ModelAgent.get_text_model()
    params = ModelAgent.get_image_params()

    tokenizer_output = Bumblebee.apply_tokenizer(tokenizer, [text])

    predict_out = Axon.predict(model, params, tokenizer_output)

    # todo -> explore using the last hidden state instead of the pooled state (or mean of all hidden states)
    # todo -> explore normalizing the pooled state tensor
    predict_out.pooled_state |> Nx.to_flat_list()
  rescue
    e ->
      Logger.error("[VECTORIZER] failed to vectorize text: #{inspect(e)}")

      {:error, :vectorize_text_error}
  end

  @spec vectorize_image(binary()) :: ok_tuple | error_tuple
  def vectorize_image(image_data) do
    with {:ok, image} <- StbImage.read_binary(image_data) do
      try do
        # todo -> explore using a custom Nx serving instead of agent

        featurizer = ModelAgent.get_featurizer()
        model = ModelAgent.get_image_model()
        params = ModelAgent.get_image_params()

        featurizer_output = Bumblebee.apply_featurizer(featurizer, image)

        predict_out = Axon.predict(model, params, featurizer_output)

        # todo -> explore using the last hidden state instead of the pooled state (or mean of all hidden states)
        # todo -> explore normalizing the pooled state tensor
        predict_out.pooled_state |> Nx.to_flat_list()
      rescue
        e ->
          Logger.error("[VECTORIZER] failed to vectorize image: #{inspect(e)}")

          {:error, :failed_to_vectorize_image}
      end
    else
      {:error, reason} ->
        Logger.error("[VECTORIZER] failed to decode image: #{inspect(reason)}")

        {:error, :failed_to_vectorize_image}
    end
  end
end
