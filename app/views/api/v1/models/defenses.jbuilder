# frozen_string_literal: true

damage_types = %w[physical energy distortion thermal]

json.array! @defenses do |row|
  model = row.model

  json.id model.id
  json.name model.name
  json.slug model.slug
  json.size model.size if model.size.present?
  json.manufacturer_code model.manufacturer.code if model.manufacturer&.code.present?

  if row.armor.present?
    json.armor do
      json.health row.armor["health"].to_f

      damage_types.each do |type|
        json.set! "damage_#{type}", (row.armor["damage_#{type}"] || 1).to_f
        json.set! "deflection_#{type}", row.armor["deflection_#{type}"].to_f
      end
    end
  end

  json.shields row.shields do |shield|
    json.max_health shield["max_health"].to_f

    %w[absorption resistance].each do |field|
      ranges = shield[field]
      next if ranges.blank?

      json.set! field do
        damage_types.each do |type|
          next if ranges[type].blank?

          json.set! type do
            json.min ranges.dig(type, "min").to_f
            json.max ranges.dig(type, "max").to_f
          end
        end
      end
    end
  end
end
