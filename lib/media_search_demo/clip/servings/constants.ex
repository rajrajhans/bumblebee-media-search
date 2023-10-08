defmodule MediaSearchDemo.Clip.Servings.Constants do
  def clip_hf_model(), do: "openai/clip-vit-base-patch32"
  def sequence_length(), do: 42
  def clip_text_batch_size(), do: 10
  def clip_text_batch_timeout(), do: 100
  def clip_vision_batch_size(), do: 10
  def clip_vision_batch_timeout(), do: 100
end
