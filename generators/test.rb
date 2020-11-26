Generator.add_actions do |answers|
  next unless answers[:test]

  $main.gem_group :test do
    $main.gem 'factory_bot_rails'
    $main.gem 'faker'
    $main.gem 'rspec-rails'
  end

  after_bundle_install do
    $main.run 'bundle binstubs rspec-core'
  end
end
