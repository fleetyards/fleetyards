# frozen_string_literal: true

json.partial! "api/v1/blueprints/base", blueprint: @blueprint
json.partial! "api/v1/blueprints/recipe", blueprint: @blueprint

# The detail response is not cached, so this needs no special placement -- but
# it is the same fact `_blueprint` renders, off the same set.
json.owned @owned_blueprint_ids.include?(@blueprint.id)
