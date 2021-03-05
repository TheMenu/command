# frozen_string_literal: true

module Command
  module ClassMethods
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end
  end

  def abort(*args, **kwargs)
    errors.add(*args, **kwargs)
    raise ExitError
  end

  module LegacyErrorHandling
    # Convenience/retrocompatibility aliases
    def self.errors_legacy_alias(method, errors_method)
      define_method method do |*args, **kwargs|
        warn "/!\\ #{method} is deprecated, please use errors.#{errors_method} instead."
        errors.send errors_method, *args, **kwargs
      end
    end
  end

  def assert_sub(klass, *args, **kwargs)
    command = klass.new(*args, **kwargs).as_sub_command.call
    (@sub_commands ||= []) << command
    return command.result if command.success?
    errors.merge_from(command)
    raise ExitError
  end
end
