defmodule MediaSearchDemo.Clip.ClipIndexAgent do
  use Agent

  alias MediaSearchDemo.ANN
  alias MediaSearchDemo.Constants

  @dimension 512

  def start_link(opts) do
    filenames_path =
      opts
      |> Keyword.get(
        :filename_path,
        Constants.default_filenames_save_path()
      )

    filenames = File.read!(filenames_path) |> Jason.decode!()

    ann_index_path = opts |> Keyword.get(:ann_index_path, Constants.default_ann_index_save_path())

    ann_index =
      ANN.load_index(
        ann_index_path,
        Constants.clip_embedding_size()
      )

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
end
