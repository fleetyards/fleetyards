# frozen_string_literal: true

class HangarImportJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(import_id)
    import = Imports::HangarImport.find_by(id: import_id)

    # Cancelled or cleaned up between enqueue and pickup. `HangarImporter#run`
    # refuses a cancelled import as well; this keeps the job from loading the
    # file for one.
    return if import.blank? || !import.created?

    ::HangarImporter.new(import).run
  end
end
