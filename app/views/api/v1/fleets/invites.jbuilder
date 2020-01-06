# frozen_string_literal: true

json.array! @invites, partial: 'api/v1/fleets/invite', as: :member
