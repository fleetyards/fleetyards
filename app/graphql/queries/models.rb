# encoding: utf-8
# frozen_string_literal: true

module Queries
  Models = GraphQL::ObjectType.define do
    field :models do
      type types[!Types::ModelType]
      description 'All Models'
      argument :q, InputTypes::ModelSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Models.new
    end

    field :model do
      type Types::ModelType
      description 'Find a Model by Slug'
      argument :slug, !types.String
      resolve Resolvers::Models.new
    end

    field :classifications do
      type types[!Types::OptionType]
      description 'All Classifications'
      resolve(lambda do |_obj, _args, _ctx|
        Ship.all.map(&:classification).uniq.compact.map do |item|
          {
            name: I18n.t("filter.ship.classification.items.#{item}"),
            value: item
          }
        end
      end)
    end

    field :productionStates do
      type types[!Types::OptionType]
      description 'All Production States'
      resolve(lambda do |_obj, _args, _ctx|
        I18n.t('labels.ship.production_status').map do |status|
          {
            name: status[1],
            value: status[0]
          }
        end
      end)
    end

    field :roles do
      type types[!Types::OptionType]
      description 'All Roles'
      resolve(lambda do |_obj, _args, _ctx|
        ShipRole.with_name.with_ship.order(name: :asc).all.map do |model_role|
          {
            name: model_role.name,
            value: model_role.slug
          }
        end
      end)
    end
  end
end
