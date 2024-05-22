module Rsi
  class LoanerLoader < ::Rsi::BaseLoader
    def initialize(options = {})
      super

      @base_url = "https://support.robertsspaceindustries.com/api/v2/help_center/en-us/articles/360003093114"
    end

    def run(html = nil)
      html_content = html

      html_content = fetch_loaners if html_content.blank?

      return if html_content.blank?

      page = Nokogiri::HTML(html_content)

      missing_loaners = []
      missing_models = []
      model_loaners = []

      (page.css("table tbody tr") || []).each do |loaner_data_row|
        name = loaner_data_row.css("td:first-child").text.squish
        loaners = loaner_data_row.css("td:last-child").text.split(",").map(&:squish)

        found_models = Model.where(name: models_mapping(name)).all

        missing_models << {name:, loaners:} if found_models.blank?

        found_models.each do |model|
          loaners.each do |loaner|
            loaner_name = loaner.squish
            loaner_model = Model.where(name: model_mapping(loaner_name)).first

            if loaner_model.present?
              model_loaner = ModelLoaner.find_or_create_by(model_id: model.id, loaner_model_id: loaner_model.id)
              model_loaners << model_loaner.id
            else
              missing_loaners << {
                model: model.name,
                model_id: model.id,
                loaner: loaner_name
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

      JSON.parse(response.body).dig("article", "body")
    rescue JSON::ParserError
      ""
    end

    private def models_mapping(name)
      x1_variants = ["X1", "X1 Velocity", "X1 Force"]
      zeus_variants = ["Zeus Mk II MR", "Zeus Mk II CL", "Zeus Mk II ES"]

      models_map = {
        "Carrack / Carrack Expedition" => ["Carrack"],
        "Carrack w/ C8X / Carrack Expedition w/C8X" => ["Carrack"],
        "Fury Variants" => ["Fury", "Fury MX", "Fury LX"],
        "100 Series" => %w[100i 125a 135c],
        "600i Series" => ["600i Touring", "600i Explorer", "600i Executive-Edition"],
        "600i Explorer and Executive" => ["600i Explorer", "600i Executive-Edition"],
        "Apollo" => ["Apollo Medivac", "Apollo Triage"],
        "Ares Ion / Inferno" => ["Ares Ion", "Ares Inferno"],
        "Dragonfly" => ["Dragonfly Yellowjacket", "Dragonfly Black"],
        "Hercules Starlifter (All)" => ["C2 Hercules", "M2 Hercules", "A2 Hercules"],
        "Hercules Starlifter A2" => ["A2 Hercules"],
        "Genesis Starliner" => ["Genesis"],
        "Hull A & B" => ["Hull A", "Hull B"],
        "Spirit Variants" => ["C1 Spirit", "E1 Spirit"],
        "Spirit A1" => ["A1 Spirit"],
        "Spirit C1" => ["C1 Spirit"],
        "Spirit E1" => ["E1 Spirit"],
        "Hull D, E" => ["Hull D", "Hull E"],
        "Idris-M & P" => %w[Idris-P Idris-M],
        "Talon & Talon Shrike" => ["Talon", "Talon Shrike"],
        "Kraken (+ Privateer)" => ["Kraken", "Kraken Privateer"],
        "Mercury" => ["Mercury", "Mercury Star Runner"],
        "Mercury Star Runner" => ["Mercury", "Mercury Star Runner"],
        "Mole" => ["Mole"],
        "G12A" => ["G12a"],
        "G12R" => ["G12r"],
        "G12 Variants" => ["G12", "G12a", "G12r"],
        "Zeus CL" => ["Zeus Mk II CL"],
        "Zeus ES" => ["Zeus Mk II ES"],
        "Zeus MR" => ["Zeus Mk II MR"],
        "Zeus ES (+ CL)" => ["Zeus Mk II ES", "Zeus Mk II CL"],
        "Zeus ES and MR Variants" => ["Zeus Mk II MR", "Zeus Mk II ES"],
        "Zeus Variants" => zeus_variants,
        "Storm Variants" => ["Storm", "Storm AA"],
        "ROC (+ ROC DS)" => %w[ROC ROC-DS],
        "Retaliator" => ["Retaliator Bomber", "Retaliator"],
        "San'Tok.yai" => ["San'tok.yāi"],
        "Nox" => ["Nox", "Nox Kue"],
        "X1 & Variants" => x1_variants,
        "X1 (+ Velocity, Force)" => x1_variants,
        "Reliant Variants" => ["Reliant Kore", "Reliant Mako", "Reliant Sen", "Reliant Tana"],
        "Cyclone Variants" => %w[Cyclone Cyclone-TR Cyclone-RN Cyclone-RC Cyclone-AA],
        "Mole (all variants)" => ["MOLE"],
        "MPUV-Tractor" => ["MPUV Tractor"],
        "Pulse (+ LX)" => ["Pulse", "Pulse LX"]
      }

      return models_map[name] if models_map[name].present?

      strip_name(name)
    end

    private def model_mapping(name)
      model_map = {
        "85x" => "85X",
        "F7C - Hornet" => "F7C Hornet Mk I",
        "F7C Hornet" => "F7C Hornet Mk I",
        "F7C-M Super Hornet" => "F7C-M Super Hornet Mk I",
        "URSA Rover" => "Ursa",
        "MPUV Passenger" => "MPUV Personnel",
        "Hercules C2" => "C2 Hercules",
        "Hercules M2" => "M2 Hercules",
        "Cyclone (Explorer only)" => "Cyclone",
        "Khartu-al (Xi'an Scout)" => "Khartu-Al",
        "Khartu-al" => "Khartu-Al",
        "Mole" => "MOLE"
      }

      return model_map[name] if model_map[name].present?

      strip_name(name)
    end

    private def strip_name(name)
      super(name).gsub(/(?:and)/, "").strip
    end
  end
end
