# encoding: utf-8
# frozen_string_literal: true

json.created_at record.created_at.to_time.iso8601
json.updated_at record.updated_at.to_time.iso8601
