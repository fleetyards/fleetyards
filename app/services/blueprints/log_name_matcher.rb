# frozen_string_literal: true

module Blueprints
  # Resolves the names the game log's "Received Blueprint" notifications carry
  # to catalogue blueprints.
  #
  # A blueprint's name is copied from the item it makes, which is also what the
  # notification shows, so an exact name is the key. Quote style, case and runs
  # of whitespace are ignored: the localisation has written the same item as
  # `5CA 'Akura'` and with typographic quotes across builds.
  #
  # Every blueprint is a candidate, retired ones included: a log can be older
  # than the build being served, and a recipe the game has since dropped is
  # still one the player received.
  class LogNameMatcher
    QUOTES = /["'‘’“”`]/

    def self.key(name)
      name.to_s.unicode_normalize(:nfkc).gsub(QUOTES, "").squish.downcase
    end

    def initialize(user)
      @user = user
    end

    # Each distinct name once, in the order given, with the blueprints it can
    # mean. An empty list means the catalogue has no such name.
    #
    # `name_keys` gives, per name, the localisation keys a translated game
    # writes that name for. They add to what the name itself means rather than
    # replacing it: logs can mix languages, and one language's name can be
    # another item's in English.
    def match(names, name_keys = [])
      candidates = blueprints_by_key
      keyed = blueprints_by_name_key(name_keys)
      marks = user_marks

      unique_names(names).map do |name|
        key = self.class.key(name)

        options = (candidates.fetch(key, []) | keyed.fetch(key, [])).map do |id, slug, blueprint_name|
          {slug:, name: blueprint_name, owned: marks[id] == false, wanted: marks[id] == true}
        end

        {name:, blueprints: options}
      end
    end

    private def unique_names(names)
      Array(names).map { |name| name.to_s.strip }.reject(&:blank?).uniq { |name| self.class.key(name) }
    end

    private def blueprints_by_key
      Blueprint.where.not(name: nil).order(:name, :slug).pluck(:id, :slug, :name).group_by { |_id, _slug, name| self.class.key(name) }
    end

    private def blueprints_by_name_key(name_keys)
      keys_by_name = Array(name_keys).each_with_object({}) do |entry, all|
        (all[self.class.key(entry[:name])] ||= []).concat(Array(entry[:keys]).map { |key| key.to_s.downcase })
      end

      return {} if keys_by_name.empty?

      blueprints = Blueprint.where.not(name: nil).where(name_key: keys_by_name.values.flatten.uniq)
        .order(:name, :slug).pluck(:name_key, :id, :slug, :name)
        .group_by(&:first).transform_values { |rows| rows.map { |row| row.drop(1) } }

      keys_by_name.transform_values { |keys| keys.flat_map { |key| blueprints.fetch(key, []) }.uniq }
    end

    # blueprint id => wanted
    private def user_marks
      UserBlueprint.where(user_id: @user.id).pluck(:blueprint_id, :wanted).to_h
    end
  end
end
