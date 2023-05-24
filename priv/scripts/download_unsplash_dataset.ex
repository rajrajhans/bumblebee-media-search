require Logger

unsplash_dataset_tsv_path = "priv/photos.tsv000"
image_download_directory = "priv/images"
max_concurrency = 100

# install the req package
Mix.install([
  {:req, "~> 0.3.0"}
])

f = File.read!(unsplash_dataset_tsv_path)

[_header | lines] =
  f
  |> String.split("\n")

lines
|> Task.async_stream(
  fn line ->
    try do
      [id, _, image_url_hd | _] =
        line
        |> String.split("\t")

      # we dont need the full hd version of the image, setting the width to 640
      image_url = image_url_hd <> "?w=640"
      image_save_path = image_download_directory <> "/#{id}.jpg"

      case File.exists?(image_save_path) do
        true ->
          Logger.debug("[DOWNLOAD_UNSPLASH_DATASET] Image #{id} already exists, skipping")

        false ->
          Logger.debug("[DOWNLOAD_UNSPLASH_DATASET] Downloading image #{id} from #{image_url}")
          image = Req.get!(image_url)
          File.write!(image_save_path, image.body)
      end
    rescue
      e ->
        Logger.error("[DOWNLOAD_UNSPLASH_DATASET] Failed to download image  #{inspect(e)}")
    end
  end,
  max_concurrency: max_concurrency,
  ordered: false,
  timeout: :timer.minutes(2),
  on_timeout: :kill_task
)
|> Stream.run()
