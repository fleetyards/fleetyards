# frozen_string_literal: true

# [...document.querySelectorAll('picture.c-slide__media img')].map(item => item.getAttribute('src')).forEach((item) => window.open(item, '_blank'))
# loader = RsiModelsLoader.new(vat_percent: Rails.application.secrets[:rsi_vat_percent]); ENV['RSI_LOAD_FROM_FILE'] = 'true'; loader.all

require 'rsi_base_loader'

class RsiModelsLoader < RsiBaseLoader
  attr_accessor :json_file_path, :vat_percent

  def initialize(options = {})
    super

    @json_file_path = 'public/models.json'
    @vat_percent = options[:vat_percent] || 19
  end

  def all
    models = load_models

    models.each do |data|
      sync_model(data)
    end
  end

  def one(rsi_id)
    models = load_models

    model_data = models.find { |model| model['id'] == rsi_id.to_s }

    sync_model(model_data) if model_data.present?
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

  def sync_model(data)
    model = create_or_update_model(data)

    buying_options = get_buying_options(model.store_url)
    if buying_options.present?
      model.pledge_price = buying_options.price if buying_options.price.present?
      model.on_sale = buying_options.on_sale
    end

    model.manufacturer = create_or_update_manufacturer(data['manufacturer'])

    model.hardpoints.destroy_all

    components = data['compiled']
    components.each_key do |component_class|
      types = components[component_class]
      types.each_key do |type|
        types[type].each do |hardpoint_data|
          create_or_update_hardpoint(hardpoint_data, model.id)
        end
      end
    end

    model.hidden = false

    model.save!
  end

  def get_buying_options(store_url)
    return if Rails.env.test? || ENV['CI'] || ENV['RSI_LOAD_FROM_FILE']

    sleep 5

    response = fetch_remote("#{base_url}#{store_url}?#{Time.zone.now.to_i}")

    return unless response.success?

    page = Nokogiri::HTML(response.body)

    prices = []
    (page.css('#buying-options .final-price') || []).each do |price_element|
      prices << begin
        raw_price = price_element.text
        price_match = raw_price.match(/^\$(\d+.\d+) USD$/)
        price_with_local_vat = price_match[1].to_f if price_match.present?
        price_with_local_vat * 100 / (100 + vat_percent) if price_with_local_vat.present?
      end
    end

    prices.compact.sort!

    OpenStruct.new(
      price: prices.first,
      on_sale: prices.present?,
      prices: prices
    )
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
      updates["rsi_#{attr}"] = data[attr].to_f
      updates[attr.to_sym] = data[attr].to_f if (model_updated(model, data) && data[attr].to_f != model.send("rsi_#{attr}")) || model.send(attr).blank? || model.send(attr).zero?
    end

    updates[:rsi_description] = data['description']
    updates[:description] = data['description'] if (model_updated(model, data) && data['description'] != model.rsi_description) || model.description.blank?

    updates[:rsi_cargo] = nil_or_float(data['cargocapacity'])
    updates[:cargo] = nil_or_float(data['cargocapacity']) if (model_updated(model, data) && nil_or_float(data['cargocapacity']) != model.rsi_cargo) || model.cargo.blank? || model.cargo.zero?

    %w[max_crew min_crew scm_speed afterburner_speed pitch_max yaw_max roll_max xaxis_acceleration yaxis_acceleration zaxis_acceleration].each do |attr|
      updates["rsi_#{attr}"] = nil_or_float(data[attr])
      updates[attr.to_sym] = nil_or_float(data[attr]) if (model_updated(model, data) && nil_or_float(data[attr]) != model.send("rsi_#{attr}")) || model.send(attr).blank? || model.send(attr).zero?
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

    # rubocop:disable Style/RescueModifier
    store_images_updated_at = Time.zone.parse(data['media'][0]['time_modified']) rescue nil
    # rubocop:enable Style/RescueModifier

    if model.store_image.blank? || model.store_images_updated_at != store_images_updated_at
      model.store_images_updated_at = data['media'][0]['time_modified']
      store_image_url = data['media'][0]['images']['store_hub_large']
      store_image_url = "#{base_url}#{store_image_url}" unless store_image_url.starts_with?('https')
      if store_image_url.present? && !Rails.env.test? && !ENV['CI'] && !ENV['RSI_LOAD_FROM_FILE']
        model.remote_store_image_url = store_image_url
        model.save
      end
    end

    model
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  def create_or_update_manufacturer(manufacturer_data)
    manufacturer = Manufacturer.find_or_create_by!(rsi_id: manufacturer_data['id'])

    manufacturer.update(
      name: manufacturer_data['name'],
      code: manufacturer_data['code'].presence,
      known_for: manufacturer_data['known_for'].presence,
      description: manufacturer_data['description'].presence,
      remote_logo_url: ("#{base_url}#{manufacturer_data['media'][0]['source_url']}" if manufacturer.logo.blank? && manufacturer_data['media'].present?)
    )

    manufacturer
  end

  def create_or_update_hardpoint(hardpoint_data, model_id)
    hardpoint = Hardpoint.create!(
      model_id: model_id,
      hardpoint_type: hardpoint_data['type'],
      size: hardpoint_data['size'],
      details: hardpoint_data['details'],
      quantity: hardpoint_data['quantity'].to_i,
      mounts: hardpoint_data['mounts'].to_i,
      category: hardpoint_data['category'],
      component_class: hardpoint_data['component_class'],
      default_empty: hardpoint_data['name'].blank?
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

  private def model_updated(model, data)
    model.last_updated_at.blank? || model.last_updated_at < new_time_modified(data)
  end
end
