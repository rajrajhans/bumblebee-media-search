defmodule MediaSearchDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # make sure the model is loaded before starting the app
    {:ok, clip} = Bumblebee.load_model({:hf, "openai/clip-vit-base-patch32"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/clip-vit-base-patch32"})

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
      {
        Nx.Serving,
        serving: MediaSearchDemo.Clip.Text.embeddings(clip, tokenizer),
        name: MediaSearchDemo.Clip.Text.Serving,
        batch_size: 10,
        batch_timeout: 20
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
