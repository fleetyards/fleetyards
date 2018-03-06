# frozen_string_literal: true

Types::ModelType = GraphQL::ObjectType.define do
  name 'Model'

  field :name, types.String
  field :slug, types.String
  field :description, types.String
  field :length, types.Float, property: :display_length
  field :beam, types.Float, property: :display_beam
  field :height, types.Float, property: :display_height
  field :mass, types.Float, property: :display_mass
  field :cargo, types.Int, property: :display_cargo
  field :minCrew, types.Int, property: :display_min_crew
  field :maxCrew, types.Int, property: :display_max_crew
  field :scmSpeed, types.Float, property: :display_scm_speed
  field :afterburnerSpeed, types.Float, property: :display_afterburner_speed
  field :pitchMax, types.Float, property: :pitch_max
  field :yawMax, types.Float, property: :yaw_max
  field :rollMax, types.Float, property: :roll_max
  field :xaxisAcceleration, types.Float, property: :xaxis_acceleration
  field :yaxisAcceleration, types.Float, property: :yaxis_acceleration
  field :zaxisAcceleration, types.Float, property: :zaxis_acceleration
  field :size, types.String
  field :storeImage, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.store_image.url
    end
  end
  field :fleetchartImage, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.fleetchart_image.url
    end
  end
  field :storeURL, types.String do
    resolve ->(obj, _args, _ctx) do
      "#{Rails.application.secrets[:rsi_hostname]}#{obj.store_url}"
    end
  end
  field :price, types.Float
  field :lastPrice, types.Float, property: :fallback_price
  field :onSale, types.Boolean, property: :on_sale
  field :productionStatus, types.String, property: :production_status
  field :productionNote, types.String, property: :production_note
  field :classification, types.String
  field :focus, types.String
  field :rsiID, types.Int, property: :rsi_id
  field :manufacturer, Types::ManufacturerType do
    resolve ->(obj, _args, _ctx) { RecordLoader.for(Manufacturer).load(obj.manufacturer_id) }
  end
  field :hardpoints, types[Types::HardpointType] do
    resolve ->(obj, _args, _ctx) { RecordLoader.for(Hardpoint).load_many(obj.hardpoint_ids) }
  end
  field :images, types[Types::ImageType] do
    resolve ->(obj, _args, _ctx) { RecordLoader.for(Image).load_many(obj.image_ids) }
  end
  field :videos, types[Types::VideoType] do
    resolve ->(obj, _args, _ctx) { RecordLoader.for(Video).load_many(obj.video_ids) }
  end
  field :createdAt, types.String, property: :created_at
  field :updatedAt, types.String, property: :updated_at
end
