# frozen_string_literal: true

json.partial! "admin/api/v1/blueprints/base", blueprint: @blueprint
json.partial! "api/v1/blueprints/recipe", blueprint: @blueprint
