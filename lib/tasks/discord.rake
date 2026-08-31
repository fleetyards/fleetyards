# frozen_string_literal: true

namespace :discord do
  namespace :commands do
    desc "Publish the slash command definitions to Discord (full replacement)"
    task sync: :environment do
      application_id = Discord::ApiClient.application_id

      if application_id.blank?
        abort "No Discord application id configured (discord.client_id)."
      end

      unless Discord::ApiClient.configured?
        abort "No Discord bot token configured (discord.bot_token)."
      end

      definitions = Discord::Commands::Registry.payload
      published = Discord::ApiClient.new.put_application_commands(application_id, definitions)

      puts "Published #{definitions.size} command(s) to application #{application_id}:"
      Array(published).each { |command| puts "  /#{command["name"]} — #{command["description"]}" }
    rescue Discord::ApiClient::Error => e
      abort "Discord rejected the command sync: #{e.message}"
    end

    desc "Print the command definitions without publishing them"
    task list: :environment do
      puts JSON.pretty_generate(Discord::Commands::Registry.payload)
    end
  end
end
