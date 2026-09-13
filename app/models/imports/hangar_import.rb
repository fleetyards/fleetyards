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
  class HangarImport < ::Import
    belongs_to :user

    has_one_attached :import

    validate :import_file_presence
    # An import is a JSON file, but it is a user upload whose blob URL the
    # admin UI links to, so it is held to the same rule as the pictures.
    validates :import, no_vector_image: true

    def import_file_presence
      return if import.attached?

      errors.add(:import, I18n.t("errors.messages.blank"))
    end

    after_create :set_import_data

    serialize :import_data, coder: YAML

    def set_import_data
      data = read_import_file

      self.import_data = (data || []).map do |item|
        return item unless item.is_a? Hash

        item.transform_keys(&:underscore)
          .transform_keys(&:to_sym)
      end.filter do |item|
        item[:type].blank? || item[:type] == "ship"
      end
    rescue JSON::ParserError
      nil
    end

    # Both lists are already model names -- this type never records ids.
    def result_details
      {
        imported: Array(output&.dig("imported")),
        missing: Array(output&.dig("missing"))
      }.reject { |_key, names| names.empty? }
    end

    def notify_admin
      # don't notify on hangar imports
    end

    private

    def read_import_file
      change = attachment_changes["import"]
      if change.present?
        attachable = change.attachable
        case attachable
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          JSON.parse(attachable.read.tap { attachable.rewind })
        when String
          blob = ActiveStorage::Blob.find_signed!(attachable)
          JSON.parse(blob.download)
        end
      elsif import.attached?
        JSON.parse(import.download)
      end
    end
  end
end
