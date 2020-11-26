app_name = Rails.app_class.name.split('::')[0]

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV['REDIS_URL'],
    id:  "#{app_name}-server-#{::Process.pid}",
  }
  config.logger.level = Logger::WARN if Rails.env.production?
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV['REDIS_URL'],
    id:  "#{app_name}-server-#{::Process.pid}",
  }
end

log_path = Rails.configuration.paths['log'].first
Sidekiq.logger = ActiveSupport::Logger.new(log_path, 2, 100.megabytes)

Sidekiq.default_worker_options = { retry: 0 }
