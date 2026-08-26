# frozen_string_literal: true

require "test_helper"

# Characterization tests for `#update_loadout` -- the recursive walk that turns a
# parsed loadout tree into hardpoint rows. It had no coverage at all, and it is
# both the most consequential code in the ingest path (a bug here silently
# reshapes every ship's loadout) and the next thing due for refactoring.
#
# These pin behaviour as it *is*, quirks included. Several assertions below
# describe things that look like bugs; they are marked as such. A refactor that
# changes one should fail here and be an explicit decision, not a surprise.
module ScData
  module Loader
    class BaseLoaderLoadoutTest < ActiveSupport::TestCase
      setup do
        @loader = ::ScData::Loader::BaseLoader.new
        @model = create(:model)
      end

      private def update_loadout(parent, loadout, **kwargs)
        @loader.send(:update_loadout, parent, loadout, **kwargs)
      end

      private def game_files_hardpoints(parent)
        parent.hardpoints.reload.where(source: :game_files)
      end

      # --- Resolution by key ------------------------------------------------

      test "creates a game_files hardpoint per entry and resolves the component by key" do
        component = create(:component, sc_key: "power_plant_s2", size: "2")

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_power", "key" => "power_plant_s2"}]})

        hardpoint = game_files_hardpoints(@model).sole
        assert_equal "hardpoint_power", hardpoint.sc_name
        assert_equal component, hardpoint.component
        assert_equal "game_files", hardpoint.source
      end

      # The game files are inconsistent about capitalisation on both sides, so
      # the name is stored lowered and the key is lowered for the lookup.
      test "downcases the hardpoint name and the key it looks the component up by" do
        component = create(:component, sc_key: "power_plant_s2")

        update_loadout(@model, {"loadout" => [{"name" => "Hardpoint_POWER", "key" => "Power_Plant_S2"}]})

        hardpoint = game_files_hardpoints(@model).sole
        assert_equal "hardpoint_power", hardpoint.sc_name
        assert_equal component, hardpoint.component
      end

      # Size is carried onto both bounds: a loaded hardpoint is exactly the size
      # of what sits in it, not a range.
      test "takes min_size and max_size from the component size" do
        create(:component, sc_key: "shield_s3", size: "3")

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_shield", "key" => "shield_s3"}]})

        hardpoint = game_files_hardpoints(@model).sole
        assert_equal 3, hardpoint.min_size
        assert_equal 3, hardpoint.max_size
      end

      test "resolves by ref when the entry carries no key" do
        component = create(:component, sc_ref: "a1b2c3", sc_key: "cooler_s1")

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_cooler", "ref" => "a1b2c3"}]})

        assert_equal component, game_files_hardpoints(@model).sole.component
      end

      # QUIRK: key and ref are an if/elsif, so a key that is present but does not
      # resolve leaves the hardpoint empty even when the ref alongside it would
      # have resolved. Ref is a fallback for a *missing* key, not a failed one.
      test "does not fall back to ref when a present key fails to resolve" do
        create(:component, sc_ref: "a1b2c3", sc_key: "cooler_s1")

        update_loadout(
          @model,
          {"loadout" => [{"name" => "hardpoint_cooler", "key" => "no_such_key", "ref" => "a1b2c3"}]}
        )

        assert_nil game_files_hardpoints(@model).sole.component
      end

      # An unresolved entry still gets a row: the ship has a slot there even if
      # we cannot say what fills it.
      test "keeps the hardpoint with no component when nothing resolves" do
        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_mystery", "key" => "absent"}]})

        hardpoint = game_files_hardpoints(@model).sole
        assert_equal "hardpoint_mystery", hardpoint.sc_name
        assert_nil hardpoint.component
      end

      # --- default_loadout fallback ----------------------------------------

      test "adopts key and ref from the matching default_loadout entry when the item has neither" do
        component = create(:component, sc_key: "default_gun")

        update_loadout(@model, {
          "loadout" => [{"name" => "hardpoint_gun"}],
          "default_loadout" => [{"name" => "hardpoint_gun", "key" => "default_gun"}]
        })

        assert_equal component, game_files_hardpoints(@model).sole.component
      end

      # QUIRK: the item is matched to its default by exact `name`, while the
      # hardpoint row is keyed on the *downcased* name. So a default whose
      # capitalisation differs is silently not applied.
      test "matches default_loadout on the raw name, case-sensitively" do
        create(:component, sc_key: "default_gun")

        update_loadout(@model, {
          "loadout" => [{"name" => "Hardpoint_Gun"}],
          "default_loadout" => [{"name" => "hardpoint_gun", "key" => "default_gun"}]
        })

        assert_nil game_files_hardpoints(@model).sole.component
      end

      # --- Derived module keys ---------------------------------------------

      test "derives <model>_module for a *_module entry with no key or ref" do
        @model.update!(sc_key: "drak_caterpillar")
        component = create(:component, sc_key: "drak_caterpillar_module")

        update_loadout(@model, {"loadout" => [{"name" => "cargo_module"}]})

        assert_equal component, game_files_hardpoints(@model).sole.component
      end

      test "leaves the entry unresolved when no component matches the derived module key" do
        @model.update!(sc_key: "drak_caterpillar")

        update_loadout(@model, {"loadout" => [{"name" => "cargo_module"}]})

        assert_nil game_files_hardpoints(@model).sole.component
      end

      # The derivation is gated on the parent being a Model, so the same entry
      # nested under a hardpoint does not get it.
      test "does not derive a module key when the parent is a hardpoint" do
        @model.update!(sc_key: "drak_caterpillar")
        create(:component, sc_key: "drak_caterpillar_module")
        parent = create(:hardpoint, parent: @model, source: :game_files, sc_name: "bay")

        update_loadout(parent, {"loadout" => [{"name" => "cargo_module"}]})

        assert_nil game_files_hardpoints(parent).sole.component
      end

      # --- Hidden components are flattened away -----------------------------

      # A hidden component is a container the game files model as an item -- a
      # door that holds a cargo grid. It gets no hardpoint of its own; its
      # sub-hardpoints are promoted onto the parent under a compound name.
      test "flattens a hidden component into parent-named child hardpoints" do
        cargo_grid = create(:component, sc_key: "cargo_grid_s4", size: "4")
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "grid", component: cargo_grid, source: :game_files)

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_door", "key" => "cargo_door"}]})

        hardpoint = game_files_hardpoints(@model).sole
        assert_equal "hardpoint_door-grid", hardpoint.sc_name
        assert_equal cargo_grid, hardpoint.component
      end

      # The items loader cannot always resolve a hidden component's own
      # sub-hardpoints, so the model's nested loadout is consulted to fill the
      # gap -- matched on the sub-hardpoint's (already lowered) name.
      test "fills a blank sub-component from the nested loadout" do
        cargo_grid = create(:component, sc_key: "cargo_grid_s4")
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "grid", component: nil, source: :game_files)

        update_loadout(@model, {
          "loadout" => [{
            "name" => "hardpoint_door",
            "key" => "cargo_door",
            "loadout" => [{"name" => "Grid", "key" => "cargo_grid_s4"}]
          }]
        })

        assert_equal cargo_grid, game_files_hardpoints(@model).sole.component
      end

      test "drops sub-hardpoints that resolve to nothing at all" do
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "grid", component: nil, source: :game_files)

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_door", "key" => "cargo_door"}]})

        assert_empty game_files_hardpoints(@model)
      end

      # The sub-hardpoint side of the blacklist is checked against the
      # component's sc_key, not against the hardpoint name.
      test "drops sub-hardpoints whose component key is blacklisted" do
        baywall = create(:component, sc_key: "rsi_constellation_ph_baywall_left")
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "wall", component: baywall, source: :game_files)

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_door", "key" => "cargo_door"}]})

        assert_empty game_files_hardpoints(@model)
      end

      # QUIRK: the hidden branch never touches the hardpoint it looked up, but
      # the unconditional `hardpoint_ids << hardpoint.id if hardpoint.persisted?`
      # at the end of the loop still protects it from cleanup. So a hardpoint
      # left over from a build where the component was *not* hidden survives,
      # keeping a component the flattening was supposed to replace.
      test "keeps a pre-existing hardpoint for a now-hidden component, un-updated" do
        old_component = create(:component, sc_key: "old_door_component")
        cargo_grid = create(:component, sc_key: "cargo_grid_s4")
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "grid", component: cargo_grid, source: :game_files)

        stale = create(
          :hardpoint,
          parent: @model, sc_name: "hardpoint_door", component: old_component, source: :game_files
        )

        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_door", "key" => "cargo_door"}]})

        assert Hardpoint.exists?(stale.id), "the un-updated hardpoint is protected from cleanup"
        assert_equal old_component, stale.reload.component
        assert_equal(
          ["hardpoint_door", "hardpoint_door-grid"],
          game_files_hardpoints(@model).order(:sc_name).pluck(:sc_name)
        )
      end

      # --- Blacklisting -----------------------------------------------------

      test "skips a blacklisted entry name entirely" do
        update_loadout(@model, {"loadout" => [{"name" => "aegs_retaliator_door_cap_rear"}]})

        assert_empty game_files_hardpoints(@model)
      end

      test "skips an entry whose name matches a blacklisted pattern" do
        update_loadout(@model, {"loadout" => [{"name" => "hardpoint_fuelpod_2_console"}]})

        assert_empty game_files_hardpoints(@model)
      end

      # QUIRK: with a matching default_loadout entry the check returns early on
      # the default's key/ref alone, so the name-pattern blacklist is never
      # reached. A cosmetic console that happens to carry a default is kept.
      test "bypasses the name-pattern blacklist when a default_loadout entry matches" do
        update_loadout(@model, {
          "loadout" => [{"name" => "hardpoint_refuel_console"}],
          "default_loadout" => [{"name" => "hardpoint_refuel_console", "key" => "some_display"}]
        })

        assert_equal "hardpoint_refuel_console", game_files_hardpoints(@model).sole.sc_name
      end

      # --- Recursion --------------------------------------------------------

      test "recurses into a nested loadout with the hardpoint as the parent" do
        turret = create(:component, sc_key: "turret_s4")
        gun = create(:component, sc_key: "gun_s2")

        update_loadout(@model, {
          "loadout" => [{
            "name" => "hardpoint_turret",
            "key" => "turret_s4",
            "loadout" => [{"name" => "hardpoint_gun", "key" => "gun_s2"}]
          }]
        })

        parent = game_files_hardpoints(@model).sole
        assert_equal turret, parent.component
        assert_equal gun, game_files_hardpoints(parent).sole.component
      end

      # --- Cleanup ----------------------------------------------------------

      test "destroys game_files hardpoints the run did not touch" do
        create(:component, sc_key: "kept_component")
        stale = create(:hardpoint, parent: @model, sc_name: "gone", source: :game_files)

        update_loadout(@model, {"loadout" => [{"name" => "kept", "key" => "kept_component"}]})

        refute Hardpoint.exists?(stale.id)
        assert_equal ["kept"], game_files_hardpoints(@model).pluck(:sc_name)
      end

      # Ship-matrix hardpoints are the curated ones. A game-files load must not
      # reach them, or every load would wipe hand-entered data.
      test "leaves ship_matrix hardpoints alone" do
        create(:component, sc_key: "kept_component")
        curated = create(:hardpoint, parent: @model, sc_name: "curated", source: :ship_matrix)

        update_loadout(@model, {"loadout" => [{"name" => "kept", "key" => "kept_component"}]})

        assert Hardpoint.exists?(curated.id)
      end

      # `cleanup: false` is what the hidden-component flattening recurses with,
      # so a flattening pass cannot delete what its siblings just wrote.
      test "skips cleanup entirely when cleanup is false" do
        create(:component, sc_key: "kept_component")
        stale = create(:hardpoint, parent: @model, sc_name: "gone", source: :game_files)

        update_loadout(@model, {"loadout" => [{"name" => "kept", "key" => "kept_component"}]}, cleanup: false)

        assert Hardpoint.exists?(stale.id)
      end

      # --- Return value -----------------------------------------------------

      # This used to come back with the id twice for a resolved entry -- once
      # from the branch that wrote it and once from an unconditional push at the
      # end of the loop. Splitting resolution from persistence left one push per
      # slot, so the list is now what it always read as. Safe because the only
      # consumer is the `where.not(id: ...)` cleanup, which does not care.
      test "returns one id per hardpoint it touched" do
        create(:component, sc_key: "kept_component")

        ids = update_loadout(@model, {"loadout" => [{"name" => "kept", "key" => "kept_component"}]})

        assert_equal [game_files_hardpoints(@model).sole.id], ids
      end

      test "returns a single id for an entry that resolved to no component" do
        ids = update_loadout(@model, {"loadout" => [{"name" => "mystery", "key" => "absent"}]})

        assert_equal [game_files_hardpoints(@model).sole.id], ids
      end

      # QUIRK: neither key is a NoMethodError on nil rather than a no-op. Every
      # real caller passes one, so this is latent rather than live -- but it is
      # what the method does today.
      test "raises when the payload carries neither loadout nor default_loadout" do
        assert_raises(NoMethodError) { update_loadout(@model, {}) }
      end
    end
  end
end
