class ShipsLoader < Struct.new(:base_url, :json_file_path, :vat_percent)
  def initialize(options = {})
    self.base_url ||= options[:base_url]
    self.base_url ||= "https://robertsspaceindustries.com"
    self.json_file_path = "public/ships.json"
    self.vat_percent ||= options[:vat_percent]
    self.vat_percent ||= 23
  end

  def all
    old_locale = I18n.locale
    I18n.locale = :en

    ships = load_ships

    ships.each do |data|
      sync_ship(data)
    end

    I18n.reload!
    I18n.locale = old_locale
  end

  def one(ship_name)
    old_locale = I18n.locale
    I18n.locale = :en

    ships = load_ships

    ship_data = ships.find { |ship| ship["name"] == ship_name }
    sync_ship(ship_data) if ship_data.present?

    I18n.reload!
    I18n.locale = old_locale
  end

  def sync_ship(data)
    ship = create_or_update_ship(data)

    buying_options = get_buying_options(ship.store_url)
    ship.price = buying_options.price
    ship.on_sale = buying_options.on_sale

    ship.ship_role = create_or_update_ship_role(data["focus"])
    ship.manufacturer = create_or_update_manufacturer(data["manufacturer"])

    ship.hardpoints.delete_all

    create_propulsion_hardpoints(ship.id, data["propulsion"])
    create_ordnance_hardpoints(ship.id, data["ordnance"])
    create_modular_hardpoints(ship.id, data["modular"])
    create_avionics_hardpoints(ship.id, data["avionics"])

    ship.enabled = true

    ship.save!
  end

  def get_buying_options(store_url)
    response = Typhoeus.get("#{self.base_url}#{store_url}")
    page = Nokogiri::HTML(response.body)

    price = nil
    if price_element = page.css('#buying-options .final-price').last
      raw_price = price_element.text
      price_match = raw_price.match(/^\$(\d+.\d+) USD$/)
      price_with_local_vat = price_match[1].to_f if price_match.present?
      price = price_with_local_vat * 100 / (100 + self.vat_percent)
    end

    OpenStruct.new({
      price: price.present? ? price : 0.0,
      on_sale: price.present? ? true : false
    })
  end

  def load_ships
    if File.exists?(self.json_file_path)
      last_updated = (Time.now - File.stat(self.json_file_path).mtime).to_i
    else
      last_updated = 9999
    end

    if last_updated > 1800
      Rails.logger.debug("Loading Ships from RSI")
      load_ships_from_rsi
    else
      Rails.logger.debug("Loading Ships from File")
      load_ships_from_file
    end
  end

  def load_ships_from_rsi
    response = Typhoeus.get("#{self.base_url}/ship-specs")

    match = response.body.match(/data: \[(.+)\]/)
    begin
      ship_data = JSON.parse("[#{match[1]}]")
      File.open(self.json_file_path, "w") do |f|
        f.write(ship_data.to_json)
      end
      ship_data
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "ShipData could not be parsed: [#{match[1]}]"
      []
    end
  end

  def load_ships_from_file
    begin
      file = File.read(self.json_file_path)
      JSON.parse(file)
    rescue Exception => e
      Raven.capture_exception(e)
      Rails.logger.error "ShipData could not be loaded from File"
      []
    end
  end

  private def create_or_update_ship(data)
    ship = Ship.find_or_create_by(name: data["name"])

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
      remote_store_image_url: ("#{self.base_url}#{data["media"][0]["images"]["store_hub_large"]}" unless ship.store_image.present?),
      store_url: data["url"],
      propulsion_raw: data["propulsion"],
      ordnance_raw: data["ordnance"],
      modular_raw: data["modular"],
      avionics_raw: data["avionics"]
    )

    ship
  end

  def create_or_update_ship_role(ship_role)
    ShipRole.find_or_create_by(name: ship_role)
  end

  def create_or_update_manufacturer(manufacturer_data)
    manufacturer = Manufacturer.find_or_create_by(name: manufacturer_data["name"])

    manufacturer.update(
      rsi_id: manufacturer_data["id"],
      known_for: manufacturer_data["known_for"],
      description: manufacturer_data["description"],
      remote_logo_url: ("#{self.base_url}#{manufacturer_data["media"][0]["source_url"]}" unless manufacturer.logo.present?),
      enabled: true
    )

    manufacturer
  end

  def create_propulsion_hardpoints(ship_id, propulsion_data)
    category = ComponentCategory.find_or_create_by(rsi_name: "propulsion")

    propulsion_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        hardpoint_class: data["type"],
        rating: data["rating"],
        component: (create_or_update_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_ordnance_hardpoints(ship_id, ordnance_data)
    category = ComponentCategory.find_or_create_by(rsi_name: "ordnance")

    ordnance_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        hardpoint_class: data["class"],
        max_size: data["max_size"],
        quantity: data["quantity"],
        component: (create_or_update_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_modular_hardpoints(ship_id, modular_data)
    category = ComponentCategory.find_or_create_by(rsi_name: "modular")

    modular_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        max_size: data["max_size"],
        component: (create_or_update_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_avionics_hardpoints(ship_id, avionics_data)
    category = ComponentCategory.find_or_create_by(rsi_name: "avionics")

    avionics_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        component: (create_or_update_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_or_update_component(component_data, category)
    component = Component.find_or_create_by(name: component_data["name"])

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
