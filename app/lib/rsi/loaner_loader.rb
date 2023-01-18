# frozen_string_literal: true

require 'rsi/base_loader'

module Rsi
  class LoanerLoader < ::Rsi::BaseLoader
    def initialize(options = {})
      super

      @base_url = 'https://support.robertsspaceindustries.com/api/v2/help_center/en-us/articles/360003093114'
    end

    def run(html = nil)
      html_content = html

      html_content = fetch_loaners if html_content.blank?

      return if html_content.blank?

      page = Nokogiri::HTML(html_content)

      missing_loaners = []
      missing_models = []
      model_loaners = []

      (page.css('table tbody tr') || []).each do |loaner_data_row|
        name = loaner_data_row.css('td:first-child').text.squish
        loaners = loaner_data_row.css('td:last-child').text.split(', ')

        found_models = Model.where(name: models_map(name)).all

        missing_models << { name:, loaners: } if found_models.blank?

        found_models.each do |model|
          loaners.each do |loaner|
            loaner_name = loaner.squish
            loaner_model = Model.where(name: model_map(loaner_name)).first

            if loaner_model.present?
              model_loaner = ModelLoaner.create(model_id: model.id, loaner_model_id: loaner_model.id)
              model_loaners << model_loaner.id
            else
              missing_loaners << {
                model: model.name,
                model_id: model.id,
                loaner: loaner_name,
              }
            end
          end
        end
      end

      ModelLoaner.where.not(id: model_loaners).destroy_all

      [missing_loaners, missing_models]
    end

    private def fetch_loaners
      response = fetch_remote("#{base_url}?time=#{Time.zone.now.to_i}")

      return unless response.success?

      JSON.parse(response.body).dig('article', 'body')
    rescue JSON::ParserError
      ''
    end

    private def models_map(name)
      models_map = {
        'Carrack / Carrack Expedition' => ['Carrack'],
        'Carrack w/ C8X / Carrack Expedition w/C8X' => ['Carrack'],
        '100 Series' => %w[100i 125a 135c],
        '600i Series' => ['600i Touring', '600i Explorer', '600i Executive-Edition'],
        'Apollo' => ['Apollo Medivac', 'Apollo Triage'],
        'Ares Ion / Inferno' => ['Ares Ion', 'Ares Inferno'],
        'Dragonfly' => ['Dragonfly Yellowjacket', 'Dragonfly Black'],
        'Hercules Starlifter (All)' => ['C2 Hercules', 'M2 Hercules', 'A2 Hercules'],
        'Hercules Starlifter A2' => ['A2 Hercules'],
        'Genesis Starliner' => ['Genesis'],
        'Hull A & B' => ['Hull A', 'Hull B'],
        'Spirit A1' => ['A1 Spirit'],
        'Spirit C1' => ['C1 Spirit'],
        'Spirit E1' => ['E1 Spirit'],
        'Hull D, E' => ['Hull D', 'Hull E'],
        'Idris-M & P' => %w[Idris-P Idris-M],
        'Talon & Talon Shrike' => ['Talon', 'Talon Shrike'],
        'Kraken (+ Privateer)' => ['Kraken', 'Kraken Privateer'],
        'Mercury' => ['Mercury Star Runner'],
        'Mole' => ['Mole'],
        'G12A' => ['G12a'],
        'G12R' => ['G12r'],
        'ROC (+ ROC DS)' => %w[ROC ROC-DS],
        'Retaliator' => ['Retaliator Bomber', 'Retaliator Base'],
        "San'Tok.yai" => ["San'tok.yāi"],
        'Nox' => ['Nox', 'Nox Kue'],
        'X1 & Variants' => ['X1 Base', 'X1 Velocity', 'X1 Force'],
        'Reliant Variants' => ['Reliant Kore', 'Reliant Mako', 'Reliant Sen', 'Reliant Tana'],
        'Cyclone Variants' => %w[Cyclone Cyclone-TR Cyclone-RN Cyclone-RC Cyclone-AA],
      }

      return models_map[name] if models_map[name].present?

      strip_name(name)
    end

    private def model_map(name)
      model_map = {
        '85x' => '85X',
        'F7C - Hornet' => 'F7C Hornet',
        'URSA Rover' => 'Ursa Rover',
        'MPUV Passenger' => 'MPUV Personnel',
        'Hercules C2' => 'C2 Hercules',
        'Hercules M2' => 'M2 Hercules',
        'Cyclone (Explorer only)' => 'Cyclone',
        "Khartu-al (Xi'an Scout)" => 'Khartu-Al',
        'Khartu-al' => 'Khartu-Al',
        'Mole' => 'MOLE'
      }

      return model_map[name] if model_map[name].present?

      strip_name(name)
    end

    private def strip_name(name)
      super(name).gsub(/(?:and)/, '').strip
    end
  end
end
