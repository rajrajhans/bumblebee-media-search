defmodule MediaSearchDemo.Clip.Index do
  @moduledoc """
  Module for building and searching the clip index.


  Building the index: Given some images, we want to create their clip embeddings
      and build an Annoy index from those embeddings.
  """
  require Logger

  alias MediaSearchDemo.Vectorizer
  alias MediaSearchDemo.ANN

  alias MediaSearchDemo.Clip.ClipIndexAgent

  @type search_result :: %{
          filename: String.t(),
          distance: float(),
          url: String.t()
        }

  @doc """
  Builds the clip index from the images in the image directory, and saves the index and filenames to disk. (The filenames array is used to map from ANN result to filename while searching)

  Args:
  - ann_index_save_path -> where to save the index, defaults to priv/clip_index.ann
  - filenames_save_path -> where to save the list of filenames, defaults to priv/clip_index_filenames.json
  - image_directory -> directory containing the images, defaults to priv/images
  """
  @dialyzer {:nowarn_function, build_index: 3}
  def build_index(
        ann_index_save_path \\ Application.get_env(:media_search_demo, :ann_index_save_path),
        filenames_save_path \\ Application.get_env(:media_search_demo, :filenames_save_path),
        image_directory \\ Application.get_env(:media_search_demo, :image_directory)
      ) do
    # list images in image directory
    all_images = File.ls!(image_directory) |> Enum.reject(&(&1 |> String.starts_with?(".")))

    # vectorize each image, and create a tuple with {vector, file_name} for each image
    vectors_with_file_name =
      all_images
      |> Enum.with_index()
      |> Enum.map(fn {image_file_name, i} ->
        Logger.debug("[CLIP_INDEX] Indexing image #{i} #{image_file_name}")
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

    vectors = Enum.map(vectors_with_file_name, fn {vector, _filename} -> vector end)
    filenames = Enum.map(vectors_with_file_name, fn {_vector, filename} -> filename end)
    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    with {:ok, ann_index} <- ANN.build_index(dimension, vectors) do
      ANN.save_index(ann_index, ann_index_save_path)
      File.write!(filenames_save_path, Jason.encode!(filenames))

      Logger.info("[CLIP_INDEX] Successfully built index")
    end
  rescue
    e ->
      Logger.error("[CLIP_INDEX] Failed to build index: #{inspect(e)}")
      {:error, :build_index_failed}
  end

  @dialyzer {:nowarn_function, search_index: 1}
  @spec search_index(String.t()) :: {:ok, list(search_result)} | {:error, any()}
  def search_index(query) do
    Logger.debug("[CLIP_INDEX] Searching index for query #{query}")

    ann_index_reference = ClipIndexAgent.get_ann_index()
    filenames = ClipIndexAgent.get_filenames()

    with {:ok, query_vector} <- Vectorizer.vectorize_text(query),
         {:ok, labels, dists} <- ANN.get_nearest_neighbors(ann_index_reference, query_vector, 10) do
      result_indices = labels |> Nx.to_flat_list()
      distances = dists |> Nx.to_flat_list()

      search_results =
        result_indices
        |> Enum.with_index()
        |> Enum.map(fn {result_index, i} ->
          # result index is the index of the image in filenames
          # i is the index of the result in the result_indices list

          filename = filenames |> Enum.at(result_index)

          %{
            filename: filename,
            url: get_url_from_file_name(filename),
            distance: distances |> Enum.at(i)
          }
        end)

      {:ok, search_results}
    else
      {:error, reason} ->
        Logger.error("[CLIP_INDEX] Failed to search index: #{inspect(reason)}")

        {:error, :search_index_failed}
    end
  end

  @dialyzer {:nowarn_function, get_url_from_file_name: 1}
  defp get_url_from_file_name(file_name) do
    "/static/#{file_name}"
  end
end
