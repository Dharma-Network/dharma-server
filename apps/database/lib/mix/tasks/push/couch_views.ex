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

    Path.wildcard("views/*")
    |> Enum.each(fn file ->
      file_striped = hd(Regex.run(~r/(?<=\/).*(?=\.)/, file))

      endpoint =
        (url <>
           "/" <>
           Application.fetch_env!(:database, :name_db) <>
           "/_design/" <>
           file_striped)
        |> IO.inspect()

      {:ok, fp} = File.open(file, [:read])
      Database.put_to_db(endpoint, IO.read(fp, :all) |> Jason.decode!())
    end)
  end
end
