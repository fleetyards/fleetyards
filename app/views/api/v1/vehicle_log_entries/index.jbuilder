# frozen_string_literal: true

json.array! @log_entries, partial: "api/v1/vehicle_log_entries/base", as: :log_entry
