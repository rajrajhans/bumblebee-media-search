defmodule MediaSearchDemo.ClipIndex do
  @moduledoc """
  Module for building and searching the clip index.


  Building the index: Given some images, we want to create their clip embeddings
      and build an Annoy index from those embeddings.
  """
  require Logger

  alias MediaSearchDemo.Vectorizer
  alias MediaSearchDemo.ANN

  @image_directory Application.app_dir(:media_search_demo, "priv/images")
  @clip_embedding_size 512

  @doc """
  Builds the clip index from the images in the image directory, and saves the index and filenames to disk. (The filenames array is used to map from ANN result to filename while searching)

  Args:
  - ann_index_save_path -> where to save the index, defaults to priv/clip_index.ann
  - filenames_save_path -> where to save the list of filenames, defaults to priv/clip_index_filenames.json
  - image_directory -> directory containing the images, defaults to priv/images
  """
  def build_index(
        ann_index_save_path \\ Application.app_dir(:media_search_demo, "priv/clip_index.ann"),
        filenames_save_path \\ Application.app_dir(
          :media_search_demo,
          "priv/clip_index_filenames.json"
        ),
        image_directory \\ @image_directory
      ) do
    # list images in image directory
    all_images = File.ls!(image_directory) |> Enum.reject(&(&1 |> String.starts_with?(".")))

    # vectorize each image, and create a tuple with {vector, file_name} for each image
    vectors_with_file_name =
      Enum.map(all_images, fn image_file_name ->
        image_path = Path.join(image_directory, image_file_name)
        image_data = File.read!(image_path)

        case Vectorizer.vectorize_image(image_data) do
          {:ok, vector} ->
            {vector, image_file_name}

          {:error, reason} ->
            Logger.error(
              "[CLIP_INDEX] Failed to vectorize image #{image_path}: #{inspect(reason)}"
            )

            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    vectors_with_index =
      vectors_with_file_name
      |> Enum.with_index()
      |> Enum.map(fn {{vector, _filename}, i} ->
        {vector, i}
      end)

    filenames = Enum.map(vectors_with_file_name, fn {_vector, filename} -> filename end)

    with {:ok, ann_index} <- ANN.build_index(@clip_embedding_size, vectors_with_index) do
      ANN.save_index(ann_index, ann_index_save_path)
      File.write!(filenames_save_path, Jason.encode!(filenames))

      Logger.info("[CLIP_INDEX] Successfully built index")
    end
  rescue
    e ->
      Logger.error("[CLIP_INDEX] Failed to build index: #{inspect(e)}")
      {:error, :build_index_failed}
  end
end
