defmodule Broadcaster do

  def start_link(socket) do
    pid = spawn(__MODULE__, :broadcast_data, [socket])
    {:ok, pid}
  end

  def broadcast_data(socket) do
    SubscriberData.broadcast_messages(SubscriberData, socket)
    Process.sleep(10)
    broadcast_data(socket)
  end
end
