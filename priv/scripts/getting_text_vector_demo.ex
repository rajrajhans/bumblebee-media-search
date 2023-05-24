text = "two dogs"

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

{:ok, %{model: text_model, params: text_params, spec: _spec}} =
  Bumblebee.load_model({:hf, clip_model_name},
    module: Bumblebee.Text.ClipText,
    architecture: :base
  )

{:ok, %{model: _, params: multimodal_params, spec: _}} =
  Bumblebee.load_model({:hf, clip_model_name},
    architecture: :base
  )

text_model_with_projection_head =
  text_model
  |> Axon.nx(& &1.pooled_state)
  |> Axon.dense(512, use_bias: false, name: "text_projection")

text_params_with_text_projection =
  put_in(
    text_params["text_projection"],
    multimodal_params["text_projection"]
  )

{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, clip_model_name})
tokenizer_output = Bumblebee.apply_tokenizer(tokenizer, [text])

predict_out =
  Axon.predict(
    text_model_with_projection_head,
    text_params_with_text_projection,
    tokenizer_output
  )

IO.inspect(predict_out)
