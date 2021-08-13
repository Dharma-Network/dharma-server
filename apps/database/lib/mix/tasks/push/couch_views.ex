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
        "/_design/designdocs"

    views =
      Path.wildcard("views/*")
      |> Enum.map(fn file ->
        file_striped = hd(Regex.run(~r/(?<=\/).*(?=\.)/, file))

        {:ok, fp} = File.open(file, [:read])
        view = IO.read(fp, :all) |> Jason.decode!()
        {file_striped, view}
      end)
      |> Enum.into(%{}, & &1)

    {:ok, resp} = Database.get_from_db("_design/designdocs")

    Database.put_to_db(endpoint, %{"views" => views}, rev: resp.body["_rev"])
  end
end
