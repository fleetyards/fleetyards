# frozen_string_literal: true

namespace :atproto do
  desc "Generate ATProto key pair and print credentials to add via `rails credentials:edit`"
  task generate_keys: :environment do
    private_key, jwk = OmniAuth::Atproto::KeyManager.generate_key_pair

    puts "Add the following to your credentials via `rails credentials:edit`:"
    puts ""
    puts "bluesky:"
    puts "  private_key: \"#{private_key.to_pem.gsub("\n", "\\n")}\""
    puts "  jwk: '#{jwk.to_json}'"
    puts ""
    puts "The client_id is derived from the frontend endpoint: #{BLUESKY_CLIENT_ID}"
  end
end
