# frozen_string_literal: true

json.array! @groups, partial: "api/v2/hangar/public/groups/minimal", as: :group
