defmodule MediaSearchDemo.Clip.Layers do
  @moduledoc """
  Custom layers
  """

  import Nx.Defn

  def normalize(tensor) do
    Axon.layer(&norm/2, [tensor], op_names: :normalize)
  end

  defnp norm(tensor, _opts \\ []) do
    magnitude =
      tensor
      |> Nx.power(2)
      |> Nx.sum(axes: [-1], keep_axes: true)
      |> Nx.sqrt()

    tensor / magnitude
  end
end
