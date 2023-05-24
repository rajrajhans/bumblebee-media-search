Mix.install([
  {:bumblebee, "~> 0.1.0"},
])

{:ok, clip} = Bumblebee.load_model({:hf, "openai/clip-vit-base-patch32"})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/clip-vit-base-patch32"})
{:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/clip-vit-base-patch32"})
