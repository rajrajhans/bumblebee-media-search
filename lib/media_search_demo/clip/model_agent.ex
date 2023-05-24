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

    {:ok, %{model: _multimodal_model, params: multimodal_params, spec: _multimodal_spec}} =
      Bumblebee.load_model({:hf, @hf_model},
        architecture: :base
      )

    %{model: text_model, params: text_params} = init_text(multimodal_params["text_projection"])

    %{model: vision_model, params: vision_params} =
      init_vision(multimodal_params["visual_projection"])

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @hf_model})

    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, @hf_model})

    Agent.start_link(
      fn ->
        %{
          text_model: text_model,
          text_params: text_params,
          image_model: vision_model,
          image_params: vision_params,
          tokenizer: tokenizer,
          featurizer: featurizer
        }
      end,
      name: __MODULE__
    )
  end

  def init_vision(visual_projection_params) do
    {:ok, %{model: vision_model, params: vision_params, spec: _vision_spec}} =
      Bumblebee.load_model({:hf, @hf_model},
        module: Bumblebee.Vision.ClipVision,
        architecture: :base
      )

    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    vision_model_with_projection_head =
      vision_model
      |> Axon.nx(& &1.pooled_state)
      |> Axon.dense(dimension,
        use_bias: false,
        name: "visual_projection"
      )

    vision_params_with_visual_projection =
      put_in(vision_params["visual_projection"], visual_projection_params)

    %{
      model: vision_model_with_projection_head,
      params: vision_params_with_visual_projection
    }
  end

  def init_text(text_projection_params) do
    {:ok, %{model: text_model, params: text_params, spec: _spec}} =
      Bumblebee.load_model({:hf, @hf_model},
        module: Bumblebee.Text.ClipText,
        architecture: :base
      )

    dimension = Application.get_env(:media_search_demo, :clip_embedding_dimension)

    text_model_with_projection_head =
      text_model
      |> Axon.nx(& &1.pooled_state)
      |> Axon.dense(dimension, use_bias: false, name: "text_projection")

    text_params_with_text_projection =
      put_in(text_params["text_projection"], text_projection_params)

    %{
      model: text_model_with_projection_head,
      params: text_params_with_text_projection
    }
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
