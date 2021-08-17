defmodule Mix.Tasks.Push.CouchViews do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Start the necessary modules
    Mix.Task.run("app.start")

    url =
      case OptionParser.parse(args, strict: [couch_url: :string]) do
        {[couch_url: url], _, _} -> url
        _ -> Application.fetch_env!(:database, :url_db)
      end

    endpoint =
      url <>
        Application.fetch_env!(:database, :name_db) <>
        "/_design/"

    Path.wildcard("views/*")
    |> Enum.each(fn designdoc ->
      handle_design_doc(endpoint, designdoc)
    end)
  end

  defp handle_design_doc(endpoint, designdoc) do
    views =
      Path.wildcard(designdoc <> "/*")
      |> Enum.map(fn query -> create_view(query) end)
      |> Enum.into(%{}, & &1)

    designdoc_stripped = designdoc |> String.split("/") |> List.last()
    {:ok, resp} = Database.get_from_db("_design/" <> designdoc_stripped)

    case resp.body["_rev"] do
      nil ->
        Database.put_to_db(endpoint <> designdoc_stripped, %{"views" => views})

      _ ->
        Database.put_to_db(endpoint <> designdoc_stripped, %{"views" => views},
          rev: resp.body["_rev"]
        )
        |> IO.inspect()
    end
  end

  defp create_view(query) do
    map = read_query(query, "/map.js")
    red = read_query(query, "/reduce.js")
    query_name = String.split(query, "/") |> List.last()
    {query_name, %{map: map, reduce: red}}
  end

  defp read_query(path, file) do
    case File.read(path <> file) do
      {:ok, content} -> content
      {:error, _} -> ""
    end
  end
end
