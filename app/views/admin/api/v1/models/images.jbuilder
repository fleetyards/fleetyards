# frozen_string_literal: true

json.array! @images, partial: "admin/api/v1/images/image", as: :image
