defmodule MediaSearchDemoWeb.SearchPageLive do
  use MediaSearchDemoWeb, :live_view
  alias MediaSearchDemo.Clip.Index
  require Logger

  def mount(_params, _session, socket) do
    initial_search_query = ""
    initial_is_searching = false
    initial_search_results = []
    initial_error = nil

    {:ok,
     socket
     |> assign(:search_query, initial_search_query)
     |> assign(:is_searching, initial_is_searching)
     |> assign(:search_results, initial_search_results)
     |> assign(:error, initial_error)}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <form phx-submit="set-search-query" class="pb-6 pb-8 mb-4">
          <div class="mb-4 flex items-center gap-10">
            <input
              class="shadow appearance-none border border-gray-400 rounded flex-1 py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="search_query"
              name="search_query"
              type="text"
              placeholder="Search Query"
              value={@search_query}
              disabled={@is_searching}
            />
            <button
              type="submit"
              class="bg-transparent hover:bg-blue-500 text-blue-800 font-medium hover:text-white py-2 px-4 border border-blue-800 hover:border-transparent rounded flex m-auto"
              disabled={@is_searching}
            >
              Search
            </button>
          </div>
        </form>

        <%= if @is_searching do %>
          <div class="text-center">
            Loading...
          </div>
        <% end %>

        <%= if length(@search_results) > 0 do %>
          <h2 class="font-medium text-xl mb-5">
            Search results for <span class="text-blue-800">"<%= @search_query %>"</span>
          </h2>
          <div class="flex flex-wrap gap-y-8 gap-x-6">
            <%= for search_result <- @search_results do %>
              <div class="flex flex-col w-80 gap-y-2 hover:bg-gray-100 py-4 px-3 rounded-md">
                <div class="relative bg-gray-100 flex items-center justify-center">
                  <img
                    class="rounded-md min-h-[200px] object-cover"
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

  def handle_event("set-search-query", %{"search_query" => search_query}, socket) do
    Logger.info("Starting Search for #{search_query}")
    send(self(), {:search, search_query})

    {:noreply,
     socket
     |> assign(is_searching: true)
     |> assign(search_query: search_query)
     |> assign(search_results: [])}
  end

  def handle_info({:search, search_query}, socket) do
    Logger.info("Searching for #{search_query}")

    with {:ok, search_results} <- Index.search_index(search_query) do
      {:noreply, socket |> assign(is_searching: false) |> assign(search_results: search_results)}
    else
      e ->
        Logger.error("[SEARCH_PAGE] Failed to search index: #{inspect(e)}")
        # todo -> show toast
        {:noreply, socket |> assign(is_searching: false) |> assign(error: "Search Failed")}
    end
  end
end
