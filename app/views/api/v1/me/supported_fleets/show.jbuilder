# frozen_string_literal: true

json.explicit @user.supported_fleet_explicit?

fleet = @user.effective_supported_fleet

if fleet.present?
  json.fleet do
    json.id fleet.id
    json.name fleet.name
    json.slug fleet.slug

    if fleet.logo.attached?
      json.logo do
        json.partial! "api/v1/shared/file", record: fleet, attr: :logo
      end
    end
  end
end
