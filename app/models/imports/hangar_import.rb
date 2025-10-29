# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id          :uuid             not null, primary key
#  aasm_state  :string
#  failed_at   :datetime
#  finished_at :datetime
#  import      :string
#  import_data :text
#  info        :text
#  input       :jsonb
#  output      :jsonb
#  started_at  :datetime
#  type        :string
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid
#
# Indexes
#
#  index_imports_on_aasm_state           (aasm_state)
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_type                 (type)
#
module Imports
  class HangarImport < ::Import
    belongs_to :user

    mount_uploader :import, HangarImportUploader
    has_one_attached :new_import

    validate :import_file_presence

    def import_file_presence
      return if import.present? || new_import.attached?

      errors.add(:import, I18n.t("errors.messages.blank"))
    end

    after_create :set_import_data

    serialize :import_data, coder: YAML

    def set_import_data
      data = if import.present?
        JSON.parse(import.read)
      elsif new_import.attached?
        JSON.parse(new_import.download)
      end

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

    def notify_admin
      # don't notify on hangar imports
    end
  end
end
