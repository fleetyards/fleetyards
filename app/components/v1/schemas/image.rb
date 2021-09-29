# frozen_string_literal: true

module V1
  module Schemas
    class Image < ::BaseSchema
      data_type :object

      property :id, {type: :string, format: :uuid}
      property :name, {type: :string}
      property :caption, {type: :string}
      property :url, {type: :string}
      property :width, {type: :string}
      property :type, {type: :string}
      property :background, {type: :boolean}
      property :smallUrl, {type: :string}
      property :bigUrl, {type: :string}

      property :gallery, {"$ref" => "#/components/schemas/Gallery", :nullable => true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[id name url width height type background smallUrl bigUrl createdAt updatedAt]
    end
  end
end
