# frozen_string_literal: true

json.array! @outfits, partial: "api/v1/outfits/outfit", as: :outfit
