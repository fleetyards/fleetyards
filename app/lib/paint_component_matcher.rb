# frozen_string_literal: true

# Bridges the two ways a paint gets named. The game files call one "Vanguard
# Clawed Steel Livery" -- base ship, then the paint, then a suffix -- while
# FleetYards stores "Clawed Steel" against a Model whose own name carries the
# variant, "Vanguard Hoplite". Comparing the whole string therefore fails on
# every ship that has variants, so the paint name is matched as a suffix and
# whatever precedes it has to read as the head of the model it hangs off.
#
# The ship half is what makes a match unique, not the paint half: "Fortuna" is
# sold on twenty-six different ships, so a paint name on its own identifies
# nothing.
class PaintComponentMatcher
  LIVERY_SUFFIX = /\s+liver(?:y|ies)\b/i

  # "Vulture Dying Star Livery (Modified)" -- an aside the store never carries.
  PARENTHETICAL = /\s*\([^)]*\)\s*\z/

  # A two-letter paint name would be the tail of almost any string.
  MIN_NAME_LENGTH = 3

  def self.normalize(value)
    value.to_s.downcase.gsub(/[^a-z0-9]/, "")
  end

  def initialize
    @candidates = ModelPaint.includes(:model)
      .where.not(name: [nil, ""])
      .reject { |paint| paint.model.nil? }
      .group_by { |paint| self.class.normalize(paint.name) }
      .except("")

    # Longest first, so "New Dawn" is tried before "Dawn" and the more specific
    # paint wins whenever both would fit.
    @names = @candidates.keys.select { |name| name.length >= MIN_NAME_LENGTH }.sort_by { |name| -name.length }
  end

  def call(component)
    subject = self.class.normalize(component.name.to_s.sub(PARENTHETICAL, "").sub(LIVERY_SUFFIX, ""))

    return if subject.blank?

    @names.each do |name|
      next unless subject.end_with?(name)

      ship = subject.delete_suffix(name)

      next if ship.blank?

      # Shortest model name first, so the base ship beats its variants: the
      # game says "Terrapin", and that must not land on the Terrapin Medic
      # while a plain Terrapin carries the same paint.
      match = @candidates[name]
        .select { |paint| ship_matches?(paint, ship) }
        .min_by { |paint| self.class.normalize(paint.model.name).length }

      return match if match
    end

    nil
  end

  # Prefix rather than equality, because the model carries the variant the game
  # leaves off: "vanguard" has to reach "vanguardhoplite".
  private def ship_matches?(paint, ship)
    self.class.normalize(paint.model.name).start_with?(ship) ||
      self.class.normalize(paint.model.slug).start_with?(ship)
  end
end
