# frozen_string_literal: true

module Locations
  # What sits directly inside a place, by kind, with places that share a name
  # folded into one entry: 306 QV Logistics Stations read as one line, and the
  # list is where they can be told apart.
  class Contents
    Group = Struct.new(:kind, :count, :entries)
    Entry = Struct.new(:name, :count, :location, :shown_on_starmap)

    def initialize(location)
      @location = location
    end

    def call
      children.group_by(&:kind)
        .sort_by { |kind, _rows| Location::KINDS.index(kind) || Location::KINDS.size }
        .map do |kind, rows|
          entries = rows.group_by(&:name).map do |name, namesakes|
            Entry.new(name:, count: namesakes.size, location: namesakes.first, shown_on_starmap: namesakes.any?(&:shown_on_starmap))
          end

          Group.new(kind:, count: rows.size, entries: entries.sort_by { |entry| entry.name.to_s.downcase })
        end
    end

    private def children
      Location.current_version
        .where(parent_id: @location.id)
        .includes(:parent, :build, :last_build)
        .order(:sc_key)
        .to_a
    end
  end
end
