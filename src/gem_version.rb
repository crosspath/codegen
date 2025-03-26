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
      .find { |actual_version| requirement.satisfied_by?(actual_version) }
  end

  private

  ATTEMPTS = 3

  private_constant :ATTEMPTS

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
    ATTEMPTS.times do |counter|
      res = http.request(req)
      return res.body if res.code.to_i < 400

      warn "#{error_message} (#{counter + 1}/#{ATTEMPTS})"

      # rubygems.org limits request count: 15 requests per second (we should wait 0.067 sec).
      sleep(0.1) if counter < ATTEMPTS - 1
    end

    raise "Request count exceeded"
  end
end
