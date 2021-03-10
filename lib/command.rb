# frozen_string_literal: true

if RUBY_VERSION >= "3"
  require "command/ruby-3-specific.rb"
elsif RUBY_VERSION.start_with? "2.7"
  require "command/ruby-2-7-specific.rb"
else
  require "command/ruby-2-specific.rb"
end

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
    def self.extended(base)
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
    self
  end

  def assert(*_args)
    raise ExitError if errors.any?
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
    errors_legacy_alias :clear_errors, :clear
    errors_legacy_alias :add_error, :add
    errors_legacy_alias :merge_errors_from, :merge_from
    errors_legacy_alias :has_error?, :exists?
    errors_legacy_alias :full_errors, :itself
  end
  include LegacyErrorHandling

  def as_sub_command
    @as_sub_command = true
    self
  end

  private

  def called?
    @called ||= false
  end
end
