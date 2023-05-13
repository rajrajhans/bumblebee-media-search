defmodule MediaSearchDemoWeb.SearchPageLive do
  use MediaSearchDemoWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    search_query = ""

    {:ok,
     socket
     |> assign(:search_query, search_query)
     |> assign(:is_searching, false)
     |> assign(:search_results, [])}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <form phx-submit="set-search-query" class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
          <h1 class="text-2xl text-center mb-5">Natural Language Media Search with Bumblebee</h1>
          <div class="mb-4">
            <input
              class="shadow appearance-none border border-gray-400 rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="search_query"
              name="search_query"
              type="text"
              placeholder="Search Query"
              value={@search_query}
              disabled={@is_searching}
            />
            <%!-- <%= @search_query %> --%>
          </div>

          <button
            type="submit"
            class="bg-transparent hover:bg-blue-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex m-auto"
            disabled={@is_searching}
          >
            Search
          </button>
        </form>

        <%= if @is_searching do %>
          <div class="text-center">
            Loading...
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("set-search-query", %{"search_query" => search_query}, socket) do
    Logger.info("Starting Search for #{search_query}")
    send(self(), {:search, search_query})
    {:noreply, socket |> assign(is_searching: true) |> assign(search_query: search_query)}
  end

  def handle_info({:search, search_query}, socket) do
    Logger.info("Searching for #{search_query}")
    # todo -> do actual search
    {:noreply, assign(socket, is_searching: true)}
  end
end
