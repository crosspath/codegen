# frozen_string_literal: true

require "json"
require "net/http"

# CLI command `gem search` downloads gz-file with all gems from all sources. It takes about 20 secs.
# We don't need it at all! We have to know latest gem version that match specified
# version requirement, for example latest version of gem "railties" for 7.*.* release.
module GemVersion
  extend self

  def latest(gem_name, version = ">= 0")
    requirement = version.is_a?(Gem::Requirement) ? version : Gem::Requirement.new(version)

    gem_specification(gem_name)
      .map { |hash| Gem::Version.new(hash[:number]) }
      .sort
      .reverse
      .find { |version| requirement.satisfied_by?(version) }
  end

  private

  def connection(&)
    Net::HTTP.start("rubygems.org", use_ssl: true, &)
  end

  def gem_specification(gem_name)
    connection do |http|
      response_body =
        request(
          http,
          Net::HTTP::Get.new("/api/v1/versions/#{gem_name}.json"),
          "Failed to fetch specification for gem \"#{gem_name}\""
        )

      return JSON.parse(response_body, symbolize_names: true)
    end
  end

  def request(http, req, error_message)
    @counter ||= 0
    res = http.request(req)

    if res.code.to_i >= 400
      @counter += 1
      warn "#{error_message} (#{counter}/3)"
      raise "Request count exceeded" if counter == 3

      # rubygems.org limits quest count: 15 requests per second (we should wait 0.067 sec).
      sleep(0.1)
      request(http, req, error_message)
    else
      res.body
    end
  end
end
