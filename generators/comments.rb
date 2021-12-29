Generator.add_actions do |answers|
  remove_strings(
    'Gemfile',
    [
      "# Bundle edge Rails instead: gem \"rails\", github: \"rails/rails\", branch: \"main\"\n",
      "# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]\n",
      "# Use postgresql as the database for Active Record\n",
      "# Use the Puma web server [https://github.com/puma/puma]\n",
      "# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]\n",
      "# Bundle and process CSS [https://github.com/rails/cssbundling-rails]\n",
      "# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]\n",
      "# gem \"kredis\"\n",
      "# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]\n",
      "# gem \"bcrypt\", \"~> 3.1.7\"\n",
      "# Windows does not include zoneinfo files, so bundle the tzinfo-data gem\n",
      "# Reduces boot times through caching; required in config/boot.rb\n",
      "# Use Sass to process CSS\n",
      "# gem \"sassc-rails\"\n",
      "# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]\n",
      "# gem \"image_processing\", \"~> 1.2\"\n",
      "# See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem\n",
      "# Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]\n",
      "# Speed up commands on slow machines / big apps [https://github.com/rails/spring]\n",
    ]
  )

  remove_strings(
    'config/application.rb',
    [
      "# Require the gems listed in Gemfile, including any gems\n"\
          "# you've limited to :test, :development, or :production.\n",
      "    # Initialize configuration defaults for originally generated Rails version.\n",
      <<-END,
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
      END
      "    # Don't generate system test files.\n",
      <<-END,
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
      END
    ]
  )

  remove_strings(
    'config/routes.rb',
    [
      "  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html\n",
      <<-END,
  # Defines the root path route ("/")
  # root "articles#index"
      END
    ]
  )

  remove_strings('db/seeds.rb', [/#[^\n]*\n/])
  if File.read('db/seeds.rb').strip.empty?
    $main.append_to_file('db/seeds.rb', "# db/seeds.rb\n")
  end

  env_string =
      "[\s\n]*# Settings specified here will take precedence over those "\
      "in config/application.rb.\n\s*"

  %w[development test production].each do |key|
    remove_strings("config/environments/#{key}.rb", [/#{env_string}/])
  end
end
