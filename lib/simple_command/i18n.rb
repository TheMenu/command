require 'i18n'

I18n.load_path << Dir[File.expand_path("locales") + "/*.yml"]
I18n.default_locale = :en # (note that `en` is already the default!)
