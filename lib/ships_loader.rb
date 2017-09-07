# frozen_string_literal: true

class ShipsLoader
  attr_accessor :json_file_path, :base_url, :vat_percent

  def initialize(options = {})
    @json_file_path = "public/ships.json"
    @base_url = options[:base_url] || "https://robertsspaceindustries.com"
    @vat_percent = options[:vat_percent] || 23
  end

  def all
    ships = load_ships

    ships.each do |data|
      sync_ship(data)
    end

    cleanup_ship_roles
  end

  def one(ship_name)
    ships = load_ships

    ship_data = ships.find { |ship| ship["name"] == ship_name }
    sync_ship(ship_data) if ship_data.present?

    cleanup_ship_roles
  end

  def cleanup_ship_roles
    ShipRole.includes(:ships).where(ships: { ship_role_id: nil }).destroy_all
  end

  def load_ships
    return JSON.parse(File.read(json_file_path)) if Rails.env.test?

    response = Typhoeus.get("#{base_url}/ship-specs")

    match = response.body.match(/data: \[(.+)\]/)
    begin
      ship_data = JSON.parse("[#{match[1]}]")
      File.open(json_file_path, "w") do |f|
        f.write(ship_data.to_json)
      end
      ship_data
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "ShipData could not be parsed: [#{match[1]}]"
      []
    end
  end

  def sync_ship(data)
    ship = create_or_update_ship(data)

    buying_options = get_buying_options(ship.store_url)
    ship.price = buying_options.price
    ship.on_sale = buying_options.on_sale

    ship.ship_role = create_or_update_ship_role(data["focus"])
    ship.manufacturer = create_or_update_manufacturer(data["manufacturer"])

    create_or_update_propulsion_hardpoints(ship.id, data["propulsion"])
    create_or_update_ordnance_hardpoints(ship.id, data["ordnance"])
    create_or_update_modular_hardpoints(ship.id, data["modular"])
    create_or_update_avionics_hardpoints(ship.id, data["avionics"])

    ship.enabled = true

    ship.save!
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

  private def create_or_update_ship(data)
    ship = Ship.find_or_initialize_by(name: data["name"])
    raise ship.errors.to_yaml unless ship.save

    ship.update(
      rsi_id: data["id"],
      production_status: data["production_status"],
      production_note: data["production_note"],
      description: data["description"],
      length: data["length"],
      beam: data["beam"],
      height: data["height"],
      mass: data["mass"].to_i / 100,
      cargo: data["cargocapacity"],
      crew: data["maxcrew"],
      powerplant_size: data["maxpowerplantsize"],
      shield_size: data["maxshieldsize"],
      classification: data["classification"],
      focus: data["focus"],
      store_url: data["url"]
    )

    if ship.store_image.blank?
      ship.remote_store_image_url = "#{base_url}#{data['media'][0]['images']['store_hub_large']}"
      ship.save
    end

    ship
  end

  def create_or_update_ship_role(ship_role)
    ShipRole.find_or_create_by(name: ship_role)
  end

  def create_or_update_manufacturer(manufacturer_data)
    manufacturer = Manufacturer.find_or_initialize_by(name: manufacturer_data["name"])
    raise manufacturer.errors.to_yaml unless manufacturer.save

    manufacturer.update(
      rsi_id: manufacturer_data["id"],
      known_for: manufacturer_data["known_for"],
      description: manufacturer_data["description"],
      remote_logo_url: ("#{base_url}#{manufacturer_data['media'][0]['source_url']}" if manufacturer.logo.blank?),
      enabled: true
    )

    manufacturer
  end

  def create_or_update_propulsion_hardpoints(ship_id, propulsion_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "propulsion")
    raise category.errors.to_yaml unless category.save

    propulsion_data.each do |data|
      create_or_update_hardpoint(data, category, ship_id)
    end

    cleanup_hardpoints(ship_id, category.id, propulsion_data)
  end

  def create_or_update_ordnance_hardpoints(ship_id, ordnance_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "ordnance")
    raise category.errors.to_yaml unless category.save

    ordnance_data.each do |data|
      create_or_update_hardpoint(data, category, ship_id)
    end

    cleanup_hardpoints(ship_id, category.id, ordnance_data)
  end

  def create_or_update_modular_hardpoints(ship_id, modular_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "modular")
    raise category.errors.to_yaml unless category.save

    modular_data.each do |data|
      create_or_update_hardpoint(data, category, ship_id)
    end

    cleanup_hardpoints(ship_id, category.id, modular_data)
  end

  def create_or_update_avionics_hardpoints(ship_id, avionics_data)
    category = ComponentCategory.find_or_initialize_by(rsi_name: "avionics")
    raise category.errors.to_yaml unless category.save

    avionics_data.each do |data|
      create_or_update_hardpoint(data, category, ship_id)
    end

    cleanup_hardpoints(ship_id, category.id, avionics_data)
  end

  def create_or_update_hardpoint(hardpoint_data, category, ship_id)
    Hardpoint.find_or_create_by(
      category_id: category.id,
      ship_id: ship_id,
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

  def cleanup_hardpoints(ship_id, category_id, hardpoint_data)
    rsi_ids = hardpoint_data.map do |data|
      data["id"].to_i
    end
    Hardpoint.where(ship_id: ship_id, category_id: category_id).where.not(rsi_id: rsi_ids).destroy_all
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
