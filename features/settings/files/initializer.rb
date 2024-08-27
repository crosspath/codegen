# frozen_string_literal: true

require_relative "../../app/lib/settings"

AppConfig =
  Settings.configurate do
    file("config/settings.yml")
  end
