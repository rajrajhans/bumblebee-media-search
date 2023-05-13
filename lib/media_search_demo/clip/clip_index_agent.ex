defmodule MediaSearchDemo.Clip.ClipIndexAgent do
  use Agent

  alias MediaSearchDemo.ANN
  alias MediaSearchDemo.Constants

  require Logger

  def start_link(opts) do
    filenames = init_filenames(opts)
    ann_index = init_ann_index(opts)

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

  def get_ann_index() do
    Agent.get(__MODULE__, fn state -> state.ann_index end)
  end

  def get_filenames() do
    Agent.get(__MODULE__, fn state -> state.filenames end)
  end

  def init_filenames(opts) do
    try do
      filenames_path =
        opts
        |> Keyword.get(
          :filename_path,
          Constants.default_filenames_save_path()
        )

      File.read!(filenames_path) |> Jason.decode!()
    rescue
      e ->
        Logger.error("[CLIP_INDEX] Failed to load filenames: #{inspect(e)}")
        []
    end
  end

  def init_ann_index(opts) do
    try do
      ann_index_path =
        opts |> Keyword.get(:ann_index_path, Constants.default_ann_index_save_path())

      ANN.load_index(
        ann_index_path,
        Constants.clip_embedding_size()
      )
    rescue
      e ->
        Logger.error("[CLIP_INDEX] Failed to load index: #{inspect(e)}")
        nil
    end
  end
end
