defmodule MySupervisor do
  use DynamicSupervisor
  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    children = %{
      id: Event_Processor,
      start: {Event_Processor, :start_link, [name]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(__MODULE__,children)
  end

  @spec delete_child(pid) :: :ok | {:error, :not_found}
  def delete_child(name) do
    DynamicSupervisor.terminate_child(__MODULE__, name)
  end
end
