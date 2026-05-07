# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ChannelsEnum
          include OpenapiRuby::Components::Base

          def self.channels
            [Rails.root.join("app/channels")].flat_map do |base_path|
              Dir.glob(base_path.join("**/*_channel.rb")).filter_map do |file_path|
                next if ::File.directory?(file_path)

                file_path.gsub(base_path.to_s, "") # remove base_path
                  .gsub(".rb", "") # remove extension
                  .camelize.constantize
              end
            end
          end

          schema({
            type: :string,
            enum: channels.map(&:to_s),
            "x-enumNames": channels.map { |channel| transform_enum_key(channel) }
          })
        end
      end
    end
  end
end
