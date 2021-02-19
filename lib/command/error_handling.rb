module Command
  module ErrorHandling
    def self.prepended(base)
      def base.i18n_scope
        @i18n_scope ||= "errors.messages" # Setting default
      end

      def base.i18n_scope=(new)
        @i18n_scope = new
      end

      base.i18n_scope = "errors.messages" # Setting default
    end

    def self.included(base)
      def base.i18n_scope
        @i18n_scope ||= "errors.messages" # Setting default
      end

      def base.i18n_scope=(new)
        @i18n_scope = new
      end

      base.i18n_scope = "errors.messages" # Setting default
    end

    def add_error(attribute, code, message_or_key, **i18n_options)
      message = I18n.t(message_or_key,
        scope: self.class.i18n_scope,
        **i18n_options,
        default: message_or_key,
      )
      errors.add(attribute, code, message, **i18n_options)
    end

    def has_error?(attribute, code)
      errors.fetch(attribute, []).any? { |e| e[:code] == code }
    end

    def merge_errors_from_record(record)
      record_errors = {}

      record.errors.messages.each do |attribute, messages|
        record_errors[attribute] = messages.
          zip(record.errors.details[attribute]).
          map { |message, detail| [detail[:error], message] }
      end

      errors.add_multiple_errors(record_errors)
    end

    def full_errors
      errors
    end

    def clear_errors
      errors.clear
    end
  end
end
