defmodule MediaSearchDemo.Clip.ClipIndexAgent do
  use Agent

  alias MediaSearchDemo.ANN

  require Logger

  def start_link(_opts) do
    filenames = init_filenames()
    {:ok, ann_index} = init_ann_index()

    Agent.start_link(
      fn ->
        %{
          filenames: filenames,
          ann_index: ann_index
        }
      end,
      name: __MODULE__
    )
  end

  @spec get_ann_index() :: %HNSWLib.Index{dim: term, reference: term, space: term} | nil
  def get_ann_index() do
    Agent.get(__MODULE__, fn state -> state.ann_index end)
  end

  @spec get_filenames() :: list(String.t())
  def get_filenames() do
    Agent.get(__MODULE__, fn state -> state.filenames end)
  end

  @spec init_filenames() :: list(String.t())
  def init_filenames() do
    try do
      filenames_path = Application.get_env(:media_search_demo, :filenames_save_path)

      File.read!(filenames_path) |> Jason.decode!()
    rescue
      e ->
        Logger.info(
          "[CLIP_INDEX] Failed to load filenames: #{inspect(e)}. Starting without index."
        )

        []
    end
  end

  @spec init_ann_index() :: {:ok, reference()} | {:ok, nil}
  def init_ann_index() do
    try do
      ann_index_path = Application.get_env(:media_search_demo, :ann_index_save_path)
      index_file_exists = File.exists?(ann_index_path)

      clip_embedding_dimension =
        Application.get_env(:media_search_demo, :clip_embedding_dimension)

      if index_file_exists do
        ANN.load_index(
          ann_index_path,
          clip_embedding_dimension
        )
      else
        Logger.info(
          "[CLIP_INDEX] Index file not found at #{ann_index_path}. Starting without index."
        )

        {:ok, nil}
      end
    rescue
      e ->
        Logger.info("[CLIP_INDEX] Failed to load index: #{inspect(e)}. Starting without index.")
        nil
    end
  end
end
