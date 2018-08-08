# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :models, !types[Types::ModelType] do
    description 'List of Models (Ships, Vehicles etc)'
    argument :q, Types::Input::ModelsSearchType
    argument :limit, types.Int, prepare: ->(limit, _ctx) { [limit, 5000].min }
    argument :offset, types.Int
    resolve Resolvers::ModelsResolver.new
  end

  field :model, !Types::ModelType do
    description 'Model (Ship, Vehicle etc) indentified by slug'
    argument :slug, !types.String
    resolve Resolvers::ModelResolver.new
  end

  field :manufacturers, !types[Types::ManufacturerType] do
    description 'List of Manufacturers'
    argument :q, Types::Input::ManufacturersSearchType
    argument :limit, types.Int, prepare: ->(limit, _ctx) { [limit, 5000].min }
    argument :offset, types.Int
    argument :withModel, types.Boolean, as: :with_model
    resolve Resolvers::ManufacturersResolver.new
  end

  field :productionStatusFilters, !types[Types::FilterType] do
    description 'Production States for Models'
    resolve ->(_obj, _args, _ctx) do
      Model.production_status_filters.sort_by(&:name)
    end
  end

  field :classificationsFilters, !types[Types::FilterType] do
    description 'Classifications for Models'
    resolve ->(_obj, _args, _ctx) do
      Model.classification_filters.sort_by(&:name)
    end
  end

  field :focusFilters, !types[Types::FilterType] do
    description 'Classifications for Models'
    resolve ->(_obj, _args, _ctx) do
      Model.focus_filters.sort_by(&:name)
    end
  end

  field :sizeFilters, !types[Types::FilterType] do
    description 'Classifications for Models'
    resolve ->(_obj, _args, _ctx) do
      Model.size_filters.sort_by(&:name)
    end
  end

  field :images, !types[Types::ImageType] do
    description 'List of Models (Ships, Vehicles etc)'
    argument :limit, types.Int, prepare: ->(limit, _ctx) { [limit, 5000].min }
    argument :offset, types.Int
    argument :random, types.Boolean
    resolve ->(_obj, args, _ctx) do
      scope = Image.enabled

      scope = if args[:random]
                scope.order('RANDOM()')
              else
                scope.order('images.created_at desc')
              end

      scope.offset(args[:offset]).limit(args[:limit])
    end
  end
end
