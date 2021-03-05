# frozen_string_literal: true

module Command
  module ClassMethods
    def call(*args)
      new(*args).call
    end
  end

  def abort(*args)
    errors.add(*args)
    raise ExitError
  end

  def assert(*_args)
    raise ExitError if errors.any?
  end

  module LegacyErrorHandling
    # Convenience/retrocompatibility aliases
    def self.errors_legacy_alias(method, errors_method)
      define_method method do |*args|
        warn "/!\\ #{method} is deprecated, please use errors.#{errors_method} instead."
        errors.send errors_method, *args
      end
    end
  end

  def assert_sub(klass, *args)
    command = klass.new(*args).as_sub_command.call
    (@sub_commands ||= []) << command
    return command.result if command.success?
    errors.merge_from(command)
    raise ExitError
  end
end
