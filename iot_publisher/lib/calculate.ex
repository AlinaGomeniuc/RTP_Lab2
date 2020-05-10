defmodule Calculate do
  def calculate_sensor_avg(msg) do
    data = msg["message"]
    |> get_tuple()
    |> get_map_list()
    |> get_map()

    data
  end

  def get_tuple(items) do
    Enum.map(items, fn {k, v} -> {Enum.at(String.split(k, "_sensor"), 0), v} end)
    |>Enum.group_by(fn {k, _y} -> {k} end)
    |>Map.values()
  end

  def get_map_list(items) do
    avgMapList = Map.new()
    avgMapList =
      for item <- items do
        if length(item) == 2 do
          [{k, v}, {_a, b}] = item
          Map.put(avgMapList, k, (v + b) /2)
        else
          [{k, v}] = item
          Map.put(avgMapList, k, v)
        end
      end
      avgMapList
  end

  def get_map(mapList) do
    avgMap = Enum.reduce(mapList, fn x, y ->
      Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
    end)
    avgMap
  end

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
