defmodule UserInput do

  def get_topic()do
    Process.sleep(50)
    IO.puts "Enter the topic to subscribe"
    user_input = IO.gets("")
    topic = String.trim(user_input, "\n")
    IO.inspect(topic)

    topic
  end
end
