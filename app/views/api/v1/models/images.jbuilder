# frozen_string_literal: true

json.array! @images, partial: "api/v1/images/minimal", as: :image
