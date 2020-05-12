defmodule Forecast do

  def generate_forecast(packet) do
    pressure = packet["pressure"]
    temperature = packet["temperature"]
    light = packet["light"]
    wind = packet["wind"]
    humidity = packet["humidity"]

    forecast =
    cond do
      temperature < -2 && light < 128 && pressure < 720 -> "SNOW"
      temperature < -2 && light > 128 && pressure < 680 -> "WET_SNOW"
      temperature < -8 -> "SNOW"
      temperature < -15 && wind > 45 -> "BLIZZARD"
      temperature > 0 && pressure < 710 && humidity > 70 && wind < 20 -> "SLIGHT_RAIN"
      temperature > 0 && pressure < 690 && humidity > 70 && wind > 20 -> "HEAVY_RAIN"
      temperature > 30 && pressure < 770 && humidity > 80 && light > 192 -> "HOT"
      temperature > 30 && pressure < 770 && humidity > 50 && light > 192 && wind > 35 -> "CONVECTION_OVEN"
      temperature > 25 && pressure < 750 && humidity > 70 && light < 192 && wind < 10 -> "WARM"
      temperature > 25 && pressure < 750 && humidity > 70 && light < 192 && wind > 10 -> "SLIGHT_BREEZE"
      light < 128 -> "CLOUDY"
      temperature > 30 && pressure < 660 && humidity > 85 && wind > 45 -> "MONSOON"
      true -> "JUST_A_NORMAL_DAY"
    end

    Aggregator.send_forecast([forecast, packet])
  end

end
