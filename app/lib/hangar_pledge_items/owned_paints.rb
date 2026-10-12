# frozen_string_literal: true

module HangarPledgeItems
  # Which of a model's catalogue paints a user owns, read from the paint pledges
  # the hangar sync stored. A pledge keeps only RSI's item name --
  # "Archimedes & Merlin - IceBreak Paint" -- with no link to a catalogue paint,
  # so both halves are matched by name: the ships before " - " against the model,
  # the rest against the paint. Paint names alone are not enough; IceBreak exists
  # for dozens of ships.
  class OwnedPaints
    SHIP_SEPARATOR = " - "
    SHIP_LIST_SEPARATOR = /\s*(?:&|,|\/|\band\b)\s*/i
    PAINT_SUFFIX = /\s+(?:paint|livery)\z/i

    attr_reader :user, :model

    def initialize(user, model)
      @user = user
      @model = model
    end

    def paint_ids(paints)
      pledged = user.hangar_pledge_items.paints.pluck(:name).filter_map { |name| pledged_paint(name) }
      return [] if pledged.empty?

      paints.select do |paint|
        paint_name = normalize(paint.name)
        next false if paint_name.blank?

        pledged.any? { |name| paint_name.include?(name) || name.include?(paint_name) }
      end.map(&:id)
    end

    # The paint half of a pledge for this model, or nil when the pledge is for
    # other ships.
    private def pledged_paint(name)
      ships, separator, paint = name.rpartition(SHIP_SEPARATOR)
      return if separator.blank?
      return unless ships.split(SHIP_LIST_SEPARATOR).any? { |ship| same_ship?(normalize(ship)) }

      normalize(paint.sub(PAINT_SUFFIX, "")).presence
    end

    # "Spirit" names the C1 Spirit as much as "C1 Spirit" does, so either name
    # may hold the other.
    private def same_ship?(ship)
      return false if ship.blank?

      model_name.include?(ship) || ship.include?(model_name)
    end

    private def model_name
      @model_name ||= normalize(model.name)
    end

    private def normalize(value)
      value.to_s.downcase.gsub(/[^a-z0-9]/, "")
    end
  end
end
