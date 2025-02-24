# frozen_string_literal: true

module FactoryBotMethods
  # @param path [String]
  # @return [Rack::Test::UploadedFile]
  def example_file(path)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/files/#{path}"))
  end
end

FactoryBot::SyntaxRunner.include(FactoryBotMethods)
RSpec.configure { |config| config.include(FactoryBotMethods) }
