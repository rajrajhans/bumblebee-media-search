defmodule MediaSearchDemo.Constants do
  # todo -> refactor this + its usages to use env var set in runtime.exs
  def default_ann_index_save_path do
    Application.app_dir(:media_search_demo, "priv/clip_index.ann")
  end

  def default_filenames_save_path do
    Application.app_dir(
      :media_search_demo,
      "priv/clip_index_filenames.json"
    )
  end

  def default_image_directory do
    Application.app_dir(:media_search_demo, "priv/images")
  end

  def clip_embedding_size do
    512
  end
end
