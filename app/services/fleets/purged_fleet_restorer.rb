# frozen_string_literal: true

module Fleets
  # Rebuilds a hard-deleted ("purged") fleet from its PaperTrail destroy
  # versions. Best effort: only versioned models are restored (fleet, roles,
  # memberships, inventories, inventory items). ActiveStorage attachments,
  # invite urls and fleet vehicles are not recoverable; fleet vehicles
  # regenerate from member hangars once memberships are restored.
  class PurgedFleetRestorer
    class FleetStillExists < StandardError; end

    class NothingToRestore < StandardError; end

    class FidTaken < StandardError; end

    MEMBERSHIP_COLUMNS = %w[
      aasm_state accepted_at invited_at requested_at declined_at primary
      hide_ships ships_filter hangar_group_id invited_by used_invite_token verified
    ].freeze

    INVENTORY_COLUMNS = %w[description location visibility managed_by slug].freeze

    INVENTORY_ITEM_COLUMNS = %w[
      item_type item_id quantity name notes added_by member_id category entry_type quality unit
    ].freeze

    def initialize(fleet_id)
      @fleet_id = fleet_id
    end

    def call
      raise FleetStillExists if Fleet.unscoped.exists?(id: @fleet_id)

      version = latest_destroy_version("Fleet", @fleet_id)
      raise NothingToRestore if version.nil?

      ActiveRecord::Base.transaction do
        fleet = version.reify
        raise FidTaken if fleet.fid.present? && Fleet.kept.where("LOWER(fid) = ?", fleet.fid.downcase).exists?
        # The save below skips validation, and with it the reservation an open
        # FID claim holds for its claimant.
        raise FidTaken if fleet.fid.present? && FleetFidClaim.reserved?(fleet.fid)

        fleet.save!(validate: false)

        role_map = restore_roles(fleet)
        restore_squadron_ranks(fleet)
        restore_memberships(fleet, role_map)
        inventory_map = restore_inventories(fleet)
        restore_inventory_items(inventory_map)

        fleet
      end
    end

    private

    def latest_destroy_version(item_type, item_id)
      PaperTrail::Version
        .where(item_type:, item_id:, event: "destroy")
        .order(created_at: :desc)
        .first
    end

    def child_destroy_versions(item_type, foreign_key, value)
      PaperTrail::Version
        .where(item_type:, event: "destroy")
        .where("object ->> ? = ?", foreign_key, value.to_s)
    end

    # Returns a map of the old fleet_role_id => restored FleetRole so
    # memberships can be re-linked. setup_default_roles! (run on fleet save)
    # already recreated the standard roles under their seeded names, so a role
    # is matched by its slug, which a rename leaves alone, and takes back its
    # name and default from the latest snapshot -- a fleet restored and purged
    # again keeps the older purge's versions under the same fleet id.
    def restore_roles(fleet)
      map = {}
      restored_by_slug = {}

      versions = child_destroy_versions("FleetRole", "fleet_id", fleet.id).order(created_at: :desc, id: :desc)

      versions.each do |version|
        role = version.reify
        slug = role.slug.presence || role.name.to_s.parameterize

        restored_by_slug[slug] ||= restore_role(fleet, role, slug)
        map[version.item_id] = restored_by_slug[slug]
      end

      map
    end

    # The four squadron ranks are reseeded on fleet save; what the fleet called
    # them, and which one new members start on, is the part worth bringing back.
    #
    # Only the latest snapshot per rank: a fleet restored and purged again
    # leaves both purges' versions under the same fleet id, and the older name
    # must not land last.
    def restore_squadron_ranks(fleet)
      latest = child_destroy_versions("FleetSquadronRole", "fleet_id", fleet.id)
        .order(created_at: :desc, id: :desc)
        .map(&:reify)
        .uniq(&:key)

      latest.each do |rank|
        restored = fleet.fleet_squadron_roles.find_by(key: rank.key)
        next if restored.nil?

        restored.update!(name: rank.name)
        restored.make_default! if rank.default_rank
      end
    end

    def restore_role(fleet, role, slug)
      restored = fleet.fleet_roles.find_by(slug:) ||
        fleet.fleet_roles.create!(name: role.name, resource_access: role.resource_access, permanent: role.permanent)

      restored.update!(name: role.name) if restored.name != role.name
      restored.make_default! if role.try(:new_member_default)
      restored
    end

    # Role assignment is best effort: FleetRole nullifies its memberships when
    # it is destroyed (roles cascade before memberships), so the destroy
    # snapshot's fleet_role_id is usually already nil and the old role cannot be
    # mapped. The fleet owner is the exception: setup_admin_user (run on fleet
    # save) already recreated their membership with the admin role, so we must
    # keep any role the record already carries rather than downgrading it.
    # Everyone else falls back to the default member role.
    def restore_memberships(fleet, role_map)
      child_destroy_versions("FleetMembership", "fleet_id", fleet.id).find_each do |version|
        membership = version.reify
        record = fleet.fleet_memberships.find_or_initialize_by(user_id: membership.user_id)
        record.assign_attributes(membership.attributes.slice(*MEMBERSHIP_COLUMNS))
        record.fleet_role = role_map[membership.fleet_role_id] || record.fleet_role || fleet.default_member_role
        record.discarded_at = membership.discarded_at
        record.save!(validate: false)
      end
    end

    def restore_inventories(fleet)
      map = {}

      child_destroy_versions("FleetInventory", "fleet_id", fleet.id).find_each do |version|
        inventory = version.reify
        restored = fleet.fleet_inventories.find_or_create_by!(name: inventory.name) do |new_inventory|
          new_inventory.assign_attributes(inventory.attributes.slice(*INVENTORY_COLUMNS))
        end
        map[version.item_id] = restored
      end

      map
    end

    def restore_inventory_items(inventory_map)
      return if inventory_map.empty?

      PaperTrail::Version
        .where(item_type: "FleetInventoryItem", event: "destroy")
        .where("object ->> 'fleet_inventory_id' IN (?)", inventory_map.keys)
        .find_each do |version|
          item = version.reify
          inventory = inventory_map[item.fleet_inventory_id]
          next if inventory.nil?

          record = inventory.fleet_inventory_items.new
          record.assign_attributes(item.attributes.slice(*INVENTORY_ITEM_COLUMNS))
          record.save!(validate: false)
        end
    end
  end
end
