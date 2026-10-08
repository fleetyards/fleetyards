module Imports
  module ScData
    class ModelsImport < ::Import
      validates :version, presence: true

      def self.current_version
        finished.order(created_at: :asc).last&.version
      end
    end
  end
end
