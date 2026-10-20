# frozen_string_literal: true

module HangarPlans
  # What rendering a ship in a plan payload reads: its manufacturer, the build
  # its facts come from and its picture.
  MODEL_PRELOAD = [
    :manufacturer, :build, :last_build,
    *Model::IMAGE_ATTACHMENT_NAMES.map { |name| {"#{name}_attachment": :blob} }
  ].freeze
end
