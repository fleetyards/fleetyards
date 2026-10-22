class HangarSync < HangarImporter
  include HangarModuleMapping

  attr_accessor :data, :ships, :components, :upgrades

  ITEM_TYPES = %w[ship component upgrade skin flair equipment extra ccu].freeze

  OUTCOMES = %w[synced nothing_to_sync only_skipped_items].freeze

  # Runs that skipped every sync step. They still finish an import, which the
  # sync status endpoint reads back for the result card, but they are not a sync.
  NO_OP_OUTCOMES = (OUTCOMES - ["synced"]).freeze

  COMPONENT_FIND_QUERY = [
    "lower(name) = :name",
    "slug = :slug",
    "lower(name) = :normalized_name",
    "slug = :normalized_name"
  ].freeze

  SUMMARY_KEYS = %i[
    imported_vehicles
    found_vehicles
    moved_vehicles_to_wanted
    deleted_vehicles
    grouped_vehicles
    unchanged_vehicles
    imported_components
    found_components
    imported_upgrades
    found_upgrades
    synced_paints
    synced_hangar_flair
    synced_equipment
    synced_ccus
    synced_ship_components
  ].freeze

  WARNING_KEYS = %i[
    missing_models
    missing_components
    missing_component_vehicles
    missing_upgrades
    missing_upgrade_vehicles
  ].freeze

  # A hangar can miss dozens of items at once, and the notification body is read
  # in a narrow reading pane.
  MAX_LISTED_ITEMS = 10

  def initialize(data)
    @data = data.map { |item| item.deep_transform_keys { |key| key.to_s.underscore.to_sym } }
    @ships = @data.select { |item| item[:type] == "ship" }
    # Ship parts are listed as components too; those are pledge items, and only
    # the modules are fitted to a ship here.
    @components = @data.select { |item| item[:type] == "component" && ::HangarModuleMapping.module?(item[:name]) }
    @upgrades = @data.select { |item| item[:type] == "upgrade" }
  end

  def run(user_id)
    import = Imports::HangarSync.create!(
      user_id:,
      input: @data
    )

    run_with_import(import)
  end

  def run_with_import(import)
    # Cancelled while it was still queued.
    return if import.cancelled?

    @import = import
    import.start!

    outcome = sync_outcome
    output = (outcome == "synced") ? sync_everything(import) : (SUMMARY_KEYS + WARNING_KEYS).index_with { [] }
    output[:outcome] = outcome
    output[:incomplete] = true if import.unread_pages.any?

    import.update!(output:)

    # Stopped at a checkpoint, or cancelled inside the window between the
    # transition and the last one. Either way the state has already moved and
    # `finish` has no transition out of `cancelled`.
    if import.reload.cancelled?
      camel_case_output = output.transform_keys { |key| key.to_s.camelize(:lower) }
      HangarSyncChannel.broadcast_to(import.user, {status: "cancelled", result: camel_case_output})

      return output
    end

    import.finish!

    camel_case_output = output.transform_keys { |key| key.to_s.camelize(:lower) }
    HangarSyncChannel.broadcast_to(import.user, {status: "finished", result: camel_case_output})
    return output unless outcome == "synced"

    I18n.with_locale(import.user.notification_locale) do
      Notification.notify!(
        user: import.user,
        type: :hangar_sync_finished,
        title: I18n.t("notifications.hangar_sync_finished.title"),
        body: sync_notification_body(output),
        link: Rails.application.routes.url_helpers.frontend_hangar_path,
        record: import
      )
    end

    output
  rescue => e
    # `fail` has no transition out of `cancelled`, and raising over the original
    # exception would hide what actually went wrong.
    import.fail! if import&.may_fail?
    import&.update!(info: e.message)

    if import&.user
      HangarSyncChannel.broadcast_to(import.user, {status: "failed", error: e.message})
      I18n.with_locale(import.user.notification_locale) do
        Notification.notify!(
          user: import.user,
          type: :hangar_sync_failed,
          title: I18n.t("notifications.hangar_sync_failed.title"),
          body: I18n.t("notifications.hangar_sync_failed.body", error: e.message),
          link: Rails.application.routes.url_helpers.frontend_hangar_path,
          record: import
        )
      end
    end

    raise e
  end

  # Decided before anything is touched: an empty paint or flair list would
  # otherwise replace the stored ones with nothing, and a run without a ship
  # lists every purchased one as unchanged.
  private def sync_outcome
    return "synced" if @ships.any? || @components.any? || @upgrades.any?

    pledge_kinds = item_kinds.compact
    return "nothing_to_sync" if pledge_kinds.empty?

    pledge_kinds.intersect?(pledge_item_kinds) ? "synced" : "only_skipped_items"
  end

  private def sync_everything(import)
    user_id = import.user_id

    # A sync rewrites `name` and `wanted` on rows a user also edits by hand, so
    # nothing in here is a change the user made. Held out here rather than at
    # each `update!` so a write added later is silent by default.
    vehicles, components, upgrades = PaperTrail.request(enabled: false) do
      Vehicle.with_bundled_snub_crafts(import.add_bundled_vehicles?) do
        [sync_vehicles(user_id), sync_components(user_id), sync_upgrades(user_id)]
      end
    end

    pledge_items = sync_pledge_items(import.user)

    imported_components, found_components, missing_components, missing_component_vehicles = components
    imported_upgrades, found_upgrades, missing_upgrades, missing_upgrade_vehicles = upgrades

    # A hash rather than a tuple: the vehicle half of a run reports seven lists,
    # four of which are the outcome the user picked for the ships it could not
    # find, and positional unpacking stopped being readable somewhere before that.
    {
      **vehicles,
      imported_components:,
      found_components:,
      missing_components:,
      missing_component_vehicles:,
      imported_upgrades:,
      found_upgrades:,
      missing_upgrades:,
      missing_upgrade_vehicles:,
      synced_paints: pledge_items.fetch("paint", []),
      synced_hangar_flair: pledge_items.fetch("flair", []),
      synced_equipment: pledge_items.fetch("equipment", []),
      synced_ccus: pledge_items.fetch("ccu", []),
      synced_ship_components: pledge_items.fetch("ship_component", [])
    }
  end

  # The sync modal is gone as soon as the user closes it, so the notification is
  # the only lasting record of what a sync actually did.
  private def sync_notification_body(output)
    counts = SUMMARY_KEYS.filter_map do |key|
      count = output[key].size
      next if count.zero?

      "- #{I18n.t("notifications.hangar_sync_finished.summary.#{key}")}: **#{count}**"
    end

    warnings = WARNING_KEYS.filter_map do |key|
      items = output[key]
      next if items.empty?

      "- #{I18n.t("notifications.hangar_sync_finished.summary.#{key}")}: **#{items.size}** (#{listed_items(items)})"
    end

    warnings << "- #{I18n.t("notifications.hangar_sync_finished.incomplete")}" if output[:incomplete]

    lines = [I18n.t("notifications.hangar_sync_finished.body")]
    lines += ["", *counts] if counts.present?
    lines += ["", "#### #{I18n.t("notifications.hangar_sync_finished.warnings")}", "", *warnings] if warnings.present?

    lines.join("\n")
  end

  private def listed_items(items)
    listed = items.first(MAX_LISTED_ITEMS)
    remaining = items.size - listed.size

    return listed.join(", ") if remaining.zero?

    "#{listed.join(", ")}, #{I18n.t("notifications.hangar_sync_finished.more_items", count: remaining)}"
  end

  def sync_vehicles(user_id)
    vehicle_ids = []
    imported_vehicles = []
    found_vehicles = []
    missing_models = []
    vehicle_scope = Vehicle.where(user_id: user_id, loaner: false, bundled: false, hidden: false, bought_via: :pledge_store).order(created_at: :asc)

    @ships.each_with_index do |item, index|
      break if stop_requested?(index)

      model_query = generate_model_query(item[:name])
      paint_query = generate_paint_query(item[:name])
      params = default_params(user_id, item)

      model = Model.where(model_query).first
      if model.present?
        vehicle_with_ref = vehicle_scope.where.not(id: vehicle_ids).find_by(
          model_id: model.id,
          rsi_pledge_id: item[:id]
        )

        if vehicle_with_ref.present?
          vehicle_with_ref.update!(
            **pledge_details(item),
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle_with_ref.name,
            wanted: false
          )

          vehicle_ids << vehicle_with_ref.id
          found_vehicles << vehicle_with_ref.id

          next
        end

        # A plain pledge goes to a hull no painted pledge has claimed, where
        # there is one, so the painted pledges still find theirs.
        vehicle = vehicle_scope.where.not(id: vehicle_ids).where(model_id: model.id)
          .reorder(Arel.sql("EXISTS (SELECT 1 FROM vehicle_paints WHERE vehicle_paints.vehicle_id = vehicles.id) ASC"), created_at: :asc)
          .first

        if vehicle.present?
          vehicle.update!(
            **pledge_details(item),
            rsi_pledge_id: item[:id],
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle.name,
            wanted: false
          )

          vehicle_ids << vehicle.id
          found_vehicles << vehicle.id

          next
        end

        vehicle = vehicle_scope.create!(params.merge(model_id: model.id))
        vehicle_ids << vehicle.id
        imported_vehicles << vehicle.id
        next
      end

      # A painted ship pledge: the hull, with the paint it came in recorded as
      # owned. Which paint the ship wears is the loadout's to say. Only a hull
      # already bound to this pledge or owning this paint is its match -- any
      # other hull may be a plain pledge's that comes later in the list.
      model_paint = ModelPaint.where(paint_query).first
      if model_paint.present?
        candidates = vehicle_scope.where.not(id: vehicle_ids).where(model_id: model_paint.model_id)
        vehicle = candidates.find_by(rsi_pledge_id: item[:id]) ||
          candidates.where(id: VehiclePaint.where(model_paint_id: model_paint.id).select(:vehicle_id)).first

        if vehicle.present?
          vehicle.update!(
            **pledge_details(item),
            rsi_pledge_id: item[:id],
            rsi_pledge_synced_at: Time.current,
            name: item[:custom_name]&.strip.presence || vehicle.name,
            wanted: false
          )
          record_owned_paint(vehicle, model_paint, item)
          vehicle_ids << vehicle.id
          found_vehicles << vehicle.id
          next
        end

        # A new ship looks the way its pledge showed it.
        picture = model_paint if model_paint.store_image.attached?
        vehicle = vehicle_scope.create!(params.merge(model_id: model_paint.model_id, picture:))
        record_owned_paint(vehicle, model_paint, item)
        vehicle_ids << vehicle.id
        imported_vehicles << vehicle.id
        next
      end

      missing_models << item[:name]
    end

    # Reconcile: match newly imported vehicles against unmatched existing vehicles
    # This handles cases where pledge IDs changed and the normal matching failed
    unmatched_vehicle_ids = with_owned_paints(vehicle_scope.where.not(id: vehicle_ids).pluck(:id, :model_id))
    imported_vehicle_records = with_owned_paints(Vehicle.where(id: imported_vehicles).pluck(:id, :model_id))

    # An imported ship takes over an unmatched one of the same model that owns
    # every paint it came in.
    imported_vehicle_records.each do |imported_id, imported_model_id, imported_paint_ids|
      match = unmatched_vehicle_ids.find do |_, model_id, paint_ids|
        model_id == imported_model_id && (imported_paint_ids - paint_ids).empty?
      end
      next unless match

      original_id = match[0]
      original_vehicle = Vehicle.find(original_id)
      imported_vehicle = Vehicle.find(imported_id)

      # Transfer the new pledge data to the original vehicle
      original_vehicle.update!(
        **imported_vehicle.slice(:rsi_pledge_melt_value, :rsi_pledge_meltable, :rsi_pledge_item_count).symbolize_keys,
        rsi_pledge_id: imported_vehicle.rsi_pledge_id,
        rsi_pledge_synced_at: imported_vehicle.rsi_pledge_synced_at,
        wanted: false
      )

      imported_vehicle.vehicle_paints.each do |imported_paint|
        original_vehicle.vehicle_paints.find_by(model_paint_id: imported_paint.model_paint_id)&.update!(
          rsi_pledge_id: imported_paint.rsi_pledge_id,
          rsi_pledge_synced_at: imported_paint.rsi_pledge_synced_at
        )
      end

      # Remove the duplicate
      imported_vehicle.destroy!

      # Update tracking arrays
      vehicle_ids << original_id
      vehicle_ids.delete(imported_id)
      imported_vehicles.delete(imported_id)
      found_vehicles << original_id
      unmatched_vehicle_ids.delete(match)
    end

    assign_target_group(vehicle_ids)

    {
      imported_vehicles:,
      found_vehicles:,
      missing_models:,
      **handle_unmatched_vehicles(
        vehicle_scope.purchased.where.not(id: vehicle_ids),
        recognised_any: found_vehicles.any? || imported_vehicles.any?
      )
    }
  end

  # Every vehicle the run did not find in the pledge list. What happens to them
  # is the user's choice, carried on the import; `wishlist` is what every sync
  # did before the choice existed, and is what a client that does not send one
  # still gets.
  #
  # The scope is `purchased` -- a wishlisted ship is one the user does not own,
  # so it was never going to be in an RSI hangar and is unmatched every single
  # run. `delete` would empty the whole wishlist on the first sync. The wishlist
  # move never touched those rows either: `reset_pledge_id_if_wanted` has
  # already cleared what it writes, so the `update!` was a no-op that the
  # `updated_at` check below kept out of the report.
  private def handle_unmatched_vehicles(scope, recognised_any: true)
    outcome = {
      moved_vehicles_to_wanted: [],
      deleted_vehicles: [],
      grouped_vehicles: [],
      unchanged_vehicles: []
    }

    # A cancelled run never saw the rest of the pledge list, so every vehicle it
    # had not reached yet still looks unmatched. Acting on those would make
    # stopping a sync worse than letting it finish -- and under `delete` it
    # would take the hangar with it.
    #
    # `@cancelled` alone is not enough: it is only set at the ship loop's
    # checkpoints, so a cancel landing after the last one leaves it false while
    # the row already says cancelled. That gap was survivable while the only
    # outcome was a wishlist move the user could undo by hand. It is not
    # survivable under `delete`, so the row is read once more here.
    return outcome if @cancelled || @import&.cancel_requested?

    # A run that recognised no ship at all, neither one the user has nor a new
    # one, is what a changed RSI page looks like once only components and paints
    # still parse. Every ship would read as unmatched, and under `delete` the
    # hangar would go with them. A hangar whose ships really are all gone keeps
    # them, listed as unchanged.
    return outcome.merge(unchanged_vehicles: scope.pluck(:id)) unless recognised_any

    # The parser could not read every item, and any one of them may be a ship.
    # It would read as gone, so this run leaves the unmatched ones as they are.
    return outcome.merge(unchanged_vehicles: scope.pluck(:id)) if @import&.unread_pages&.any?

    case @import&.unmatched_vehicles_action
    when "keep" then outcome.merge(unchanged_vehicles: scope.pluck(:id))
    when "delete" then outcome.merge(deleted_vehicles: delete_unmatched(scope))
    when "group" then outcome.merge(group_unmatched(scope))
    else outcome.merge(moved_vehicles_to_wanted: move_unmatched_to_wanted(scope))
    end
  end

  private def move_unmatched_to_wanted(scope)
    moved = []

    scope.find_each do |vehicle|
      initial_updated_at = vehicle.updated_at
      vehicle.update!(rsi_pledge_id: nil, rsi_pledge_synced_at: nil, wanted: true)

      moved << vehicle.id if initial_updated_at != vehicle.updated_at
    end

    moved
  end

  # Names rather than ids, and read before the delete: nothing is left to
  # resolve an id from afterwards, and the notification and the imports page
  # both say what a run did in ships rather than in uuids.
  #
  # `delete_with_dependents` rather than `destroy_all`: it takes the loaners and
  # bundled snub crafts hanging off each row with it, and `vehicle_loadouts`
  # carries a foreign key that a plain delete would raise on.
  private def delete_unmatched(scope)
    vehicles = scope.includes(:model).to_a
    return [] if vehicles.empty?

    names = vehicles.map { |vehicle| vehicle.name.presence || vehicle.model&.name }.compact.sort

    Vehicle.delete_with_dependents(vehicles.map(&:id))

    names
  end

  # The vehicles themselves are left exactly as they were. The point of the
  # option is to collect what the sync could not find somewhere the user can
  # work through by hand, not to decide anything about those ships -- and
  # `wanted` is not available to it either way, because a wishlisted vehicle
  # drops its groups on save.
  #
  # The group can be gone by the time the run reaches this: the foreign key
  # nullifies rather than cascading, so deleting it between queueing a sync and
  # running one leaves the action behind without its target. The ships are left
  # alone and reported as such -- calling them filed somewhere they are not
  # would be the one answer worse than doing nothing.
  private def group_unmatched(scope)
    group_id = @import&.unmatched_hangar_group_id
    vehicle_ids = scope.pluck(:id)

    return {unchanged_vehicles: vehicle_ids} if group_id.blank?

    file_into_group(vehicle_ids, group_id)

    {grouped_vehicles: vehicle_ids}
  end

  private def sync_components(user_id)
    vehicle_module_ids = []
    imported_components = []
    found_components = []
    missing_components = []
    missing_component_vehicles = []

    user = User.find(user_id)

    @components.each_with_index do |item, index|
      break if stop_requested?(index)

      # A module the mapping does not know, or whose ship is not in the
      # catalogue, could not be matched: said so rather than dropped.
      mapped = component_mapping(item[:name])
      model = Model.where(name: mapped[:model_names]).first if mapped.present?
      if model.blank?
        missing_components << item[:name]
        next
      end

      component_query = generate_module_query(mapped[:module_name])
      component = model.modules.where(component_query).first
      if component.blank?
        missing_components << item[:name]
        next
      end

      vehicle_module_with_ref = user.vehicle_modules.where(
        model_module_id: component.id,
        rsi_pledge_id: item[:id]
      ).first
      if vehicle_module_with_ref.present?
        vehicle_module_with_ref.update!(rsi_pledge_synced_at: Time.current)

        vehicle_module_ids << vehicle_module_with_ref.id
        found_components << vehicle_module_with_ref.id

        next
      end

      vehicle_module = user.vehicle_modules.where.not(id: vehicle_module_ids).find_by(
        model_module_id: component.id
      )
      if vehicle_module.present?
        vehicle_module.update!(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)

        vehicle_module_ids << vehicle_module.id
        found_components << vehicle_module.id

        next
      end

      vehicle = Vehicle.where(
        user_id: user_id, loaner: false, hidden: false, model_id: component.model_ids
      ).order(created_at: :asc).first
      if vehicle.blank?
        missing_component_vehicles << item[:name]

        next
      end

      new_vehicle_module = vehicle.vehicle_modules.create!(model_module_id: component.id)

      vehicle_module_ids << new_vehicle_module.id
      imported_components << new_vehicle_module.id
    end

    [imported_components, found_components, missing_components, missing_component_vehicles]
  end

  private def sync_upgrades(user_id)
    vehicle_upgrade_ids = []
    imported_upgrades = []
    found_upgrades = []
    missing_upgrades = []
    missing_upgrade_vehicles = []

    user = User.find(user_id)

    @upgrades.each_with_index do |item, index|
      break if stop_requested?(index)

      upgrade_query = generate_upgrade_query(item[:name])
      upgrade = ModelUpgrade.where(upgrade_query).first
      if upgrade.blank?
        missing_upgrades << item[:name]
        next
      end

      vehicle_upgrade_with_ref = user.vehicle_upgrades.where(
        model_upgrade_id: upgrade.id,
        rsi_pledge_id: item[:id]
      ).first
      if vehicle_upgrade_with_ref.present?
        vehicle_upgrade_with_ref.update!(rsi_pledge_synced_at: Time.current)

        vehicle_upgrade_ids << vehicle_upgrade_with_ref.id
        found_upgrades << vehicle_upgrade_with_ref.id

        next
      end

      vehicle_upgrade = user.vehicle_upgrades.where.not(id: vehicle_upgrade_ids).find_by(
        model_upgrade_id: upgrade.id
      )
      if vehicle_upgrade.present?
        vehicle_upgrade.update!(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)

        vehicle_upgrade_ids << vehicle_upgrade.id
        found_upgrades << vehicle_upgrade.id

        next
      end

      vehicle = Vehicle.where(user_id: user_id, loaner: false, hidden: false, model_id: upgrade.model_ids).order(created_at: :asc).first
      if vehicle.blank?
        missing_upgrade_vehicles << item[:name]

        next
      end

      new_vehicle_upgrade = vehicle.vehicle_upgrades.create!(model_upgrade_id: upgrade.id)

      vehicle_upgrade_ids << new_vehicle_upgrade.id
      imported_upgrades << new_vehicle_upgrade.id
    end

    [imported_upgrades, found_upgrades, missing_upgrades, missing_upgrade_vehicles]
  end

  private def generate_model_query(item_name)
    name = rsi_hangar_mapping(item_name)
    normalized_name = normalize(name)

    [
      (MODEL_FIND_QUERY + MODEL_LEGACY_SLUG_QUERY).join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def generate_paint_query(item_name)
    name = rsi_hangar_mapping(item_name)
    normalized_name = normalize(name)

    [
      MODEL_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def generate_module_query(item_name)
    name = item_name
    normalized_name = normalize(name)

    [
      COMPONENT_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  private def generate_upgrade_query(item_name)
    name = item_name
    # Add mapping when needed
    # name = rsi_hangar_upgrade_mapping(item_name)
    normalized_name = normalize(name)

    [
      COMPONENT_FIND_QUERY.join(" OR "),
      {
        name: name.downcase,
        slug: name.downcase,
        normalized_name:,
        search: "%#{normalized_name}%"
      }
    ]
  end

  # Every vehicle the sync touches, not only the ones it creates: an RSI hangar
  # carries no group information, so "sync into this group" is only useful if it
  # files the whole pledge list there. Additive -- a vehicle keeps any group the
  # user had already put it in.
  private def assign_target_group(vehicle_ids)
    file_into_group(vehicle_ids, @import&.hangar_group_id)
  end

  private def file_into_group(vehicle_ids, group_id)
    return if group_id.blank? || vehicle_ids.blank?

    existing = TaskForce.where(hangar_group_id: group_id, vehicle_id: vehicle_ids).pluck(:vehicle_id)
    now = Time.current

    rows = (vehicle_ids.uniq - existing).map do |vehicle_id|
      {vehicle_id:, hangar_group_id: group_id, created_at: now, updated_at: now}
    end

    # `task_forces` carries no unique index, so a duplicate would be accepted
    # rather than rejected -- the read above is what keeps a re-sync from
    # stacking rows.
    return if rows.empty?

    TaskForce.insert_all(rows)

    filed_ids = rows.pluck(:vehicle_id)
    Vehicle.schedule_fleet_vehicle_updates(filed_ids + Vehicle.where(loaner: true, vehicle_id: filed_ids).ids)
  end

  # The paints, flair and equipment are replaced as a whole, so a run stopped part way
  # leaves the stored ones alone rather than replacing them with a partial list.
  private def sync_pledge_items(user)
    return {} if @cancelled || @import&.cancel_requested?

    ::HangarPledgeItems::Sync.new(user, @data, kinds: pledge_item_kinds, item_kinds:,
      keep_unlisted: @import&.unread_pages&.any?).run
  end

  # Sorting the extras reads the whole equipment catalogue, so it happens once
  # a run.
  private def item_kinds
    @item_kinds ||= ::HangarPledgeItems::Sync.kinds_for(@data)
  end

  private def pledge_item_kinds
    kinds = []
    kinds << "paint" if @import.nil? || @import.sync_paints?
    kinds << "flair" if @import.nil? || @import.sync_hangar_flair?
    kinds << "ccu" if @import.nil? || @import.sync_ccus?
    kinds << "equipment" if @import.nil? || @import.sync_equipment?
    kinds << "ship_component" if @import.nil? || @import.sync_ship_components?
    kinds
  end

  private def stop_requested?(index)
    return false unless (index % ::HangarImporter::CANCEL_CHECK_INTERVAL).zero?
    return false unless @import&.cancel_requested?

    @cancelled = true
  end

  private def record_owned_paint(vehicle, model_paint, item)
    vehicle.vehicle_paints.find_or_initialize_by(model_paint:)
      .update!(rsi_pledge_id: item[:id], rsi_pledge_synced_at: Time.current)
  end

  # `[id, model_id]` pairs, each with the ids of the paints the vehicle owns.
  private def with_owned_paints(rows)
    owned = VehiclePaint.where(vehicle_id: rows.map(&:first)).pluck(:vehicle_id, :model_paint_id)
      .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }

    rows.map { |id, model_id| [id, model_id, owned.fetch(id, [])] }
  end

  private def default_params(user_id, item)
    {
      notify: false,
      user_id:,
      name: item[:custom_name],
      wanted: false,
      bought_via: :pledge_store,
      public: true,
      name_visible: false,
      sale_notify: false,
      rsi_pledge_id: item[:id],
      rsi_pledge_synced_at: Time.current,
      **pledge_details(item)
    }
  end

  # What RSI says about the pledge a ship came in: what melting it credits,
  # whether RSI lets it be melted, and how many items go with it when it is.
  # Only what the item says is written, so a sync that leaves one out keeps
  # the value an earlier one read.
  private def pledge_details(item)
    details = {}
    details[:rsi_pledge_melt_value] = item[:pledge_value].presence if item.key?(:pledge_value)
    details[:rsi_pledge_meltable] = ActiveModel::Type::Boolean.new.cast(item[:meltable]) || false if item.key?(:meltable)
    details[:rsi_pledge_item_count] = item[:pledge_item_count].presence if item.key?(:pledge_item_count)
    details
  end

  private def rsi_hangar_mapping(name)
    name = name.tr("–", "-")

    Rsi::ShipNames::MAPPING.fetch(name.strip, name)
  end

  private def rsi_hangar_upgrade_mapping(name)
    mapping = {
      "Hurston Dynamics Exodus Laser Beam" => "Idris-K"
    }

    return name if mapping[name.strip].nil?

    mapping[name.strip]
  end
end
