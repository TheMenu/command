# frozen_string_literal: true

require 'simple_command'
require 'simple_command/error_handling'

module Command
  class CommandError < RuntimeError
    attr_reader :code
    def initialize(message = nil, code = nil)
      @code = code
      super(message)
    end
  end

  class ExitError < CommandError; end

  def self.prepended(base)
    base.prepend SimpleCommand
    base.include SimpleCommand::ErrorHandling
  end

  def call
    fail NotImplementedError unless defined?(super)

    @result = super
    @result
  rescue ExitError => e
  end

  def assert_sub(klass, *args)
    command = klass.new(*args).as_sub_command.call
    (@sub_commands ||= []) << command
    return command.result if command.success?
    errors.add_multiple_errors(command.errors)
    raise ExitError
  end

  def as_sub_command
    @as_sub_command = true
    self
  end
end
