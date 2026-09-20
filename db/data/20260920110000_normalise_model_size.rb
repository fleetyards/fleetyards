# frozen_string_literal: true

# `size` was a free string, and three different things had gone wrong in it.
#
# Six ships carry the RSI matrix's own capitalisation -- "Small", "Large",
# "Capital" -- because the loader copied the matrix verbatim and the rest of the
# catalogue had been downcased by hand over the years. Nothing filters on those
# spellings, so those ships sit outside their own class.
#
# Two carry an empty string, which is neither a size nor an absence.
#
# And ten ground vehicles carry nothing at all -- the Ursa family, the Lynx, the
# Storms, the Novas and the Ballista. That is the one with consequences: the
# ladder added in #4868 may only be set where `size` is "vehicle", so the whole
# top half of it was unreachable.
class NormaliseModelSize < ActiveRecord::Migration[8.1]
  # The two Geotack beacons are the empty strings, and they are deployables
  # rather than anything that berths, so they come out of this unsized rather
  # than being called vehicles. This runs before the blanks are cleared so that
  # the distinction is the migration's, not an accident of which rows happened
  # to be NULL.
  def up
    vehicles = Model.where(size: nil, ground: true)
    say("#{vehicles.count} ground vehicle(s) without a size")
    vehicles.update_all(size: "vehicle")

    # Raw SQL, because `normalizes` turns an empty string into nil on the way
    # into a finder too -- `where(size: "")` asks for the NULLs instead.
    blanks = Model.where("size = ''")
    say("#{blanks.count} model(s) with an empty size")
    blanks.update_all(size: nil)

    Model::SIZES.each do |size|
      misspelled = Model.where("size <> ? AND lower(size) = ?", size, size)
      next if misspelled.none?

      say("#{misspelled.count} model(s) spelling #{size} some other way")
      misspelled.update_all(size: size)
    end

    unknown = Model.where.not(size: [nil, *Model::SIZES]).pluck(:name, :size)
    return if unknown.empty?

    say("left alone, not a size this catalogue knows: #{unknown.map { |name, size| "#{name} (#{size})" }.join(", ")}")
  end

  # There is nothing to put back. The capitalisation was a copy of `rsi_size`,
  # which is untouched and still holds it, and an empty string is not a state
  # worth restoring.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
