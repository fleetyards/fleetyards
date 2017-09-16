# encoding: utf-8
# frozen_string_literal: true

json.array! @orgs, partial: 'api/v1/rsi/orgs/base', as: :org
