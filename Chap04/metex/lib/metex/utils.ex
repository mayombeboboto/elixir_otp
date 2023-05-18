defmodule Metex.Utils do
  @success 200

  def temperature_of(location) do
    url_for(location)
    |> HTTPoison.get()
    |> parse_response()
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?" <>
    "q=#{URI.encode(location)}&appid=#{api_key()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{ body: body, status_code: @success }}) do
    body |> JSON.decode!() |> compute_temperature()
  end
  defp parse_response(_response) do
    :error
  end

  defp compute_temperature(json_body) do
    try do
      temp = (json_body["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _reason -> :error
    end
  end

  defp api_key do
    "7dfdb727abcedb4b33b3fd21509164f2"
  end
end
