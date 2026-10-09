# frozen_string_literal: true

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

    # `before_create`, not `after_create`: an assignment made after the INSERT is
    # never written. It went unnoticed while the run happened inline in the
    # request, because the controller held the same instance and the importer's
    # own `start!` flushed the dirty attribute along with the state. The run
    # moved into `HangarImportJob`, which loads the row fresh -- and read back a
    # column that had always been NULL.
    before_create :set_import_data

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
          parse_import(attachable.read.tap { attachable.rewind })
        when String
          blob = ActiveStorage::Blob.find_signed!(attachable)
          parse_import(blob.download)
        end
      elsif import.attached?
        parse_import(import.download)
      end
    end

    # Exports from third-party tools can repeat a key; json 3 rejects that by
    # default, where json 2 kept the last value.
    def parse_import(json)
      JSON.parse(json, allow_duplicate_key: true)
    end
  end
end
