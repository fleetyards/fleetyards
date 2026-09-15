# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: fleet_contracts
#
#  id                             :uuid             not null, primary key
#  aasm_state                     :string           default("draft"), not null
#  cancelled_at                   :datetime
#  claimed_at                     :datetime
#  cover_image_preset             :string
#  crew_limit                     :integer
#  deadline                       :datetime
#  description                    :text
#  expired_at                     :datetime
#  fulfilled_at                   :datetime
#  kind                           :integer          default(0), not null
#  published_at                   :datetime
#  reimburse_expenses             :boolean          default(TRUE), not null
#  reward                         :decimal(15, 2)   default(0.0), not null
#  slug                           :string           not null
#  title                          :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  created_by_id                  :uuid
#  destination_fleet_inventory_id :uuid
#  fleet_id                       :uuid             not null
#  source_fleet_inventory_id      :uuid
#
# Indexes
#
#  index_fleet_contracts_on_created_by_id                   (created_by_id)
#  index_fleet_contracts_on_destination_fleet_inventory_id  (destination_fleet_inventory_id)
#  index_fleet_contracts_on_fleet_id                        (fleet_id)
#  index_fleet_contracts_on_fleet_id_and_aasm_state         (fleet_id,aasm_state)
#  index_fleet_contracts_on_fleet_id_and_kind               (fleet_id,kind)
#  index_fleet_contracts_on_fleet_id_and_slug               (fleet_id,slug) UNIQUE
#  index_fleet_contracts_on_source_fleet_inventory_id       (source_fleet_inventory_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (destination_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (source_fleet_inventory_id => fleet_inventories.id) ON DELETE => nullify
#
class FleetContractTest < ActiveSupport::TestCase
  # A fleet's own board art, one attachment per kind. The lookup is by kind so
  # nothing above it deals in three attachment names.
  test "a fleet carries a cover per contract kind" do
    fleet = create(:fleet)

    FleetContract::KINDS.each_key do |kind|
      assert_not_nil fleet.contract_cover_for(kind), "no attachment for #{kind}"
      assert_not fleet.contract_cover_for(kind).attached?
    end

    assert_nil fleet.contract_cover_for("nonsense")
  end

  test "a contract cover refuses a vector image" do
    fleet = build(:fleet)
    fleet.transport_contract_cover.attach(
      io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
      filename: "cover.svg", content_type: "image/svg+xml"
    )

    assert_not fleet.valid?
    assert_includes fleet.errors.attribute_names, :transport_contract_cover
  end

  test "a transport contract needs a source inventory and the others must not have one" do
    fleet = create(:fleet)

    transport = build(:fleet_contract, :transport, fleet: fleet)
    assert transport.valid?

    transport.source_fleet_inventory = nil
    assert_not transport.valid?

    procurement = build(:fleet_contract, fleet: fleet,
      source_fleet_inventory: create(:fleet_inventory, fleet: fleet))
    assert_not procurement.valid?
  end

  test "both inventories have to belong to the posting fleet" do
    contract = build(:fleet_contract, destination_fleet_inventory: create(:fleet_inventory))

    assert_not contract.valid?
    assert_includes contract.errors.details[:base].map { |error| error[:error] }, :inventory_not_in_fleet
  end

  test "a contract cannot haul to the inventory it hauls from" do
    fleet = create(:fleet)
    inventory = create(:fleet_inventory, fleet: fleet)

    contract = build(:fleet_contract, :transport, fleet: fleet,
      source_fleet_inventory: inventory, destination_fleet_inventory: inventory)

    assert_not contract.valid?
  end

  # A contract already says what it wants in its goods; making the author
  # restate that in a title is busywork.
  test "an untitled contract describes itself from its goods" do
    contract = create(:fleet_contract, title: nil)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 800)

    assert_equal "Buy 800 SCU Titanium", contract.reload.display_title
  end

  test "the grade it asks for is part of the sentence" do
    contract = create(:fleet_contract, title: nil, kind: :crafting)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Cooler", category: :component, unit: :units, quantity: 4, quality: 500)

    assert_equal "Craft 4 units Cooler at 500+ quality", contract.reload.display_title

    contract.fleet_contract_items.sole.update!(quality_match: :exact)

    assert_equal "Craft 4 units Cooler at exactly 500 quality", contract.reload.display_title
  end

  test "several lines name the first and count the rest" do
    contract = create(:fleet_contract, title: nil)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 800)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 200)

    assert_equal "Buy 800 SCU Titanium and 1 more", contract.reload.display_title
  end

  test "a contract with nothing on it yet still has something to be called" do
    assert_equal "Untitled purchase", create(:fleet_contract, title: nil).display_title
  end

  test "a title the author gave wins over the derived one" do
    contract = create(:fleet_contract, title: "Weekly Daymar run")
    create(:fleet_contract_item, fleet_contract: contract)

    assert_equal "Weekly Daymar run", contract.reload.display_title
  end

  # A derived title moves whenever the goods do, so the slug cannot follow it.
  test "an untitled contract keeps its slug when its goods change" do
    contract = create(:fleet_contract, title: nil)
    slug = contract.slug

    assert_match(/\Aprocurement-[0-9a-f]{8}\z/, slug)

    create(:fleet_contract_item, fleet_contract: contract)
    contract.reload.touch

    assert_equal slug, contract.reload.slug
  end

  test "a renamed contract follows its new title" do
    contract = create(:fleet_contract, title: "First name")

    assert_equal "first-name", contract.slug

    contract.update!(title: "Second name")

    assert_equal "second-name", contract.slug
  end

  test "publishing needs something to deliver" do
    contract = create(:fleet_contract)

    assert_not contract.publish!
    assert contract.draft?

    create(:fleet_contract_item, fleet_contract: contract)

    assert contract.reload.publish!
    assert contract.open?
    assert_not_nil contract.published_at
  end

  test "claiming and releasing move the contract and stamp it" do
    contract = create(:fleet_contract, :published)

    assert contract.claim!
    assert contract.in_progress?
    assert_not_nil contract.claimed_at

    assert contract.release!
    assert contract.open?
    assert_nil contract.claimed_at
  end

  test "the database refuses a second accepted lead" do
    contract = create(:fleet_contract, :in_progress)
    create(:fleet_contract_assignment, :lead, fleet_contract: contract)

    assert_raises ActiveRecord::RecordNotUnique do
      FleetContractAssignment.insert_all!(
        [{
          fleet_contract_id: contract.id, user_id: create(:user).id,
          role: 0, aasm_state: "accepted",
          created_at: Time.current, updated_at: Time.current
        }]
      )
    end
  end

  test "a released lead does not block the next claim" do
    contract = create(:fleet_contract, :in_progress)
    lead = create(:fleet_contract_assignment, :lead, fleet_contract: contract)

    lead.withdraw!

    assert_nothing_raised do
      create(:fleet_contract_assignment, :lead, fleet_contract: contract)
    end
  end

  # Two lines with the same identity would both match the same deposits, so one
  # delivery would satisfy both.
  test "a contract cannot ask for the same position twice" do
    contract = create(:fleet_contract)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 100)

    twin = build(:fleet_contract_item, fleet_contract: contract,
      name: "titanium", category: :commodity, unit: :scu, quantity: 50)

    assert_not twin.valid?
    assert_includes twin.errors.details[:name].map { |error| error[:error] }, :taken
  end

  test "the database refuses a duplicate identity that slips past the validation" do
    contract = create(:fleet_contract)
    create(:fleet_contract_item, fleet_contract: contract,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 100)

    assert_raises ActiveRecord::RecordNotUnique do
      FleetContractItem.insert_all!(
        [{
          fleet_contract_id: contract.id, name: "TITANIUM",
          category: 0, unit: 0, quantity: 5, position: 9,
          created_at: Time.current, updated_at: Time.current
        }]
      )
    end
  end

  test "the same position in another contract is fine" do
    create(:fleet_contract_item, name: "Titanium", category: :commodity, unit: :scu)

    assert build(:fleet_contract_item, name: "Titanium", category: :commodity, unit: :scu).valid?
  end

  test "the crew limit is counted over the other accepted rows" do
    contract = create(:fleet_contract, :in_progress, crew_limit: 1)
    create(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    second = build(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    assert_not second.valid?
    assert_not contract.accepting_crew?
  end

  test "an accepted crew member may be saved again without tripping its own limit" do
    contract = create(:fleet_contract, :in_progress, crew_limit: 1)
    assignment = create(:fleet_contract_assignment, :accepted, fleet_contract: contract)

    assert assignment.update(approved_by: create(:user))
  end
  # Nothing is written for a form that picked nothing. The column says whether
  # somebody chose a picture, and a default stored in it could not be told apart
  # from a choice that happened to name the same art -- which is how a contract
  # nobody had touched came to outrank the cover its fleet had configured.
  test "a contract with no preset stores none" do
    contract = create(:fleet_contract, :transport)

    assert_nil contract.cover_image_preset
  end

  # The value the model used to write by itself, now only reachable by asking
  # for it -- and it has to survive, or the picker's own tile for this kind
  # would be the one choice that could not be made.
  test "a preset naming the contract's own kind is kept" do
    contract = create(:fleet_contract, :transport, cover_image_preset: "transport")

    assert_equal "transport", contract.cover_image_preset

    contract.reload.update!(title: "Renamed")

    assert_equal "transport", contract.cover_image_preset
  end

  test "a preset the author chose is kept" do
    contract = create(:fleet_contract, :transport, cover_image_preset: "transport_alt1")

    assert_equal "transport_alt1", contract.cover_image_preset
  end

  # Nothing to leave behind any more: a contract that chose nothing carries
  # nothing, so a change of kind has no stale default to clean up after.
  test "changing the kind leaves an unchosen preset alone" do
    contract = create(:fleet_contract, :transport)
    assert_nil contract.cover_image_preset

    contract.update!(kind: :crafting, source_fleet_inventory: nil)

    assert_nil contract.reload.cover_image_preset
  end

  # The picker offers every kind's art, so a stored preset is a picture somebody
  # picked for this job -- a change of kind is not a reason to throw it away.
  test "changing the kind keeps a preset the author picked" do
    contract = create(:fleet_contract, :transport, cover_image_preset: "transport_alt1")

    contract.update!(kind: :crafting, source_fleet_inventory: nil)

    assert_equal "transport_alt1", contract.cover_image_preset
  end

  test "a preset naming another kind is kept as chosen" do
    contract = create(:fleet_contract, :crafting, cover_image_preset: "transport")

    assert_equal "transport", contract.cover_image_preset

    contract.reload.update!(title: "Renamed")

    assert_equal "transport", contract.cover_image_preset
  end

  test "a vector cover is refused" do
    contract = build(:fleet_contract)
    contract.cover_image.attach(
      io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
      filename: "cover.svg",
      content_type: "image/svg+xml"
    )

    assert_not contract.valid?
    assert_includes contract.errors.attribute_names, :cover_image
  end

  test "a raster cover is accepted" do
    contract = build(:fleet_contract)
    contract.cover_image.attach(
      io: file_fixture("test.png").open,
      filename: "cover.png",
      content_type: "image/png"
    )

    assert_predicate contract, :valid?
    assert_predicate contract.cover_image, :attached?
  end
end
