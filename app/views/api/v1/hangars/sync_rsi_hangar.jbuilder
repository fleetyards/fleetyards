# frozen_string_literal: true

json.updated @response[:updated_vehicles]
json.imported @response[:new_vehicles]
json.moved_to_wanted @response[:missing_vehicles]
json.missing @response[:missing_models]
json.new_components @response[:new_components]
json.found_components @response[:found_components]
json.missing_components @response[:missing_components]
json.missing_component_vehicles @response[:missing_component_vehicles]
