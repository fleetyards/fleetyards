# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarSyncTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @input = JSON.parse(Rails.root.join("test/fixtures/sync/rsi_hangar.json").read)
  end

  class WithExistingVehiclesTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @corsair_model = Model.find_by!(slug: "drak-corsair")
      @javelin_model = Model.find_by!(slug: "aegs-javelin")

      @andromeda_ship = create(:vehicle, user: @user, model: @andromeda_model, name: "USS Troi", wanted: false, public: true)
      @pirate_ship = create(:vehicle, user: @user, model: @corsair_model, wanted: false)
      @jav_ship = create(:vehicle, user: @user, model: @javelin_model, wanted: false, public: true, flagship: true)
    end

    test "syncs all data" do
      travel_to 1.minute.from_now do
        result = ::HangarSync.new(@input).run(@user.id)

        assert_equal [@andromeda_ship.id, @pirate_ship.id].sort, result[:found_vehicles].sort
        assert_equal [@jav_ship.id], result[:moved_vehicles_to_wanted]
        assert_equal 47, result[:imported_vehicles].size
        assert_equal [], result[:missing_components]
        assert_equal [], result[:missing_models]
        assert_equal [], result[:imported_components]
        assert_equal [], result[:found_components]
        assert_equal [], result[:missing_component_vehicles]
        assert_equal [], result[:imported_upgrades]
        assert_equal [], result[:found_upgrades]

        assert_equal "USS Troi", @andromeda_ship.reload.name
        assert_equal "Enterprise", @pirate_ship.reload.name
      end
    end

    # The sync renames the corsair and moves the javelin to wanted -- both
    # columns a user edits by hand, so nothing about the row says which of the
    # two wrote it. It is held out at the entry point instead.
    test "records no versions, though it writes columns a user's edit would" do
      travel_to 1.minute.from_now do
        assert_no_difference -> { PaperTrail::Version.where(item_type: "Vehicle").count } do
          ::HangarSync.new(@input).run(@user.id)
        end
      end

      assert_equal "Enterprise", @pirate_ship.reload.name
      assert @jav_ship.reload.wanted
    end

    test "files every vehicle it touched into the target group" do
      group = HangarGroup.create!(user_id: @user.id, name: "RSI", color: "#ffffff")
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, hangar_group_id: group.id)

      ::HangarSync.new(@input).run_with_import(import)

      # Matched and newly created alike -- an RSI hangar carries no group
      # information, so filing only the new ones would leave the list split.
      assert_includes group.reload.vehicles.pluck(:id), @andromeda_ship.id
      assert_predicate group.vehicles.count, :positive?
    end

    test "does not stack a duplicate task force on a re-sync" do
      group = HangarGroup.create!(user_id: @user.id, name: "RSI", color: "#ffffff")

      2.times do
        import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, hangar_group_id: group.id)
        ::HangarSync.new(@input).run_with_import(import)
      end

      counts = TaskForce.where(hangar_group_id: group.id).group(:vehicle_id).count

      assert_equal [1], counts.values.uniq
    end

    test "a cancelled sync leaves unreached vehicles alone" do
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input)

      sync = ::HangarSync.new(@input)
      # Stop on the first checkpoint, with the state already moved the way
      # `request_cancel!` moves it -- so the run breaks out mid-list rather
      # than refusing to start.
      sync.define_singleton_method(:stop_requested?) do |index|
        next false unless index.zero?

        import.request_cancel!
        @cancelled = true
      end

      sync.run_with_import(import)

      # The run never saw the rest of the pledge list, so nothing it had not
      # reached may be treated as unmatched and pushed onto the wishlist.
      refute_predicate @jav_ship.reload, :wanted?
      refute_predicate @andromeda_ship.reload, :wanted?
      assert_predicate import.reload, :cancelled?
    end
  end

  # The javelin is the one existing ship the pledge list does not carry, so it
  # is what every action below is about.
  class UnmatchedVehiclesTest < HangarSyncTest
    setup do
      @javelin_model = Model.find_by!(slug: "aegs-javelin")
      @jav_ship = create(:vehicle, user: @user, model: @javelin_model, name: "Ozymandias", wanted: false)
    end

    def run_with(**attributes)
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, **attributes)

      ::HangarSync.new(@input).run_with_import(import)
    end

    test "moves what it did not find to the wishlist by default" do
      result = run_with

      assert_equal [@jav_ship.id], result[:moved_vehicles_to_wanted]
      assert_equal [], result[:deleted_vehicles]
      assert_predicate @jav_ship.reload, :wanted?
    end

    test "deletes what it did not find, and names it" do
      result = run_with(unmatched_vehicles_action: "delete")

      assert_equal ["Ozymandias"], result[:deleted_vehicles]
      assert_equal [], result[:moved_vehicles_to_wanted]
      refute Vehicle.exists?(@jav_ship.id)
    end

    test "takes what hangs off a deleted vehicle with it" do
      task_force = TaskForce.create!(
        vehicle: @jav_ship,
        hangar_group: HangarGroup.create!(user_id: @user.id, name: "Capitals", color: "#ffffff")
      )

      run_with(unmatched_vehicles_action: "delete")

      refute TaskForce.exists?(task_force.id)
    end

    test "leaves what it did not find alone, and still reports it" do
      result = run_with(unmatched_vehicles_action: "keep")

      assert_equal [@jav_ship.id], result[:unchanged_vehicles]
      assert_equal [], result[:moved_vehicles_to_wanted]

      @jav_ship.reload
      refute_predicate @jav_ship, :wanted?
      assert_equal "Ozymandias", @jav_ship.name
    end

    test "files what it did not find into its own group, without touching the ship" do
      group = HangarGroup.create!(user_id: @user.id, name: "Sort me out", color: "#ffffff")

      result = run_with(unmatched_vehicles_action: "group", unmatched_hangar_group_id: group.id)

      assert_equal [@jav_ship.id], result[:grouped_vehicles]
      assert_equal [@jav_ship.id], group.reload.vehicles.pluck(:id)
      refute_predicate @jav_ship.reload, :wanted?
    end

    test "does not stack a task force when the same run is repeated" do
      group = HangarGroup.create!(user_id: @user.id, name: "Sort me out", color: "#ffffff")

      2.times { run_with(unmatched_vehicles_action: "group", unmatched_hangar_group_id: group.id) }

      assert_equal 1, TaskForce.where(hangar_group_id: group.id, vehicle_id: @jav_ship.id).count
    end

    # A wishlisted ship is one the user does not own, so it is absent from every
    # RSI hangar and unmatched on every single run. Under `delete` that would
    # empty the whole wishlist on the first sync.
    test "never reaches a ship that is already on the wishlist" do
      wishlisted = create(:vehicle, user: @user, model: Model.find_by!(slug: "aegs-idris-p"), wanted: true)

      result = run_with(unmatched_vehicles_action: "delete")

      assert Vehicle.exists?(wishlisted.id)
      refute_includes result[:deleted_vehicles], wishlisted.name
    end

    # Stopping a sync is how a user gets out of a scrape that came back short.
    # Under `delete` an unreached vehicle is not recoverable, so the guard that
    # already covered the wishlist move has to cover this too.
    test "a cancelled run deletes nothing" do
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, unmatched_vehicles_action: "delete")

      sync = ::HangarSync.new(@input)
      sync.define_singleton_method(:stop_requested?) do |index|
        next false unless index.zero?

        import.request_cancel!
        @cancelled = true
      end

      sync.run_with_import(import)

      assert Vehicle.exists?(@jav_ship.id)
    end
  end

  class WithBundledSnubCraftsTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @snub_model = Model.find_by!(slug: "drak-corsair")
      @andromeda_model.snub_crafts << @snub_model
    end

    test "auto-creates bundled child vehicles for synced ships" do
      result = ::HangarSync.new(@input).run(@user.id)

      andromeda_vehicle = Vehicle.find(result[:imported_vehicles]).find { |v| v.model_id == @andromeda_model.id }
      assert andromeda_vehicle.present?

      bundled = Vehicle.where(bundled: true, vehicle_id: andromeda_vehicle.id, user_id: @user.id)
      assert_equal 1, bundled.count
      assert_equal @snub_model.id, bundled.first.model_id
    end

    test "does not move bundled children to wanted during reconciliation" do
      andromeda_vehicle = create(:vehicle, user: @user, model: @andromeda_model, wanted: false)
      bundled = Vehicle.find_by(bundled: true, vehicle_id: andromeda_vehicle.id)
      assert bundled.present?

      ::HangarSync.new(@input).run(@user.id)

      assert_equal true, bundled.reload.bundled
      assert_equal false, bundled.wanted
    end

    test "creates no bundled child vehicles when the run opted out" do
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, add_bundled_vehicles: false)

      ::HangarSync.new(@input).run_with_import(import)

      assert_empty Vehicle.where(bundled: true, user_id: @user.id)
    end

    # The option prevents new rows; it does not orphan the ones the user already
    # has. A parent the sync pushes onto the wishlist still takes its snub craft
    # with it, or the two would disagree about whether the ship is owned.
    test "keeps an existing bundled child following its parent when opted out" do
      javelin_model = Model.find_by!(slug: "aegs-javelin")
      javelin_model.snub_crafts << @snub_model

      # Absent from the pledge list, so the sync pushes it onto the wishlist --
      # and the snub craft it carries has to go with it, or the two disagree
      # about whether the ship is owned.
      javelin = create(:vehicle, user: @user, model: javelin_model, wanted: false)
      bundled = Vehicle.find_by!(bundled: true, vehicle_id: javelin.id)
      refute_predicate bundled, :wanted?

      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, add_bundled_vehicles: false)
      ::HangarSync.new(@input).run_with_import(import)

      assert_predicate javelin.reload, :wanted?
      assert_predicate bundled.reload, :wanted?
    end

    test "restores the switch once the run is over" do
      import = ::Imports::HangarSync.create!(user_id: @user.id, input: @input, add_bundled_vehicles: false)

      ::HangarSync.new(@input).run_with_import(import)

      refute Vehicle.skip_bundled_snub_crafts

      other_user = create(:user)
      create(:vehicle, user: other_user, model: @andromeda_model, wanted: false)

      assert_predicate Vehicle.where(bundled: true, user_id: other_user.id).count, :positive?
    end
  end

  class WhenRsiPledgeIdChangesTest < HangarSyncTest
    setup do
      @andromeda_model = Model.find_by!(slug: "rsi-constellation-andromeda")
      @andromeda_ship = create(:vehicle, user: @user, model: @andromeda_model, name: "USS Troi", wanted: false, public: true,
        rsi_pledge_id: "OLD_PLEDGE_ID", rsi_pledge_synced_at: 1.day.ago)
    end

    test "updates the existing vehicle instead of creating a duplicate" do
      travel_to 1.minute.from_now do
        result = ::HangarSync.new(@input).run(@user.id)

        assert_includes result[:found_vehicles], @andromeda_ship.id
        refute_includes result[:moved_vehicles_to_wanted], @andromeda_ship.id

        @andromeda_ship.reload
        assert_equal "00064313", @andromeda_ship.rsi_pledge_id
        assert_equal false, @andromeda_ship.wanted
        assert_equal "USS Troi", @andromeda_ship.name

        andromeda_vehicles = Vehicle.where(user_id: @user.id, model_id: @andromeda_model.id)
        assert_equal 1, andromeda_vehicles.count
      end
    end
  end

  class WithPaintOnlyPledgeTest < HangarSyncTest
    test "matches a paint the RSI hangar names after its ship" do
      gladius = Model.find_by!(slug: "aegs-gladius")
      paint = create(:model_paint, model: gladius, name: "Dunlevy")

      input = @input + [{"id" => "99999", "type" => "ship", "name" => "Gladius Dunlevy"}]

      result = ::HangarSync.new(input).run(@user.id)

      assert_equal [], result[:missing_models]

      vehicle = Vehicle.where(id: result[:imported_vehicles]).find_by(model_paint_id: paint.id)
      assert vehicle.present?
      assert_equal gladius.id, vehicle.model_id
    end
  end

  class NotificationTest < HangarSyncTest
    test "summarises the sync in the notification body" do
      result = ::HangarSync.new(@input).run(@user.id)

      body = Notification.find_by!(user: @user, notification_type: :hangar_sync_finished).body

      assert_includes body, I18n.t("notifications.hangar_sync_finished.body")
      assert_includes body, "- Added ships: **#{result[:imported_vehicles].size}**"
      refute_includes body, "Found ships"
      refute_includes body, I18n.t("notifications.hangar_sync_finished.warnings")
    end

    test "lists the items a sync could not match" do
      input = @input + [{"id" => "1", "type" => "ship", "name" => "Mystery Ship"}]

      ::HangarSync.new(input).run(@user.id)

      body = Notification.find_by!(user: @user, notification_type: :hangar_sync_finished).body

      assert_includes body, I18n.t("notifications.hangar_sync_finished.warnings")
      assert_includes body, "- Ships not found: **1** (Mystery Ship)"
    end

    test "caps the listed items and counts the rest" do
      missing = (1..12).map { |index| {"id" => index.to_s, "type" => "ship", "name" => "Mystery Ship #{index}"} }

      ::HangarSync.new(@input + missing).run(@user.id)

      body = Notification.find_by!(user: @user, notification_type: :hangar_sync_finished).body

      assert_includes body, "Mystery Ship 10"
      refute_includes body, "Mystery Ship 11"
      assert_includes body, I18n.t("notifications.hangar_sync_finished.more_items", count: 2)
    end
  end
end
