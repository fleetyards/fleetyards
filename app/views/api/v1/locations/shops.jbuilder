# frozen_string_literal: true

json.shops @shops do |summary|
  json.id summary.shop.id
  json.name summary.shop.name
  json.slug summary.shop.slug
  json.items_count summary.items_count
  json.counts summary.counts

  if summary.shop.image.attached?
    json.image do
      json.partial! "api/v1/shared/file", record: summary.shop, attr: :image
    end
  end
end
