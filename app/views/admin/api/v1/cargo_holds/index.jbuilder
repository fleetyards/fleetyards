# frozen_string_literal: true

json.items do
  json.array! @cargo_holds, partial: "admin/api/v1/cargo_holds/cargo_hold", as: :cargo_hold
end

json.partial! "api/shared/meta", result: @cargo_holds
