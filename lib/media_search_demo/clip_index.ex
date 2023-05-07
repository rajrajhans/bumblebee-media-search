defmodule MediaSearchDemo.ClipIndex do
  @moduledoc """
  Module for building and searching the clip index.


  Building the index: Given some images, we want to create their clip embeddings
      and build an Annoy index from those embeddings.
  """
  require Logger

  alias MediaSearchDemo.Vectorizer

  @image_directory Application.app_dir(:media_search_demo, "priv/images")

  def build_index() do
    # list images in image directory
    images = File.ls!(@image_directory)

    # vectorize each image
    vectors_with_index =
      Enum.map(images, fn image ->
        image_path = Path.join(@image_directory, image)
        image_data = File.read!(image_path)

        case Vectorizer.vectorize_image(image_data) do
          {:ok, vector} ->
            {:ok, {vector, image}}

          {:error, reason} ->
            Logger.error("[CLIP_INDEX] Failed to vectorize image: #{inspect(reason)}")
            {:error, :vectorize_image_error}
        end
      end)

    vectors_with_index
  rescue
    e ->
      Logger.error("[CLIP_INDEX] Failed to build index: #{inspect(e)}")
      {:error, :build_index_failed}
  end
end
