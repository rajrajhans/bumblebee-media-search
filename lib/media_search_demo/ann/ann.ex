defmodule MediaSearchDemo.ANN do
  @moduledoc """
  Module for performing ANN similarity search using Annoy.
  """
  require Logger

  @doc """
  Build an index from a list of vectors.
  Arg -> list of {vector, index} tuples
  """
  def build_index(size, vectors_with_index) do
    n = length(vectors_with_index)
    Logger.debug("[ANN] Building index with #{n} vectors")
    ann_index = AnnoyEx.new(size, :angular)

    Enum.each(vectors_with_index, fn {vector, i} ->
      AnnoyEx.add_item(ann_index, i, vector)
    end)

    :ok = AnnoyEx.build(ann_index, 10, -1)
    ann_index
  rescue
    e ->
      Logger.error("[ANN] Failed to build index: #{inspect(e)}")
      {:error, :build_index_failed}
  end

  @doc """
  Given a ANN_INDEX and a vector, return the approximate nearest neighbor.
  """
  @spec get_nearest_neighbors(
          ann_index :: reference(),
          input_embedding :: list(),
          n :: pos_integer()
        ) :: {:ok, list(), list()} | {:error, any()}
  def get_nearest_neighbors(ann_index, vector, n) do
    Logger.debug("[ANN] Getting nearest neighbors for vector")
    {ids, distances} = AnnoyEx.get_nns_by_vector(ann_index, vector, n, -1, true)

    {:ok, {ids, distances}}
  rescue
    e ->
      Logger.error("[ANN] Failed to get nearest neighbors: #{inspect(e)}]")
      {:error, :nns_failed}
  end
end
