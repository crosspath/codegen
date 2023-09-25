# frozen_string_literal: true

module Features
  # https://bundler.io/v2.4/man/bundle-config.1.html
  class BundleConfig < Feature
    register_as "bundle-config"

    def call
      copy_files_to_project("", ".bundle")
    end
  end
end
