class SuccessCommand
  prepend Command

  def initialize(input)
    @input = input
  end

  def call
    @input * 2
  end
end
