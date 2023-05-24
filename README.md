# WIP

- Create a hnswlib index from a directory of images (using bumblebee, clip), and run queries against it

## Using with Unsplash Sample Dataset (25,000 images)

- Download the dataset from [https://unsplash.com/data/lite/latest](https://unsplash.com/data/lite/latest).
- Extract and copy the `photos.tsv000` file to `priv` directory.
- Run the script [`download_unsplash_dataset.ex`](./priv/scripts/download_unsplash_dataset.ex) by `run elixir priv/scripts/download_unsplash_dataset.ex` to download the images from the dataset. It will concurrently download images to `priv/images` directory.
- Once the images are downloaded to `priv/images` directory, follow the same steps as described in the above section.
