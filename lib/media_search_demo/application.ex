defmodule MediaSearchDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias MediaSearchDemo.Clip.Servings.Constants

  @impl true
  def start(_type, _args) do
    # make sure the model is loaded before starting the app
    {:ok, _} = Bumblebee.load_model({:hf, Constants.clip_hf_model()})

    children = [
      # Start the Telemetry supervisor
      MediaSearchDemoWeb.Telemetry,
      # Start the Ecto repository
      MediaSearchDemo.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: MediaSearchDemo.PubSub},
      # Start Finch
      {Finch, name: MediaSearchDemo.Finch},
      # Start the Endpoint (http/https)
      MediaSearchDemoWeb.Endpoint,
      MediaSearchDemo.Clip.ClipIndexAgent,
      ## Hand Rolled Nx Serving for CLIP Text Embedding ->
      {
        Nx.Serving,
        serving: MediaSearchDemo.Clip.Servings.Text.get_serving(),
        name: MediaSearchDemo.Clip.TextServing,
        batch_size: Constants.clip_text_batch_size(),
        batch_timeout: Constants.clip_text_batch_timeout()
      },
      ## Hand Rolled Nx Servings for CLIP Image Embedding ->
      {
        Nx.Serving,
        serving: MediaSearchDemo.Clip.Servings.Vision.get_serving(),
        name: MediaSearchDemo.Clip.VisionServing,
        batch_size: Constants.clip_vision_batch_size(),
        batch_timeout: Constants.clip_vision_batch_timeout()
      },
      ## Bumblebee Nx Servings for CLIP Text Embedding ->
      {
        Nx.Serving,
        serving: MediaSearchDemo.Clip.Servings.Bumblebee.Text.get_serving(),
        name: MediaSearchDemo.Clip.Bumblebee.TextServing,
        batch_size: Constants.clip_text_batch_size(),
        batch_timeout: Constants.clip_text_batch_timeout()
      },
      ## Bumblebee Nx Servings for CLIP Image Embedding ->
      {
        Nx.Serving,
        serving: MediaSearchDemo.Clip.Servings.Bumblebee.Vision.get_serving(),
        name: MediaSearchDemo.Clip.Bumblebee.VisionServing,
        batch_size: Constants.clip_vision_batch_size(),
        batch_timeout: Constants.clip_vision_batch_timeout()
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MediaSearchDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MediaSearchDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
