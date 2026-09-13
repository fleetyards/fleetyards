# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id                        :uuid             not null, primary key
#  aasm_state                :string
#  add_bundled_vehicles      :boolean          default(TRUE), not null
#  cancel_requested_at       :datetime
#  cancelled_at              :datetime
#  failed_at                 :datetime
#  finished_at               :datetime
#  import_data               :text
#  info                      :text
#  input                     :jsonb
#  output                    :jsonb
#  started_at                :datetime
#  type                      :string
#  unmatched_vehicles_action :string           default("wishlist"), not null
#  version                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  admin_user_id             :uuid
#  hangar_group_id           :uuid
#  unmatched_hangar_group_id :uuid
#  user_id                   :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type        (aasm_state,type)
#  index_imports_on_admin_user_id              (admin_user_id)
#  index_imports_on_hangar_group_id            (hangar_group_id)
#  index_imports_on_type                       (type)
#  index_imports_on_type_and_id                (type,id)
#  index_imports_on_unmatched_hangar_group_id  (unmatched_hangar_group_id)
#  index_imports_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (hangar_group_id => hangar_groups.id) ON DELETE => nullify
#  fk_rails_...  (unmatched_hangar_group_id => hangar_groups.id) ON DELETE => nullify
#
module Imports
  class HangarSync < ::Import
    belongs_to :user

    # The vehicle keys hold ids, so they are resolved to names here. A vehicle
    # deleted since the run simply drops out: there is no longer a ship to name,
    # and inventing a placeholder would be worse than a shorter list.
    def result_details
      {
        imported: vehicle_names(output&.dig("imported_vehicles")),
        found: vehicle_names(output&.dig("found_vehicles")),
        moved_to_wanted: vehicle_names(output&.dig("moved_vehicles_to_wanted")),
        # Already names: the rows they came from are gone, so there is nothing
        # left to resolve an id against.
        deleted: Array(output&.dig("deleted_vehicles")),
        grouped: vehicle_names(output&.dig("grouped_vehicles")),
        unchanged: vehicle_names(output&.dig("unchanged_vehicles")),
        missing: Array(output&.dig("missing_models")),
        missing_components: Array(output&.dig("missing_components")),
        missing_upgrades: Array(output&.dig("missing_upgrades"))
      }.reject { |_key, names| names.empty? }
    end

    private def vehicle_names(ids)
      return [] if ids.blank?

      Vehicle.where(id: ids).includes(:model).map do |vehicle|
        vehicle.name.presence || vehicle.model&.name
      end.compact.sort
    end

    def notify_admin
      # don't notify on hangar sync
    end
  end
end
