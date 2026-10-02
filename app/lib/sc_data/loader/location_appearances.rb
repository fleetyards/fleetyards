# frozen_string_literal: true

module ScData
  module Loader
    # Seeds how places are drawn from `config/sc_data/location_appearances.yml`:
    # a colour or a header picture, only where the place has none yet. The
    # places only exist once a load made them, so the seed rides on the load
    # rather than on a deploy, and an admin's change always wins.
    class LocationAppearances
      PATH = "config/sc_data/location_appearances.yml"

      def self.seeds
        path = Rails.root.join(PATH)

        path.exist? ? (YAML.safe_load_file(path) || {}) : {}
      end

      def initialize(seeds: self.class.seeds)
        @seeds = seeds
      end

      # How many places it changed.
      def apply
        locations = Location.where(sc_key: @seeds.keys).with_attached_image.index_by(&:sc_key)

        @seeds.sum do |sc_key, seed|
          location = locations[sc_key]
          next 0 if location.nil?

          changed = seed_color(location, seed["color"])
          (seed_image(location, seed["image"]) || changed) ? 1 : 0
        end
      end

      private def seed_color(location, color)
        return false if color.blank? || location.color.present?

        location.update_column(:color, color)
      end

      private def seed_image(location, path)
        return false if path.blank? || location.image.attached?

        file = Rails.root.join(path)
        return false unless file.file?

        location.image.attach(io: StringIO.new(file.binread), filename: file.basename.to_s, content_type: Marcel::MimeType.for(file))
        true
      end
    end
  end
end
