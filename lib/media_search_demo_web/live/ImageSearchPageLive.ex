defmodule MediaSearchDemoWeb.ImageSearchPageLive do
  use MediaSearchDemoWeb, :live_view
  alias MediaSearchDemo.Clip.Index
  require Logger

  def mount(_params, _session, socket) do
    initial_query_image = nil
    initial_is_searching = false
    initial_search_results = []
    initial_error = nil

    {:ok,
     socket
     |> assign(:page_title, "Search with image")
     |> assign(:query_image, initial_query_image)
     |> assign(:error, initial_error)
     |> assign(:is_searching, initial_is_searching)
     |> assign(:search_results, initial_search_results)
     |> allow_upload(:query_image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <form phx-submit="set_query_image" phx-change="validate" class="pb-2" autocomplete="off">
          <div class="mb-4 flex items-center gap-10 justify-between w-full">
            <.live_file_input upload={@uploads.query_image} />

            <button
              type="submit"
              class="bg-transparent hover:bg-blue-500 text-blue-800 font-medium hover:text-white py-2 px-4 border border-blue-800 hover:border-transparent rounded"
            >
              Upload
            </button>
          </div>
        </form>

        <%= if @error do %>
          <div class="text-center text-red-600">
            <%= @error %>
          </div>
        <% end %>

        <%= if @query_image do %>
          <div class="text-center text-red-600">
            <img
              class="rounded-md h-[150px] object-cover flex m-auto mb-10"
              src={"data:image/png;base64, " <> Base.encode64(@query_image)}
              alt="search query image"
            />
          </div>
        <% end %>

        <%= if @is_searching do %>
          <div class="mt-10 text-center">
            Loading...
          </div>
        <% end %>

        <%= if length(@search_results) > 0 do %>
          <p class="mb-5 text-gray-600 text-sm">
            The number in the bottom right corner of each image represents the cosine distance between the search query and the image. The lower the distance, the more similar the image is to the search query.
          </p>
          <div class="flex flex-wrap gap-y-8 gap-x-6">
            <%= for search_result <- @search_results do %>
              <div class="flex flex-col w-80 gap-y-2 hover:bg-gray-100 py-4 px-3 rounded-md">
                <div class="relative bg-gray-100 flex items-center justify-center">
                  <img
                    class="rounded-md h-[200px] object-cover"
                    src={"#{search_result.url}"}
                    alt="stock-media"
                  />
                  <p class="absolute bottom-0 right-0 bg-gray-800 text-gray-400 text-xs font-semibold px-2 py-1 rounded-md">
                    <%= Float.round(search_result.distance, 2) %>
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("set_query_image", _params, socket) do
    [image] =
      consume_uploaded_entries(socket, :query_image, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    send(self(), {:search, image})

    {:noreply,
     socket
     |> assign(:error, nil)
     |> assign(is_searching: true)
     |> assign(:search_results, [])
     |> assign(:query_image, image)}
  rescue
    e ->
      Logger.error("Error uploading image: #{inspect(e)}")

      {:noreply,
       socket
       |> assign(:error, "Error uploading image")
       |> assign(is_searching: false)
       |> assign(:query_image, nil)
       |> assign(:search_results, [])}
  end

  @dialyzer {:nowarn_function, handle_info: 2}
  def handle_info({:search, image}, socket) do
    with {:ok, search_results} <- Index.search_index_with_image(image) do
      {:noreply,
       socket
       |> assign(is_searching: false)
       |> assign(search_results: search_results)
       |> assign(:error, nil)}
    else
      e ->
        Logger.error("[SEARCH_PAGE] Failed to search index: #{inspect(e)}")

        {:noreply,
         socket
         |> assign(is_searching: false)
         |> assign(error: "Search Failed")}
    end
  end
end
