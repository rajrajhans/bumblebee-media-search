defmodule MediaSearchDemo.ANN do
  @moduledoc """
  Module for performing ANN similarity search using HNSWLib.
  """
  require Logger

  @doc """
  Build an index from a list of tensors.
  Args:
  dimension -> dimension of each tensor
  tensors_with_index -> list of {Nx.tensor, index} tuples
  """
  @spec build_index(integer(), list(Nx.Tensor.t())) :: {:ok, reference()} | {:error, any()}
  def build_index(dimension, tensors) do
    n = length(tensors)
    Logger.debug("[ANN] Building index with #{n} tensors")
    {:ok, ann_index} = HNSWLib.Index.new(:cosine, dimension, 100_000)

    Enum.each(tensors, fn tensor ->
      HNSWLib.Index.add_items(ann_index, tensor)
    end)

    {:ok, ann_index}
  rescue
    e ->
      Logger.error("[ANN] Failed to build index: #{inspect(e)}")
      {:error, :build_index_failed}
  end

  @doc """
  Save an index to given file path.
  """
  @spec save_index(reference(), String.t()) :: :ok | {:error, any()}
  def save_index(ann_index, path) do
    Logger.debug("[ANN] Saving index to #{path}")
    HNSWLib.Index.save_index(ann_index, path)
  rescue
    e ->
      Logger.error("[ANN] Failed to save index: #{inspect(e)}")
      {:error, :save_index_failed}
  end

  @doc """
  Load an index from given file path.
  """
  @spec load_index(String.t(), integer()) :: {:ok, reference()} | {:error, any()}
  def load_index(path, dimension) do
    Logger.debug("[ANN] Loading index from #{path}")
    HNSWLib.Index.load_index(:cosine, dimension, path)
  rescue
    e ->
      Logger.error("[ANN] Failed to load index: #{inspect(e)}")
      {:error, :load_index_failed}
  end

  @doc """
  Given a ANN_INDEX and a query_tensor, return the approximate nearest neighbor.
  """
  @spec get_nearest_neighbors(
          ann_index :: any(),
          query_tensor :: Nx.Tensor.t(),
          n :: any()
        ) :: {:ok, list(), list()} | {:error, any()}
  def get_nearest_neighbors(ann_index, query_tensor, n) do
    Logger.debug("[ANN] Getting nearest neighbors for tensor")
    HNSWLib.Index.knn_query(ann_index, query_tensor, k: n)
  rescue
    e ->
      Logger.error("[ANN] Failed to get nearest neighbors: #{inspect(e)}]")
      {:error, :nns_failed}
  end
end
