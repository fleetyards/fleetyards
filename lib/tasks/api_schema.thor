# frozen_string_literal: true

require "typhoeus"

class ApiSchema < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc "fetch", "Fetch API Schema from Github and resolve refs"
  def fetch
    require "./config/environment"

    raw_data = fetch_remote(api_schema_url)

    Rails.root.join("schema.yaml").write(raw_data)
  end

  no_commands do
    private def fetch_remote(url)
      response = Typhoeus.get(url, followlocation: true)

      unless response.success?
        puts "Unable to fetch URL: \"#{url}\"!"
        exit 1
      end

      response.body
    end

    private def api_schema_url
      ENV["API_SCHEMA_BASE_URL"] ||
      "https://stoplight.io/api/v1/projects/fleetyards/api-schema-v2/nodes/reference/schema-v2.yaml?deref=optimizedBundle"
    end
  end
end
