# frozen_string_literal: true

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
  end

  attr_reader :result

  module ClassMethods
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    def extended(base)
      base.i18n_scope = "errors.messages"
    end
    attr_accessor :i18n_scope
  end

  def call
    fail NotImplementedError unless defined?(super)

    @called = true
    @result = super
    self
  rescue ExitError => _e
  end

  def success?
    called? && !failure?
  end

  def failure?
    called? && errors.any?
  end

  def errors
    @errors ||= Command::Errors.new(source: self.class)
  end

  module LegacyErrorHandling
    # Convenience/retrocompatibility aliases
    def self.errors_legacy_alias(method, errors_method)
      define_method method do |*args|
        warn "/!\\ #{method} is deprecated, please use errors.#{errors_method} instead."
        errors.send errors_method, *args
      end
    end
    errors_legacy_alias :clear_errors, :clear
    errors_legacy_alias :add_error, :add
    errors_legacy_alias :merge_errors_from, :merge_from
    errors_legacy_alias :has_error?, :exists?
    errors_legacy_alias :full_errors, :itself
  end
  include LegacyErrorHandling

  def assert_sub(klass, *args)
    command = klass.new(*args).as_sub_command.call
    (@sub_commands ||= []) << command
    return command.result if command.success?
    errors.merge_from(command)
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
