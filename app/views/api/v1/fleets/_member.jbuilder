# frozen_string_literal: true

json.username member.user.username
json.admin member.admin
json.approved member.approved
json.verified member.user.rsi_verified?
json.partial! 'api/shared/dates', record: member
