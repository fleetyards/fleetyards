# encoding: utf-8
# frozen_string_literal: true

json.array! @members, partial: 'api/v1/fleets/member', as: :member
