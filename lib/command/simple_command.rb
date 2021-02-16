require 'command/version'
require 'command/errors'

module Command
  module SimpleCommand
    attr_reader :result

    module ClassMethods
      def call(*args)
        new(*args).call
      end
    end

    def self.prepended(base)
      base.extend ClassMethods
    end

    def call
      fail Command::NotImplementedError unless defined?(super)

      @called = true
      @result = super

      self
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

    private

    def called?
      @called ||= false
    end
  end
end
