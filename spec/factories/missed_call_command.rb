class MissedCallCommand
  prepend Command::SimpleCommand

  def initialize(input)
    @input = input
  end
end
