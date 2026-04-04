# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id                      :uuid             not null, primary key
#  aasm_state              :string
#  carrierwave_migrated_at :datetime
#  failed_at               :datetime
#  finished_at             :datetime
#  import                  :string
#  import_data             :text
#  info                    :text
#  input                   :jsonb
#  output                  :jsonb
#  started_at              :datetime
#  type                    :string
#  version                 :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_type                 (type)
#
module Imports
  class HangarImport < ::Import
    self.ignored_columns += %w[import]

    belongs_to :user

    has_one_attached :import

    validate :import_file_presence

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
