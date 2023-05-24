image_path = "./priv/images/__1Mu7EZXOM.jpg"

##################

Mix.install(
  [
    {:bumblebee, "~> 0.3.0"},
    {:nx, "~> 0.5.0"},
    {:exla, "~> 0.5.0"},
    {:stb_image, "~> 0.6.0"}
  ],
  config: [
    nx: [default_backend: EXLA.Backend]
  ]
)

clip_model_name = "openai/clip-vit-base-patch32"

{:ok, %{model: vision_model, params: vision_params, spec: _spec}} =
  Bumblebee.load_model({:hf, clip_model_name},
    module: Bumblebee.Vision.ClipVision,
    architecture: :base
  )

{:ok, %{model: _, params: multimodal_params, spec: _}} =
  Bumblebee.load_model({:hf, clip_model_name},
    architecture: :base
  )

vision_model_with_projection_head =
  vision_model
  |> Axon.nx(& &1.pooled_state)
  |> Axon.dense(512, use_bias: false, name: "visual_projection")

vision_params_with_vision_projection =
  put_in(
    vision_params["visual_projection"],
    multimodal_params["visual_projection"]
  )

image_data = File.read!(image_path)
{:ok, image} = StbImage.read_binary(image_data)
{:ok, featurizer} = Bumblebee.load_featurizer({:hf, clip_model_name})
featurizer_output = Bumblebee.apply_featurizer(featurizer, image)

predict_out =
  Axon.predict(
    vision_model_with_projection_head,
    vision_params_with_vision_projection,
    featurizer_output
  )

IO.inspect(predict_out)
