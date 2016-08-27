defmodule Veggy.Countdown do
  use GenServer
  alias Veggy.EventStore

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start(duration, aggregate_id, user_id) do
    GenServer.call(__MODULE__, {:start, duration, aggregate_id, user_id})
  end

  def handle_call({:start, duration, aggregate_id, user_id}, _from, pomodori) do
    pomodoro_id = Veggy.UUID.new
    {:ok, reference} = :timer.send_after(duration, self, {:ended, pomodoro_id, aggregate_id})
    {:reply, {:ok, pomodoro_id}, Map.put(pomodori, pomodoro_id, {reference, user_id})}
  end

  def handle_info({:ended, pomodoro_id, aggregate_id}, pomodori) do
    {{_, user_id}, pomodori} = Map.pop(pomodori, pomodoro_id)
    EventStore.emit(%{event: "PomodoroEnded",
                      aggregate_id: aggregate_id,
                      timer_id: aggregate_id,
                      pomodoro_id: pomodoro_id,
                      user_id: user_id,
                      id: Veggy.UUID.new})
    {:noreply, pomodori}
  end
end
