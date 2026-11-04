# frozen_string_literal: true

module HangarPlans
  # What rendering a ship in a plan payload reads: its manufacturer, the build
  # its facts come from and its picture.
  MODEL_PRELOAD = [
    {manufacturer: {icon_attachment: :blob}}, :build, :last_build,
    *Model::IMAGE_ATTACHMENT_PRELOAD
  ].freeze
end
