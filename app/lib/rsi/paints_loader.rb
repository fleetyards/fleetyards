# frozen_string_literal: true

module Rsi
  class PaintsLoader
    def import(paints_data)
      paints = normalize(paints_data)

      return if paints.blank?

      paints.each do |paint_item|
        paint_item[:model_ids].each do |model_id|
          model_paint = ModelPaint.find_or_create_by!(name: paint_item[:name], model_id: model_id) do |new_paint|
            new_paint.remote_store_image_url = paint_item[:remote_store_image_url]
            new_paint.store_url = paint_item[:store_url]
          end

          model_paint.update!(
            hidden: false,
            active: true
          )
        end
      end
    end

    private def normalize(paints_data)
      paints_data.filter_map do |raw_paint|
        next if raw_paint['name'].include?('Pack')

        paint_name_parts = raw_paint['name'].split('-')

        media_url = normalize_image(raw_paint['image'])

        {
          name: normalize_name(paint_name_parts.last),
          model_ids: find_models_from_name(paint_name_parts.first),
          model_name: paint_name_parts.first.strip,
          remote_store_image_url: media_url,
          store_url: raw_paint['store_url']
        }
      end
    end

    private def normalize_image(media_url)
      media_url.gsub('sku_widget_thumbnail', 'source')
    end

    private def normalize_name(name)
      name.gsub('Paint', '').strip
    end

    private def find_models_from_name(ship_name)
      model = Model.where('name ILIKE ?', model_mapping(ship_name.strip)).first

      [model.id] + model.variants.pluck(:id)
    end

    private def model_mapping(name)
      mapping = {
        Constellation: 'Constellation Andromeda',
        Retaliator: 'Retaliator Base',
        Reliant: 'Reliant Kore',
        Aurora: 'Aurora MR',
        Avenger: 'Avenger Titan',
        Vanguard: 'Vanguard Warden',
        'Nova Tank': 'Nova',
        '100 Series': '100i',
        'Hercules Starlifter': 'C2 Hercules'
      }

      return mapping[name.to_sym] if mapping[name.to_sym].present?

      name
    end
  end
end
