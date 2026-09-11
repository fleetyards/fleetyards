# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/migrate/20260910230000_create_inventory_positions.rb")

# The migration's slug derivation, tested directly rather than by running it.
#
# It carries its own copy on purpose -- a migration has to keep working against
# the schema of its own moment -- so `StockPosition` being tested says nothing
# about this one. And the state it exists for cannot be built any more: the
# foreign key is `null: false` in the same migration, so there is no way to hold
# an unpointed entry in a test without dropping the constraint.
#
# The derivation is a pure function, which is the part that can break a deploy:
# the unique index turns a slug collision into a hard failure inside the
# pre-deploy hook.
class CreateInventoryPositionsTest < ActiveSupport::TestCase
  setup do
    @migration = CreateInventoryPositions.new
    @used = {}
    @inventory = SecureRandom.uuid
  end

  def slug_for(name, category: 0, unit: 0, inventory: nil)
    @migration.send(:free_slug, @used, inventory || @inventory, name, category, unit)
  end

  test "the address is the one three endpoints already publish" do
    assert_equal "quantanium--commodity--scu", slug_for("Quantanium")
  end

  test "the enum integers map to the names the address is built from" do
    assert_equal "beacon--component--units", slug_for("Beacon", category: 1, unit: 1)
    assert_equal "aos--other--units", slug_for("AOS", category: 6, unit: 1)
  end

  # Two identities, one address. The loser is unreachable today.
  test "a second name competing for one address gets a suffix" do
    assert_equal "med-pens--consumable--units", slug_for("Med Pens", category: 5, unit: 1)
    assert_equal "med-pens--consumable--units-2", slug_for("med-pens", category: 5, unit: 1)
    assert_equal "med-pens--consumable--units-3", slug_for("MED  PENS", category: 5, unit: 1)
  end

  test "the same address in another inventory is not a collision" do
    assert_equal "quantanium--commodity--scu", slug_for("Quantanium")
    assert_equal "quantanium--commodity--scu", slug_for("Quantanium", inventory: SecureRandom.uuid)
  end

  # Real data has one: a fleet position named "Adp mk4 ".
  test "a trailing space does not reach the address" do
    assert_equal "adp-mk4--equipment--units", slug_for("Adp mk4 ", category: 3, unit: 1)
  end

  # The same identity twice cannot happen -- the query is `SELECT DISTINCT` --
  # but a name that parameterizes to nothing can.
  test "a name with nothing to parameterize still gets an address" do
    assert_equal "item--commodity--scu", slug_for("///")
  end
end
