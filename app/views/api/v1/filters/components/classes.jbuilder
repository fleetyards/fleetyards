# frozen_string_literal: true

json.array! @class_filters, partial: "api/shared/filter", as: :filter
