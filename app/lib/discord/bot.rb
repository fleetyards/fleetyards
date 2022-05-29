# frozen_string_literal: true

require 'discordrb'

module Discord
  class Bot
    include Routing

    attr_accessor :token

    def initialize(token:)
      @token = token
    end

    def run
      setup_commands

      bot.run
    end

    def bot
      @_bot ||= Discordrb::Commands::CommandBot.new(token: token, prefix: '!')
    end

    private def setup_commands
      bot.message(with_text: 'Ping!') do |event|
        event.respond 'Pong!'
      end

      bot.command(:query) do |event, *args|
        type = args.first

        case type
        when 'ship'
          resolve_ship(args[1..-1].join(' '))
        when 'station'
          resolve_station(args[1..-1])
        else
          event.respond 'Unknown query type. Allowed types: ship, station'
        end
      end

      bot.command(:ship?) do |_event, *args|
        resolve_ship(args.join(' '))
      end
    end

    private def resolve_ship(ship_name)
      results = Searchkick.search(
        ship_name,
        models: [Model],
        fields: [{ 'name^5': :word_start }]
      )

      return "No Ship found for \"#{ship_name}\"" if results.blank?

      results.map do |result|
        frontend_model_url(slug: result.slug)
      end.join("\n")
    end

    private def resolve_station(args)
      if args.include?('docking')
        ship_size = args.find do |arg|
          Dock.ship_sizes.include?(arg.downcase)
        end

        return resolve_station_docking_query(ship_size)
      end

      station_name = args.join(' ')

      results = Searchkick.search(
        station_name,
        models: [Station],
        fields: [{ 'name^5': :word_start }]
      )

      return "No Station found for \"#{station_name}\"" if results.blank?

      results.map do |result|
        frontend_station_url(slug: result.slug)
      end.join("\n")
    end

    private def resolve_station_docking_query(ship_size)
      ship_size
    end
  end
end
