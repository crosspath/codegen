# frozen_string_literal: true

AppConfig =
  Settings.configurate do
    read_file_if_exists = ->(path) { file(path) if File.exist?(path) }

    file("#{__dir__}/settings/default.yml")

    read_file_if_exists.call("#{__dir__}/settings/#{Rails.env}.yml")
    read_file_if_exists.call("#{__dir__}/settings/local.yml")
    read_file_if_exists.call("#{__dir__}/settings/#{Rails.env}.local.yml")
  end.freeze

# ActiveRecord expects DATABASE_URL from ENV.
database_url = AppConfig.dig(:active_record, :url)
ENV["DATABASE_URL"] = database_url if database_url.present?
