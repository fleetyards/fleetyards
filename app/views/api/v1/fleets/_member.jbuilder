# frozen_string_literal: true

json.handle member.handle
json.name member.name
json.avatar member.avatar
json.rank member.rank
json.partial! 'api/shared/dates', record: member
