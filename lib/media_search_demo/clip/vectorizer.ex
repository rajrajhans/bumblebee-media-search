defmodule MediaSearchDemo.Vectorizer do
  @moduledoc """
  A module for vectorizing images and text. (abstraction over MediaSearchDemo.Clip.Image and MediaSearchDemo.Clip.Text)
  """

  # hand rolled Nx Servings:
  # alias MediaSearchDemo.Clip.Servings.Text
  # alias MediaSearchDemo.Clip.Servings.Vision

  # Bumblebee Nx Servings:
  alias MediaSearchDemo.Clip.Servings.Bumblebee.Text
  alias MediaSearchDemo.Clip.Servings.Bumblebee.Vision

  require Logger

  @type error_tuple :: {:error, any()}

  @spec vectorize_text(String.t()) :: {:ok, Nx.Tensor.t()} | error_tuple
  def vectorize_text(text) do
    {:ok, Text.run_embeddings(text)}
  rescue
    e ->
      Logger.error("[VECTORIZER] failed to vectorize text: #{inspect(e)}")

      {:error, :vectorize_text_error}
  end

  @spec vectorize_image(binary()) :: {:ok, Nx.Tensor.t()} | error_tuple
  def vectorize_image(image_data) do
    with {:ok, image} <- StbImage.read_binary(image_data) do
      try do
        {:ok, Vision.run_embeddings(image)}
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

  @spec vectorize_image_url(String.t()) :: {:ok, Nx.Tensor.t()} | error_tuple
  def vectorize_image_url(image_url) do
    with {:ok, res} <- Req.get(image_url) do
      vectorize_image(res.body)
    else
      {:error, reason} ->
        Logger.error("[VECTORIZER] failed to download image: #{inspect(reason)}")

        {:error, :failed_to_vectorize_image}
    end
  end
end
