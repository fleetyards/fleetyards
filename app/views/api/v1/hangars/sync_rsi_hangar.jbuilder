# frozen_string_literal: true

json.updated @response[:updated_vehicles]
json.imported @response[:new_vehicles]
json.moved_to_wanted @response[:missing_vehicles]
json.missing @response[:missing_models]
