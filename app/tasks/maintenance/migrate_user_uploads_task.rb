# frozen_string_literal: true

module Maintenance
  class MigrateUserUploadsTask < MaintenanceTasks::Task
    include CarrierwaveToActiveStorageMigration

    MODEL = User
    FIELD_MAPPINGS = {
      avatar: :new_avatar
    }.freeze
  end
end
