defmodule KidsPrep.Notion.Scheduler do
  use GenServer

  require Logger

  alias KidsPrep.Notion.Sync

  @check_interval :timer.hours(1)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(state) do
    send(self(), :run)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    if Sync.enabled?() do
      today = Date.utc_today()
      tomorrow = Date.add(today, 1)
      generate_daily_modules(today)
      generate_daily_modules(tomorrow)
    end

    Process.send_after(self(), :run, @check_interval)
    {:noreply, state}
  end

  defp generate_daily_modules(date) do
    case Sync.ensure_daily_modules(date) do
      results when is_list(results) ->
        errors = Enum.reject(results, &match?({:ok, _}, &1))

        if errors != [] do
          Logger.warning(
            "Notion daily module generation had errors for #{date}: #{inspect(errors)}"
          )
        end

      {:error, reason} ->
        Logger.warning("Notion daily module generation skipped for #{date}: #{inspect(reason)}")
    end
  rescue
    exception ->
      Logger.warning("Notion scheduler failed for #{date}: #{Exception.message(exception)}")
  catch
    kind, reason ->
      Logger.warning("Notion scheduler failed for #{date}: #{inspect({kind, reason})}")
  end
end
