defmodule MediaSearchDemo.Vectorizer do
  @moduledoc """
  A module for vectorizing images and text. (abstraction over MediaSearchDemo.Clip.Image and MediaSearchDemo.Clip.Text)
  """

  require Logger
  @type ok_tuple :: {:ok, any()}
  @type error_tuple :: {:error, any()}

  @spec vectorize_text(String.t()) :: ok_tuple | error_tuple
  def vectorize_text(text) do
    {:ok, MediaSearchDemo.Clip.Text.run_embeddings(text)}
  rescue
    e ->
      Logger.error("[VECTORIZER] failed to vectorize text: #{inspect(e)}")

      {:error, :vectorize_text_error}
  end

  @spec vectorize_image(binary()) :: ok_tuple | error_tuple
  def vectorize_image(image_data) do
    with {:ok, image} <- StbImage.read_binary(image_data) do
      try do
        {:ok, MediaSearchDemo.Clip.Image.run_embeddings(image)}
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
