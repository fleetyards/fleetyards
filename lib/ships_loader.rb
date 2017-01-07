class ShipsLoader < Struct.new(:base_url)
  def initialize options = {}
    self.base_url ||= options[:base_url]
    self.base_url ||= "https://robertsspaceindustries.com"
  end

  def run
    body = Typhoeus.get(
      "#{self.base_url}/ship-specs"
    ).body

    match = body.match(/data: \[(.+)\]/)
    begin
      ships = JSON.parse("[#{match[1]}]")
      File.open("public/ships.json", "w") do |f|
        f.write(ships.to_json)
      end

      old_locale = I18n.locale
      I18n.locale = :en

      ships.each do |data|
        ship = create_ship(data)
        ship.ship_role = create_ship_role(data["focus"])
        ship.manufacturer = create_manufacturer(data["manufacturer"])

        ship.hardpoints.delete_all

        create_propulsion_hardpoints(ship.id, data["propulsion"])
        create_ordnance_hardpoints(ship.id, data["ordnance"])
        create_modular_hardpoints(ship.id, data["modular"])
        create_avionics_hardpoints(ship.id, data["avionics"])

        ship.enabled = true

        ship.save!
      end

      I18n.reload!
      I18n.locale = old_locale
    rescue JSON::ParserError => e
      p "ShipData could not be parsed: [#{match[1]}]"
    end
    Rails.cache.clear
  end

  private

  def create_ship data
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
      remote_image_url: ("#{self.base_url}#{data["media"][0]["source_url"]}" unless ship.image.present?),
      remote_store_image_url: ("#{self.base_url}#{data["media"][0]["images"]["store_hub_large"]}" unless ship.store_image.present?),
      store_url: data["url"],
      propulsion_raw: data["propulsion"],
      ordnance_raw: data["ordnance"],
      modular_raw: data["modular"],
      avionics_raw: data["avionics"]
    )

    ship
  end

  def create_ship_role ship_role
    ShipRole.find_or_create_by(name: ship_role)
  end

  def create_manufacturer manufacturer_data
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

  def create_propulsion_hardpoints ship_id, propulsion_data
    category = ComponentCategory.find_or_create_by(rsi_name: "propulsion")

    propulsion_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        hardpoint_class: data["type"],
        rating: data["rating"],
        component: (create_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_ordnance_hardpoints ship_id, ordnance_data
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
        component: (create_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_modular_hardpoints ship_id, modular_data
    category = ComponentCategory.find_or_create_by(rsi_name: "modular")

    modular_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        max_size: data["max_size"],
        component: (create_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_avionics_hardpoints ship_id, avionics_data
    category = ComponentCategory.find_or_create_by(rsi_name: "avionics")

    avionics_data.each do |data|
      hardpoint = Hardpoint.create(
        ship_id: ship_id,
        rsi_id: data["id"],
        category_id: category.id,
        name: data["name"],
        component: (create_component(data["component"], category) unless data["component"].nil?)
      )
    end
  end

  def create_component component_data, category
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
