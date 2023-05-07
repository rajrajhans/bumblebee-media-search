defmodule MediaSearchDemo.Clip.ModelAgent do
  @moduledoc """
  Agent for storing the Clip model, tokenizer and featurizer references in memory.
  """

  use Agent
  require Logger

  @hf_model "openai/clip-vit-base-patch32"

  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_opts) do
    Logger.info("[MODEL_AGENT] Starting model agent. Loading model #{@hf_model} ...")

    {:ok, %{model: text_model, params: text_params, spec: _spec}} =
      Bumblebee.load_model({:hf, @hf_model},
        module: Bumblebee.Text.ClipText,
        architecture: :base
      )

    {:ok, %{model: image_model, params: image_params, spec: _spec}} =
      Bumblebee.load_model({:hf, @hf_model},
        module: Bumblebee.Vision.ClipVision,
        architecture: :base
      )

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @hf_model})

    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, @hf_model})

    Agent.start_link(
      fn ->
        %{
          text_model: text_model,
          text_params: text_params,
          image_model: image_model,
          image_params: image_params,
          tokenizer: tokenizer,
          featurizer: featurizer
        }
      end,
      name: __MODULE__
    )
  end

  def get_text_model() do
    Agent.get(__MODULE__, fn state -> state.text_model end)
  end

  def get_text_params() do
    Agent.get(__MODULE__, fn state -> state.text_params end)
  end

  def get_image_model() do
    Agent.get(__MODULE__, fn state -> state.image_model end)
  end

  def get_image_params() do
    Agent.get(__MODULE__, fn state -> state.image_params end)
  end

  def get_tokenizer() do
    Agent.get(__MODULE__, fn state -> state.tokenizer end)
  end

  def get_featurizer() do
    Agent.get(__MODULE__, fn state -> state.featurizer end)
  end
end
