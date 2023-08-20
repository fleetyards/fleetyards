# frozen_string_literal: true

json.array! @manufacturers, partial: "api/v1/manufacturers/manufacturer", as: :manufacturer
