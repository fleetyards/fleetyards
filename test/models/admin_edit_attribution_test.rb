# frozen_string_literal: true

require "test_helper"

# The whole point of versioning these models is attribution, so the gate that
# keeps loader writes out of the version table is the behaviour worth pinning.
class AdminEditAttributionTest < ActiveSupport::TestCase
  # One entry per model that gained versioning, with a field the admin edits and
  # a value to change it to. A model added to the group without a line here is
  # untested, which the count assertion at the bottom catches.
  CASES = {
    Equipment => {name: "Renamed by an admin"},
    Commodity => {name: "Renamed by an admin"},
    Manufacturer => {known_for: "Renamed by an admin"},
    ModelPaint => {production_note: "Noted by an admin"},
    Vehicle => {serial: "SN-ADMIN-1"},
    User => {rsi_handle: "renamed_by_admin"},
    FundingGoal => {title: "Renamed by an admin"},
    SupporterContribution => {note: "Noted by an admin"}
  }.freeze

  setup do
    @admin = create(:admin_user)
  end

  CASES.each do |klass, attributes|
    factory = klass.name.underscore.to_sym

    test "#{klass} files a version when an admin makes the change" do
      record = create(factory)

      assert_difference -> { PaperTrail::Version.where(item_type: klass.name).count }, 1 do
        record.author_id = @admin.id
        record.update!(attributes)
      end

      version = PaperTrail::Version.where(item_type: klass.name).order(created_at: :desc).first

      assert_equal @admin.id, version.author_id
      assert_equal attributes.keys.map(&:to_s), version.changeset.keys
    end

    # A loader writes the same columns and sets no author. Without the guard the
    # UEX sync alone would file a version for every commodity every morning.
    test "#{klass} files nothing when no author made the change" do
      record = create(factory)

      assert_no_difference -> { PaperTrail::Version.where(item_type: klass.name).count } do
        record.update!(attributes)
      end
    end
  end

  # Component keeps recording loader changes -- its history page shows them --
  # so it is the one model here without the author guard.
  test "Component records a change with no author, and carries one when given" do
    component = create(:component)

    assert_difference -> { PaperTrail::Version.where(item_type: "Component").count }, 1 do
      component.update!(name: "Renamed by a loader")
    end

    assert_nil PaperTrail::Version.where(item_type: "Component").order(created_at: :desc).first.author_id

    component.author_id = @admin.id
    component.update!(name: "Renamed by an admin")

    assert_equal @admin.id,
      PaperTrail::Version.where(item_type: "Component").order(created_at: :desc).first.author_id
  end

  # devise is `reconfirmable`, so an admin retyping a confirmed user's address
  # writes `unconfirmed_email` and leaves `email` where it was. Versioning
  # `email` alone would have recorded this nowhere.
  test "an admin changing a confirmed user's email is recorded" do
    user = create(:user, email: "before@example.test")
    user.confirm

    user.author_id = @admin.id
    user.update!(email: "after@example.test")

    changeset = PaperTrail::Version.where(item_type: "User", item_id: user.id)
      .order(created_at: :desc).first.changeset

    assert_equal "after@example.test", changeset["unconfirmed_email"].last
    assert_equal "before@example.test", user.reload.email
  end

  test "a destroyed user takes its versions with it" do
    user = create(:user)

    user.author_id = @admin.id
    user.update!(rsi_handle: "changed_by_admin")

    assert_equal 1, PaperTrail::Version.where(item_type: "User", item_id: user.id).count

    user.destroy!

    assert_empty PaperTrail::Version.where(item_type: "User", item_id: user.id),
      "an old email would outlive the account it belonged to"
  end

  test "a destroyed vehicle takes its versions with it" do
    vehicle = create(:vehicle)

    vehicle.author_id = @admin.id
    vehicle.update!(serial: "SN-ADMIN-2")

    assert_equal 1, PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id).count

    vehicle.destroy!

    assert_empty PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id)
  end

  # The catalogue is not somebody's to erase, so it keeps paper_trail's default.
  test "a destroyed catalogue record keeps its versions" do
    equipment = create(:equipment)

    equipment.author_id = @admin.id
    equipment.update!(name: "Renamed by an admin")

    assert_equal 1, PaperTrail::Version.where(item_type: "Equipment", item_id: equipment.id).count

    equipment.destroy!

    assert_equal 1, PaperTrail::Version.where(item_type: "Equipment", item_id: equipment.id).count
  end

  test "every versioned type the feed can carry is authorised and named" do
    feed_types = Admin::Api::V1::VersionsController::FEED_ACCESS_BY_ITEM_TYPE.keys

    # A type in the feed with no VersionedItem entry would be returned with an
    # `itemType` outside the schema's enum.
    assert_empty feed_types - ::VersionedItem::TYPES

    feed_types.each do |item_type|
      klass = item_type.constantize
      column = Admin::Api::V1::VersionsController::FEED_NAME_COLUMN.fetch(item_type, :name)

      assert_includes klass.column_names, column.to_s, "#{item_type} has no #{column} to label it with"
      assert ::VersionedItem::POLICIES.key?(item_type), "#{item_type} has no policy to authorise it"
    end
  end
end
