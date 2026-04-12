# frozen_string_literal: true

namespace :atproto do
  desc "Generate ATProto key pair and print credentials to add via `rails credentials:edit`"
  task generate_keys: :environment do
    private_key, jwk = OmniAuth::Atproto::KeyManager.generate_key_pair

    domain = Rails.configuration.app.domain
    scheme = Rails.configuration.force_ssl ? "https" : "http"
    client_id = "#{scheme}://#{domain}/oauth/client-metadata.json"

    puts "Add the following to your credentials via `rails credentials:edit`:"
    puts ""
    puts "bluesky:"
    puts "  client_id: \"#{client_id}\""
    puts "  private_key: \"#{private_key.to_pem.gsub("\n", "\\n")}\""
    puts "  jwk: '#{jwk.to_json}'"
    puts ""
    puts "The client metadata is served dynamically at /oauth/client-metadata.json"
  end
end
