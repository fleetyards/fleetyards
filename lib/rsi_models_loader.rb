# frozen_string_literal: true

class RsiModelsLoader
  attr_accessor :json_file_path, :base_url, :vat_percent

  def initialize(options = {})
    @json_file_path = "public/models.json"
    @base_url = options[:base_url] || "https://robertsspaceindustries.com"
    @vat_percent = options[:vat_percent] || 23
  end

  def all
    models = load_models

    models.each do |data|
      sync_model(data)
    end
  end

  def one(model_name)
    models = load_models

    model_data = models.find { |model| model["name"] == model_name }
    sync_model(model_data) if model_data.present?
  end

  def load_models
    if Rails.env.test? && File.exist?(json_file_path)
      return JSON.parse(File.read(json_file_path))['data']
    end

    response = Typhoeus.get("#{base_url}/ship-matrix/index")

    begin
      model_data = JSON.parse(response.body)
      File.open(json_file_path, "w") do |f|
        f.write(model_data.to_json)
      end
      model_data['data']
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "Model Data could not be parsed: [#{match[1]}]"
      []
    end
  end

  def sync_model(data)
    model = create_or_update_model(data)

    buying_options = get_buying_options(model.store_url)
    model.price = buying_options.price
    model.on_sale = buying_options.on_sale

    model.manufacturer = create_or_update_manufacturer(data["manufacturer"])

    model.hardpoints.destroy_all

    components = data['compiled']
    components.keys.each do |component_class|
      types = components[component_class]
      types.keys.each do |type|
        types[type].each do |hardpoint_data|
          create_or_update_hardpoint(hardpoint_data, model.id)
        end
      end
    end

    model.save!
  end

  def get_buying_options(store_url)
    response = Typhoeus.get("#{base_url}#{store_url}")
    page = Nokogiri::HTML(response.body)

    price_element = page.css('#buying-options .final-price').first
    price = if price_element
              raw_price = price_element.text
              price_match = raw_price.match(/^\$(\d+.\d+) USD$/)
              price_with_local_vat = price_match[1].to_f if price_match.present?
              price_with_local_vat * 100 / (100 + vat_percent) if price_with_local_vat.present?
            end

    OpenStruct.new(
      price: price.present? ? price : 0.0,
      on_sale: price.present? ? true : false
    )
  end

  private def create_or_update_model(data)
    model = Model.find_or_create_by!(rsi_id: data['id'])

    model.update(
      name: data['name'],
      production_status: data['production_status'],
      production_note: data['production_note'],
      description: data['description'],
      length: data['length'].to_f,
      beam: data['beam'].to_f,
      height: data['height'].to_f,
      mass: data['mass'].to_f,
      size: data['size'],
      cargo: data['cargocapacity'].to_f,
      max_crew: data['max_crew'].to_i,
      min_crew: data['min_crew'].to_i,
      scm_speed: data['scm_speed'].to_f,
      afterburner_speed: data['afterburner_speed'].to_f,
      pitch_max: data['pitch_max'].to_f,
      yaw_max: data['yaw_max'].to_f,
      roll_max: data['roll_max'].to_f,
      xaxis_acceleration: data['xaxis_acceleration'].to_f,
      yaxis_acceleration: data['yaxis_acceleration'].to_f,
      zaxis_acceleration: data['zaxis_acceleration'].to_f,
      classification: data['type'],
      focus: data['focus'],
      store_url: data['url']
    )

    if model.store_image.blank?
      model.remote_store_image_url = "#{base_url}#{data['media'][0]['images']['store_hub_large']}"
      model.save
    end

    model
  end

  def create_or_update_manufacturer(manufacturer_data)
    manufacturer = Manufacturer.find_or_create_by!(rsi_id: manufacturer_data["id"])

    manufacturer.update(
      name: manufacturer_data['name'],
      code: (manufacturer_data['code'] if manufacturer_data['code'].present?),
      known_for: (manufacturer_data['known_for'] if manufacturer_data['known_for'].present?),
      description: (manufacturer_data['description'] if manufacturer_data['description'].present?),
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
    component = Component.find_or_create_by!(name: hardpoint_data['name'])

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
end
