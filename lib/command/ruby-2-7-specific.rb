# frozen_string_literal: true

require 'ruby2_keywords'

module Command
  module ClassMethods
    ruby2_keywords def call(*args)
      new(*args).call
    end
  end

  ruby2_keywords def abort(*args)
    errors.add(*args)
    raise ExitError
  end

  module LegacyErrorHandling
    # Convenience/retrocompatibility aliases
    def self.errors_legacy_alias(method, errors_method)
      ruby2_keywords define_method(method) { |*args|
        warn "/!\\ #{method} is deprecated, please use errors.#{errors_method} instead."
        errors.send errors_method, *args
      }
    end
  end

  ruby2_keywords def assert_sub(klass, *args)
    command = klass.new(*args).as_sub_command.call
    (@sub_commands ||= []) << command
    return command.result if command.success?
    errors.merge_from(command)
    raise ExitError
  end
end
