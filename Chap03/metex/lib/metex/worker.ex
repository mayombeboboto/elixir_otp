defmodule Metex.Worker do

  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get() |> parse_response()
    case result do
      {:ok, temp} -> "#{location}: #{temp}°C"
      :error -> "#{location} not found"
    end
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?" <>
    "q=#{URI.encode(location)}&appid=#{api_key()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{ body: body, status_code: 200 }}) do
    body |> JSON.decode!() |> compute_temperature()
  end
  defp parse_response(_response) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _reason -> :error
    end
  end

  defp api_key() do
    "7dfdb727abcedb4b33b3fd21509164f2"
  end
end
