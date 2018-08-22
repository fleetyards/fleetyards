# frozen_string_literal: true

class RsiModelsLoader
  attr_accessor :json_file_path, :base_url, :vat_percent

  def initialize(options = {})
    @json_file_path = 'public/models.json'
    @base_url = options[:base_url] || 'https://robertsspaceindustries.com'
    @vat_percent = options[:vat_percent] || 23
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
    if Rails.env.test? && File.exist?(json_file_path)
      return JSON.parse(File.read(json_file_path))['data']
    end

    response = Typhoeus.get("#{base_url}/ship-matrix/index")

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
      model.price = buying_options.price if buying_options.price.present?
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
    response = Typhoeus.get("#{base_url}#{store_url}")

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

  private def create_or_update_model(data)
    model = Model.find_or_create_by!(rsi_id: data['id'])
    model.update(
      name: strip_name(data['name']),
      rsi_name: data['name'],
      production_status: data['production_status'],
      production_note: data['production_note'],
      description: data['description'],
      length: data['length'].to_f,
      beam: data['beam'].to_f,
      height: data['height'].to_f,
      mass: data['mass'].to_f,
      size: data['size'],
      cargo: nil_or_float(data['cargocapacity']),
      max_crew: nil_or_int(data['max_crew']),
      min_crew: nil_or_int(data['min_crew']),
      scm_speed: nil_or_float(data['scm_speed']),
      afterburner_speed: nil_or_float(data['afterburner_speed']),
      pitch_max: nil_or_float(data['pitch_max']),
      yaw_max: nil_or_float(data['yaw_max']),
      roll_max: nil_or_float(data['roll_max']),
      xaxis_acceleration: nil_or_float(data['xaxis_acceleration']),
      yaxis_acceleration: nil_or_float(data['yaxis_acceleration']),
      zaxis_acceleration: nil_or_float(data['zaxis_acceleration']),
      classification: data['type'],
      focus: data['focus'],
      store_url: data['url'],
      last_updated_at: data['time_modified.unfiltered']
    )
    # rubocop:disable Style/RescueModifier
    store_images_updated_at = Time.zone.parse(data['media'][0]['time_modified']) rescue nil
    # rubocop:enable Style/RescueModifier
    if model.store_image.blank? || model.store_images_updated_at != store_images_updated_at
      model.store_images_updated_at = data['media'][0]['time_modified']
      model.remote_store_image_url = "#{base_url}#{data['media'][0]['images']['store_hub_large']}"
      model.save
    end
    model
  end

  def strip_name(name)
    name.gsub(/^\s*(?:AEGIS|Aegis|ANVIL|Anvil|BANU|Banu|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an)[^a-zA-Z0-9]+/, '')
  end

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
      size: hardpoint_data['component_size'],
      component_class: hardpoint_data['component_class'],
      component_type: hardpoint_data['type']
    )

    component.update(
      size: hardpoint_data['component_size'],
      component_class: hardpoint_data['component_class'],
      component_type: hardpoint_data['type']
    )

    if hardpoint_data['manufacturer'].present? && hardpoint_data['manufacturer'] != 'TBD'
      component.manufacturer = Manufacturer.find_or_create_by!(name: hardpoint_data['manufacturer'].strip)
      component.save
    end

    component
  end

  private def nil_or_float(value)
    return if value.blank?
    value.to_f
  end

  private def nil_or_int(value)
    return if value.blank?
    value.to_i
  end
end
