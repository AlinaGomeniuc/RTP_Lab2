defmodule Calculate do

  def sort_map(map)do
    Enum.map(map, fn elem -> hd(elem) end) |>
    Enum.frequencies|>
    Map.to_list |>
    Enum.sort_by(&(elem(&1, 1)), :desc)
  end

  def get_first(list)do
    hd(list)|> elem(0)
  end

  def get_sensor_from_list(list, condition)do
    Enum.filter(list, fn elem -> hd(elem) === condition end) |>
    Enum.map(fn list -> List.to_tuple(list) end) |>
    Enum.map(fn tuple -> elem(tuple, 1) end) |> List.to_tuple
  end

  def sum_data(list, key)do
    Enum.map(list, fn (x) -> x[key] end)|>
    Enum.sum
  end

  def last_element(list, key)do
    Enum.map(list, fn (x) -> x[key] end)|>
    Enum.max()
  end

end
