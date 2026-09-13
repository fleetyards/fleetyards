# frozen_string_literal: true

json.id tour.id
json.title tour.title
json.slug tour.slug
json.description tour.description
json.status tour.status
json.starts_at tour.starts_at&.utc&.iso8601
json.settled_at tour.settled_at&.utc&.iso8601

json.created_by do
  json.id tour.created_by_id
  json.username tour.created_by&.username

  # Omitted rather than rendered empty when there is nothing attached: an
  # avatar with no name, type, size or url does not satisfy MediaFile.
  if tour.created_by&.avatar&.attached?
    json.avatar do
      json.partial! "api/v1/shared/file", record: tour.created_by, attr: :avatar
    end
  end
end

json.partial! "api/shared/dates", record: tour
