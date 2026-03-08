# frozen_string_literal: true

json.array! @features, partial: "admin/api/v1/features/feature", as: :feature
