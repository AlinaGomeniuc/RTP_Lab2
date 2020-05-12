defmodule Printer do
  require Logger
  def print_forcast(sensors_data) do
    forcast = sensors_data["forecast"]

    humidity = sensors_data["humidity"] |> Float.round(2)
    light = sensors_data["light"] |> Float.round(2)
    pressure = sensors_data["pressure"] |> Float.round(2)
    temperature = sensors_data["temperature"] |> Float.round(2)
    wind = sensors_data["wind"] |> Float.round(2)
    timestamp = Integer.to_string(sensors_data["timestamp"]) |> String.slice(0..9)
                                                             |> String.to_integer()
                                                             |> DateTime.from_unix()
                                                             |> elem(1)
                                                             |> DateTime.add(10800, :second)

    IO.puts ("=================================")
    IO.puts ("Date: #{timestamp.day}/#{timestamp.month}/#{timestamp.year} | Time: #{timestamp.hour}:#{timestamp.minute}:#{timestamp.second}")
    IO.puts ("---------------------------------")
    IO.puts ("IT'S #{forcast} OUTSIDE")
    IO.puts ("---------------------------------")
    IO.puts ("Humidity: #{humidity}")
    IO.puts ("Light: #{light}")
    IO.puts ("Pressure: #{pressure}")
    IO.puts ("Temperature: #{temperature}")
    IO.puts ("Wind: #{wind}")
    IO.puts ("=================================")
    IO.puts ("")
  end
end
