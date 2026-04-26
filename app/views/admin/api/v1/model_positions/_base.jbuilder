# frozen_string_literal: true

json.id model_position.id
json.name model_position.name
json.position_type model_position.position_type
json.source model_position.source
json.position model_position.position
json.hardpoint_id model_position.hardpoint_id
json.model_id model_position.model_id

json.partial! "api/shared/dates", record: model_position
