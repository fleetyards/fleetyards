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

    # create_or_update_propulsion_hardpoints(model.id, data["propulsion"])
    # create_or_update_ordnance_hardpoints(model.id, data["ordnance"])
    # create_or_update_modular_hardpoints(model.id, data["modular"])
    # create_or_update_avionics_hardpoints(model.id, data["avionics"])

    model.enabled = true

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
    model = Model.find_or_create_by!(rsi_id: data["id"])

    model.update(
      name: data["name"],
      production_status: data["production_status"],
      production_note: data["production_note"],
      description: data["description"],
      length: data["length"].to_f,
      beam: data["beam"].to_f,
      height: data["height"].to_f,
      mass: data["mass"].to_f,
      size: data["size"],
      cargo: data["cargocapacity"].to_i,
      max_crew: data["max_crew"].to_i,
      min_crew: data["min_crew"].to_i,
      scm_speed: data["scm_speed"].to_i,
      afterburner_speed: data["afterburner_speed"].to_i,
      classification: data["type"],
      focus: data["focus"],
      store_url: data["url"]
    )

    if model.store_image.blank?
      model.remote_store_image_url = "#{base_url}#{data['media'][0]['images']['store_hub_large']}"
      model.save
    end

    model
  end

  def create_or_update_manufacturer(manufacturer_data)
    manufacturer = Manufacturer.find_or_initialize_by(rsi_id: manufacturer_data["id"])
    raise manufacturer.errors.to_yaml unless manufacturer.save

    manufacturer.update(
      name: manufacturer_data["name"],
      known_for: manufacturer_data["known_for"],
      description: manufacturer_data["description"],
      remote_logo_url: ("#{base_url}#{manufacturer_data['media'][0]['source_url']}" if manufacturer.logo.blank?),
      enabled: true
    )

    manufacturer
  end

  def create_or_update_propulsion_hardpoints(model_id, propulsion_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "propulsion")
    raise category.errors.to_yaml unless category.save

    propulsion_data.each do |data|
      create_or_update_hardpoint(data, category, model_id)
    end

    cleanup_hardpoints(model_id, category.id, propulsion_data)
  end

  def create_or_update_ordnance_hardpoints(model_id, ordnance_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "ordnance")
    raise category.errors.to_yaml unless category.save

    ordnance_data.each do |data|
      create_or_update_hardpoint(data, category, model_id)
    end

    cleanup_hardpoints(model_id, category.id, ordnance_data)
  end

  def create_or_update_modular_hardpoints(model_id, modular_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "modular")
    raise category.errors.to_yaml unless category.save

    modular_data.each do |data|
      create_or_update_hardpoint(data, category, model_id)
    end

    cleanup_hardpoints(model_id, category.id, modular_data)
  end

  def create_or_update_avionics_hardpoints(model_id, avionics_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "avionics")
    raise category.errors.to_yaml unless category.save

    avionics_data.each do |data|
      create_or_update_hardpoint(data, category, model_id)
    end

    cleanup_hardpoints(model_id, category.id, avionics_data)
  end

  def create_or_update_hardpoint(hardpoint_data, category, model_id)
    Hardpoint.find_or_create_by(
      category_id: category.id,
      model_id: model_id,
      rsi_id: hardpoint_data["id"]
    ) do |hardpoint|
      hardpoint.name = hardpoint_data["name"]
      hardpoint.max_size = hardpoint_data["max_size"]
      hardpoint.hardpoint_class = hardpoint_data["class"]
      hardpoint.max_size = hardpoint_data["max_size"]
      hardpoint.quantity = hardpoint_data["quantity"]
      hardpoint.rating = hardpoint_data["rating"]
      unless hardpoint_data["component"].nil?
        hardpoint.component = create_or_update_component(hardpoint_data["component"], category)
      end
    end
  end

  def cleanup_hardpoints(model_id, category_id, hardpoint_data)
    rsi_ids = hardpoint_data.map do |data|
      data["id"].to_i
    end
    Hardpoint.where(model_id: model_id, category_id: category_id).where.not(rsi_id: rsi_ids).destroy_all
  end

  def create_or_update_component(component_data, category)
    component = Component.find_or_initialize_by(name: component_data["name"]) do |c|
      c.component_type = component_data["type"]
      c.category = category
    end
    raise component.errors.to_yaml unless component.save

    component.update(
      rsi_id: component_data["id"],
      size: component_data["size"],
      component_type: component_data["type"],
      category: category,
      enabled: true
    )

    component
  end
end
