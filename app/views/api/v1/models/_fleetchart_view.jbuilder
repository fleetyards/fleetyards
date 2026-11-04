# frozen_string_literal: true

# The ship views a fleetchart draws with, keyed by slug so a caller can match them
# against a list it already holds.

json.slug model.slug

json.media do
  Model::FLEETCHART_VIEW_ATTACHMENT_NAMES.each do |view|
    json.set! view do
      json.partial! "api/v1/shared/file", record: model, attr: view
    end
  end

  json.angled_extents do
    {flight: "", extended: "extended_", landed: "landed_"}.each do |state, prefix|
      top_view = [model.public_send("#{prefix}top_view"), model.public_send("#{prefix}top_view_colored")].find(&:attached?)
      next unless top_view&.metadata&.key?(:angled_extent)

      json.set! state do
        json.angled top_view.metadata[:angled_extent]
        json.angled_rear top_view.metadata[:angled_rear_extent]
      end
    end
  end
end
