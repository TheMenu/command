# frozen_string_literal: true

require 'command/error_handling'
require 'command/version'
require 'command/errors'

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
    base.extend ClassMethods
    base.include Command::ErrorHandling
  end

  attr_reader :result

  module ClassMethods
    def call(*args)
      new(*args).call
    end
  end

  def call
    fail NotImplementedError unless defined?(super)

    @called = true
    @result = super
    self
  rescue ExitError => e
  end

  def success?
    called? && !failure?
  end

  def failure?
    called? && errors.any?
  end

  def errors
    @errors ||= Command::Errors.new
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

  private

  def called?
    @called ||= false
  end
end
