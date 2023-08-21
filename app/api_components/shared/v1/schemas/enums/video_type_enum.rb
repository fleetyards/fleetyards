# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class VideoTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Video.video_types.keys
          })
        end
      end
    end
  end
end
