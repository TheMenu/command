require 'command/i18n'

module Command
  class NotImplementedError < ::StandardError; end

  class Errors < Hash
    def add(attribute, code, message_or_key = code, **options)
      if defined?(I18n)
        # Can't use `I18n.exists?` because it doesn't accept a scope: kwarg
        message = begin
          I18n.t!(message_or_key, **options)
        rescue I18n::MissingTranslationData
          nil
        end
      end
      message ||= message_or_key

      self[attribute] ||= []
      self[attribute] << { code: code, message: message }
      self[attribute].uniq!
    end

    def add_multiple_errors(errors_hash)
      errors_hash.each do |key, values|
        values.each do |value|
          if value.is_a?(Hash)
            code = value[:code]
            message_or_key = value[:message]
          else
            code = value[0]
            message_or_key = value[1] || value[0]
          end
          add(key, code, message_or_key)
        end
      end
    end
  end
end
