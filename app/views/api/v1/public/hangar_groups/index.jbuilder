# frozen_string_literal: true

json.array! @groups, partial: "api/v1/public/hangar_groups/hangar_group", as: :group
