defmodule Id3Parser do
  @moduledoc """
  Documentation for `Id3Parser`.
  """

  def parse(filename) do
    case File.read(filename) do
      {:ok, mp3} ->
        mp3_byte_size = byte_size(mp3) - 128
        <<_head :: binary-size(mp3_byte_size), id3_tag :: binary>> = mp3
        print_info(id3_tag)
      _other ->
        IO.puts("Couldn't open #{filename}")
    end
  end

  def print_info(id3_tag) do
    <<"TAG",
      title  :: binary-size(30),
      artist :: binary-size(30),
      album  :: binary-size(30),
      year   :: binary-size(4),
      _rest  :: binary>> = id3_tag
    IO.puts("#{artist} - #{title} (#{album}, #{year})")
  end
end
