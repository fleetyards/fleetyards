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
module Imports
  class HangarImport < ::Import
    belongs_to :user

    mount_uploader :import, HangarImportUploader

    validates :import, presence: true

    after_create :set_import_data

    serialize :import_data

    def set_import_data
      data = JSON.parse(import.read)

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
  end
end
