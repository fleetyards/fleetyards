# frozen_string_literal: true

# [...document.querySelectorAll('picture.c-slide__media img')].map(item => item.getAttribute('src')).forEach((item) => window.open(item, '_blank'))
# loader = ::Rsi::ModelsLoader.new(vat_percent: Rails.application.secrets[:rsi_vat_percent]); ENV['RSI_LOAD_FROM_FILE'] = 'true'; loader.all

require 'rsi/base_loader'

module Rsi
  class ModelsLoader < ::Rsi::BaseLoader
    attr_accessor :json_file_path, :vat_percent

    def initialize(options = {})
      super

      @json_file_path = 'public/models.json'
      @vat_percent = options[:vat_percent] || 19
    end

    def all
      models = load_models

      models.each do |data|
        next if blocked(data['id'])

        sync_model(data)
      end

      cleanup_variants
    end

    def one(rsi_id)
      models = load_models

      model_data = models.find { |model| model['id'] == rsi_id.to_s }

      return if model_data.blank?

      sync_model(model_data) unless blocked(rsi_id)

      cleanup_variants
    end

    def load_models
      return JSON.parse(File.read(json_file_path))['data'] if (Rails.env.test? || ENV['CI'] || ENV['RSI_LOAD_FROM_FILE']) && File.exist?(json_file_path)

      response = fetch_remote("#{base_url}/ship-matrix/index?#{Time.zone.now.to_i}")

      return [] unless response.success?

      begin
        model_data = JSON.parse(response.body)
        File.open(json_file_path, 'w') do |f|
          f.write(model_data.to_json)
        end
        model_data['data']
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Model Data could not be parsed: #{response.body}"
        []
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def sync_model(data)
      model_for_paint = find_model_for_paint(data)
      model = if model_for_paint.present?
                create_or_update_paint(data, model_for_paint.id)
              else
                create_or_update_model(data)
              end

      buying_options = get_buying_options(model.store_url) unless Rails.env.test?
      if buying_options.present?
        model.pledge_price = buying_options.price if buying_options.price.present?
        model.on_sale = buying_options.on_sale
      end

      model.manufacturer = create_or_update_manufacturer(data['manufacturer']) unless paint?(data)

      if !paint?(data) && (model.data_slug.blank? || model.hardpoints.blank?)
        model.hardpoints.where(rsi_key: nil).destroy_all

        hardpoint_ids = []
        components = data['compiled']
        components.each_key do |component_class|
          types = components[component_class]
          types.each_key do |type|
            types[type].each_with_index do |hardpoint_data, index|
              hardpoint = create_or_update_hardpoint(hardpoint_data, model.id, index)
              hardpoint_ids << hardpoint.id
            end
          end
        end

        model.hardpoints.where.not(id: hardpoint_ids).update(deleted_at: Time.zone.now)
      end

      model.hidden = false

      model.save!
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def get_buying_options(store_url)
      return if Rails.env.test? || ENV['CI'] || ENV['RSI_LOAD_FROM_FILE']

      sleep 5

      response = fetch_remote("#{base_url}#{store_url}?#{Time.zone.now.to_i}")

      return unless response.success?

      page = Nokogiri::HTML(response.body)

      prices = []
      (page.css('#buying-options .final-price') || []).each do |price_element|
        prices << extract_price(price_element)
      end

      prices.compact.sort!

      OpenStruct.new(
        price: prices.first,
        on_sale: prices.present?,
        prices: prices
      )
    end

    private def extract_price(element)
      raw_price = element.text
      price_match = raw_price.match(/^\$(\d+.\d+) USD$/)
      price_with_local_vat = price_match[1].to_d if price_match.present?
      price_with_local_vat * 100 / (100 + vat_percent) if price_with_local_vat.present?
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    private def create_or_update_model(data)
      model = Model.find_or_create_by!(rsi_id: data['id'])

      updates = {
        rsi_chassis_id: data['chassis_id'],
        last_updated_at: new_time_modified(data)
      }

      if model_updated(model, data) || model.production_status.blank?
        updates[:production_status] = data['production_status']
        updates[:production_note] = data['production_note']
      end

      %w[length beam height mass].each do |attr|
        updates["rsi_#{attr}"] = data[attr].to_d
        updates[attr.to_sym] = data[attr].to_d if (model_updated(model, data) && data[attr].to_d != model.send("rsi_#{attr}").to_d) || model.send(attr).blank? || model.send(attr).zero?
      end

      updates[:rsi_description] = data['description']
      updates[:description] = data['description'] if (model_updated(model, data) && data['description'] != model.rsi_description) || model.description.blank?

      updates[:rsi_cargo] = nil_or_decimal(data['cargocapacity'])
      updates[:cargo] = nil_or_decimal(data['cargocapacity']) if (model_updated(model, data) && nil_or_decimal(data['cargocapacity']) != model.rsi_cargo) || model.cargo.blank? || model.cargo.zero?

      %w[max_crew min_crew scm_speed afterburner_speed pitch_max yaw_max roll_max xaxis_acceleration yaxis_acceleration zaxis_acceleration].each do |attr|
        updates["rsi_#{attr}"] = nil_or_decimal(data[attr])
        updates[attr.to_sym] = nil_or_decimal(data[attr]) if (model_updated(model, data) && nil_or_decimal(data[attr]) != model.send("rsi_#{attr}")) || model.send(attr).blank? || model.send(attr).zero?
      end

      updates[:ground] = true if data['type'] == 'ground' && model_updated(model, data) && data['type'] != model.classification

      %w[size focus].each do |attr|
        updates["rsi_#{attr}"] = data[attr]
        updates[attr] = data[attr] if (model_updated(model, data) && data[attr] != model.send("rsi_#{attr}")) || model.send("rsi_#{attr}").blank?
      end

      updates[:rsi_classification] = data['type']
      updates[:classification] = data['type'] if (model_updated(model, data) && data['type'] != model.rsi_classification) || model.classification.blank?

      updates[:rsi_store_url] = data['url']
      updates[:store_url] = data['url'] if (model_updated(model, data) && data['url'] != model.rsi_store_url) || model.store_url.blank?

      updates[:rsi_name] = data['name'].strip
      updates[:name] = strip_name(data['name']) if (model_updated(model, data) && data['name'] != model.rsi_name) || model.name.blank?

      model.update(updates)
      store_images_updated_at = begin
        Time.zone.parse(data['media'][0]['time_modified'])
      rescue StandardError
        nil
      end

      if !Rails.env.test? && (model.rsi_store_image.blank? || model.store_images_updated_at != store_images_updated_at)
        model.store_images_updated_at = data['media'][0]['time_modified']
        store_image_url = data['media'][0]['images']['store_hub_large']
        store_image_url = "#{base_url}#{store_image_url}" unless store_image_url.starts_with?('https')
        if store_image_url.present? && !Rails.env.test? && !ENV['CI'] && !ENV['RSI_LOAD_FROM_FILE']
          image_url = store_image_url.gsub('store_hub_large', 'source')
          model.remote_rsi_store_image_url = image_url
          model.remote_store_image_url = image_url if model.store_image.blank?
          model.save
        end
      end

      model
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/CyclomaticComplexity
    private def create_or_update_paint(data, model_id)
      paint = ModelPaint.find_or_create_by!(rsi_id: data['id'])

      updates = {
        last_updated_at: new_time_modified(data),
        model_id: model_id,
      }

      updates[:rsi_description] = data['description']
      updates[:description] = data['description'] if (model_updated(paint, data) && data['description'] != paint.rsi_description) || paint.description.blank?

      updates[:rsi_store_url] = data['url']
      updates[:store_url] = data['url'] if (model_updated(paint, data) && data['url'] != paint.rsi_store_url) || paint.store_url.blank?

      if model_updated(paint, data) || paint.production_status.blank?
        updates[:production_status] = data['production_status']
        updates[:production_note] = data['production_note']
      end

      updates[:rsi_name] = data['name'].strip
      updates[:name] = strip_name(data['name']) if (model_updated(paint, data) && data['name'] != paint.rsi_name) || paint.name.blank?

      paint.update(updates)
      store_images_updated_at = begin
        Time.zone.parse(data['media'][0]['time_modified'])
      rescue StandardError
        nil
      end

      if !Rails.env.test? && (paint.rsi_store_image.blank? || paint.store_images_updated_at != store_images_updated_at)
        paint.store_images_updated_at = data['media'][0]['time_modified']
        store_image_url = data['media'][0]['images']['store_hub_large']
        store_image_url = "#{base_url}#{store_image_url}" unless store_image_url.starts_with?('https')
        if store_image_url.present? && !Rails.env.test? && !ENV['CI'] && !ENV['RSI_LOAD_FROM_FILE']
          image_url = store_image_url.gsub('store_hub_large', 'source')
          paint.remote_rsi_store_image_url = image_url
          paint.remote_store_image_url = image_url if paint.store_image.blank?
          paint.save
        end
      end

      paint
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def create_or_update_manufacturer(manufacturer_data)
      manufacturer = Manufacturer.find_or_create_by!(rsi_id: manufacturer_data['id'])

      manufacturer.update(
        name: manufacturer_data['name'],
        code: manufacturer_data['code'].presence,
        known_for: manufacturer_data['known_for'].presence,
        description: manufacturer_data['description'].presence,
        remote_logo_url: ("#{base_url}#{manufacturer_data['media'][0]['source_url']}" if !Rails.env.test? && manufacturer.logo.blank? && manufacturer_data['media'].present?)
      )

      manufacturer
    end

    def create_or_update_hardpoint(hardpoint_data, model_id, index)
      key = [
        model_id,
        hardpoint_data['component_class'],
        hardpoint_data['type'],
        hardpoint_data['category'],
        hardpoint_data['size'],
        hardpoint_data['quantity'].to_i,
        hardpoint_data['mounts'].to_i,
        index
      ].join('-')

      hardpoint = Hardpoint.find_or_create_by(rsi_key: key) do |new_hardpoint|
        new_hardpoint.model_id = model_id
        new_hardpoint.hardpoint_type = hardpoint_data['type']
        new_hardpoint.size = hardpoint_data['size']
        new_hardpoint.quantity = hardpoint_data['quantity'].to_i
        new_hardpoint.mounts = hardpoint_data['mounts'].to_i
        new_hardpoint.category = hardpoint_data['category']
      end

      hardpoint.update(
        details: hardpoint_data['details'],
        component_class: hardpoint_data['component_class'],
        default_empty: hardpoint_data['name'].blank?,
        deleted_at: nil
      )

      if hardpoint_data['name'].present? && hardpoint_data['manufacturer'].present? && hardpoint_data['manufacturer'] != 'TBD'
        hardpoint.component = create_or_update_component(hardpoint_data)
        hardpoint.save
      end

      hardpoint
    end

    def create_or_update_component(hardpoint_data)
      component = Component.find_or_create_by!(
        name: hardpoint_data['name'],
        size: hardpoint_data['component_size']
      )

      item_type = hardpoint_data['type']
      item_type = 'weapons' if item_type == 'turrets'

      component.update(
        component_class: hardpoint_data['component_class'],
        item_type: item_type
      )

      if hardpoint_data['manufacturer'].present? && hardpoint_data['manufacturer'] != 'TBD'
        component.manufacturer = Manufacturer.find_or_create_by!(name: hardpoint_data['manufacturer'].strip)
        component.save
      end

      component
    end

    private def new_time_modified(data)
      Time.zone.parse(data['time_modified.unfiltered'])
    rescue ArgumentError
      nil
    end

    private def paint?(data)
      paint_mapping.any? { |item| item[:rsi_id] == data['id'].to_i }
    end

    # rubocop:disable Metrics/MethodLength
    private def paint_mapping
      [
        {
          # Carrack
          rsi_id: 206,
          model_rsi_id: 62,
        }, {
          # Ballista
          rsi_id: 185,
          model_rsi_id: 183,
        }, {
          rsi_id: 184,
          model_rsi_id: 183,
        }, {
          # Caterpillar
          rsi_id: 194,
          model_rsi_id: 24,
        }, {
          rsi_id: 125,
          model_rsi_id: 24,
        }, {
          # Phoenix
          rsi_id: 156,
          model_rsi_id: 49,
        }, {
          # Cutlass
          rsi_id: 193,
          model_rsi_id: 56,
        }, {
          # Hammerhead
          rsi_id: 195,
          model_rsi_id: 151,
        }, {
          # Reclaimer
          rsi_id: 196,
          model_rsi_id: 51,
        }, {
          # Mole
          rsi_id: 202,
          model_rsi_id: 201,
        }, {
          rsi_id: 203,
          model_rsi_id: 201,
        }, {
          # Mustang
          rsi_id: 172,
          model_rsi_id: 65,
        }, {
          # Nautilus
          rsi_id: 187,
          model_rsi_id: 186,
        }, {
          # Archimedes
          rsi_id: 207,
          model_rsi_id: 104,
        }, {
          # Valkyrie
          rsi_id: 171,
          model_rsi_id: 169,
        },
      ]
    end
    # rubocop:enable Metrics/MethodLength

    private def blocklist
      [{
        rsi_id: 205,
        replacements: [{
          rsi_id: 62,
          paint_rsi_id: 205,
        }, {
          rsi_id: 192,
        }],
      }, {
        rsi_id: 204,
        replacements: [{
          rsi_id: 62,
        }, {
          rsi_id: 192,
        }],
      }]
    end

    private def blocked(rsi_id)
      blocklist.find { |item| item[:rsi_id] == rsi_id.to_i }
    end

    private def find_model_for_paint(data)
      mapping = paint_mapping.find { |item| item[:rsi_id] == data['id'].to_i }

      return if mapping.blank?

      model_rsi_id = mapping[:model_rsi_id]

      return if model_rsi_id.blank?

      Model.find_by(rsi_id: model_rsi_id)
    end

    private def model_updated(model, data)
      model.last_updated_at.blank? || model.last_updated_at < new_time_modified(data)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def cleanup_variants
      ModelPaint.where.not(rsi_id: nil).find_each do |paint|
        model = Model.find_by(rsi_id: paint.rsi_id)
        next if model.blank?

        Vehicle.where(model_id: model.id).find_each do |vehicle|
          vehicle.update(model_id: paint.model_id, model_paint_id: paint.id)
        end

        model.destroy
      end

      blocklist.each do |item|
        model = Model.find_by(rsi_id: item[:rsi_id])
        next if model.blank?

        replacements = item[:replacements].map { |replacement| replacement.merge(model: Model.find_by!(rsi_id: replacement[:rsi_id])) }

        Vehicle.where(model_id: model.id, loaner: false).find_each do |vehicle|
          next if replacements.first[:model].blank?

          vehicle.update(model_id: replacements.first[:model].id)
          replacements.each_with_index do |replacement, index|
            next if index.zero?

            replacement_model = replacement[:model]
            next if replacement_model.blank?

            paint = ModelPaint.find_by!(rsi_id: replacement[:paint_rsi_id]) if replacement[:paint_rsi_id].present?

            Vehicle.create(model_id: replacement_model.id, user_id: vehicle.user_id, model_paint_id: paint&.id)
          end
        end

        model.destroy
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
