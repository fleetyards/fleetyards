class ShipsLoader
  BASE_STATIC_URL = "https://robertsspaceindustries.com/rsi/static/images/"

  def self.run
    body = Typhoeus.get(
      "https://robertsspaceindustries.com/cache/en/rsi-js.js"
    ).body
    match = body.match(/this\.shipData=\[(.+)\]/)
    ships = JSON.parse("[#{match[1]}]")

    ships.each do |data|
      ship = Ship.find_or_create_by(rsi_name: data["title"], basename: data["basename"])
      base_class = Ship.find_or_create_by(basename: data["basename"]) if data["isvariant"]

      old_locale = I18n.locale
      I18n.locale = :en
      max_equipment_data = build_max_equipment(data)
      factory_equipment_data = build_equipment(data)
      weapons_data = build_weapons(data)
      ship.update(
        description: data["description"],
        length: data["length"],
        beam: data["beam"],
        height: data["height"],
        mass: data["mass"].to_i / 100,
        cargo: data["cargocapacity"],
        crew: data["maxcrew"],
        max_upgrades: data["upgradespace"],
        remote_image_url: ("#{BASE_STATIC_URL}game/ship-specs/#{data["imageurl"]}" unless ship.image.present?),
        store_url: data["storeurl"],
        basename: data["basename"],
        base: (base_class.id unless base_class.nil?),
        max_equipment_raw: max_equipment_data.to_json,
        factory_equipment_raw: factory_equipment_data.to_json,
        weapons_raw: weapons_data.to_json
      )

      add_weapon_counts(ship, weapons_data)
      add_equipment_counts(ship, max_equipment_data)

      create_equipment(ship, factory_equipment_data)
      create_weapons(ship, weapons_data)

      ship.ship_role = ShipRole.find_or_create_by(rsi_name: data["role"])

      manufacturer = Manufacturer.find_or_create_by(rsi_name: data["manufacturer"])
      logo_name = manufacturer.slug.gsub('-', '')
      manufacturer.update(
        remote_logo_url: "#{BASE_STATIC_URL}Temp/starcitizen/logo_#{logo_name}.png"
      ) unless manufacturer.logo.present?
      ship.manufacturer = manufacturer

      ship.enabled = true

      ship.save

      I18n.reload!
      I18n.locale = old_locale
    end
  end

  def self.build_max_equipment data
    equipment = {}
    equipment.merge! add_item("max_powerplant", data["maxpowerplant"])
    equipment.merge! add_item("max_primary_thrusters", data["maxprimarythruster"])
    equipment.merge! add_item("max_thrusters", data["maneuveringthrusters"])
    equipment.merge! add_item("max_shield", data["maxshield"])
    equipment
  end

  def self.build_equipment data
    equipment = {}
    equipment.merge! add_item("powerplant", data["factorypowerplant"])
    equipment.merge! add_item("primary_thrusters", data["factorythruster"])
    equipment.merge! add_item("thrusters", data["factorymaneuveringthrusters"])
    equipment.merge! add_item("shield", data["shield"])
    equipment.merge! add_item("additional", data["additionalequipment"])
    equipment
  end

  def self.build_weapons data
    weapons = {}
    weapons.merge! add_item("class1", data["class1_hp"])
    weapons.merge! add_item("class2", data["class2_hp"])
    weapons.merge! add_item("class3", data["class3_hp"])
    weapons.merge! add_item("class4", data["class4_hp"])
    weapons.merge! add_item("class5", data["class5_hp"])
    weapons.merge! add_item("class6", data["class6_hp"])
    weapons.merge! add_item("class7", data["class7_hp"])
    weapons.merge! add_item("class8", data["class8_hp"])
    weapons
  end

  def self.add_weapon_counts ship, data
    values = {}
    Weapon::VALID_CLASSES.each do |hp_class|
      unless data["#{hp_class}_count"].blank?
        values["max_#{hp_class}"] = data["#{hp_class}_count"]
      end
    end
    ship.update(values)
  end

  def self.add_equipment_counts ship, data
    values = {}
    Equipment::VALID_TYPES.each do |type|
      unless data["max_#{type}_count"].blank?
        values["max_#{type}"] = data["max_#{type}_count"]
      end
      unless data["max_#{type}_type"].blank?
        values["max_#{type}_type"] = data["max_#{type}_type"]
      end
    end
    ship.update(values)
  end

  def self.create_weapons ship, data
    weapons = []
    Weapon::VALID_CLASSES.each do |hp_class|
      unless data[hp_class].blank?
        data[hp_class].each do |item|
          weapon = Weapon.find_or_create_by(name: item[:name], hp_class: hp_class)
          item[:count].to_i.times do |i|
            weapons << weapon
          end
        end
      end
    end
    ship.weapons = weapons
    ship.save
  end

  def self.create_equipment ship, data
    Equipment::VALID_TYPES.each do |type|
      unless data[type].blank?
        data[type].each do |item|
          equipment = Equipment.find_or_create_by(name: item[:name], equipment_type: type)
          item[:count].to_i.times do |i|
            ship.equipment << equipment
          end
        end
      end
    end
    ship.save
  end

  def self.add_item name, data
    hash = {}
    count = 0
    type = nil
    items = []
    values = data.split('<br />').map do |v|
      v.strip
    end
    values.delete_if do |v|
      ['None', 'None Equipped', 'Unknown'].include?(v)
    end
    values.each do |v|
      if v.match(/available/)
        match = v.match(/\d+/)
        if match
          count = count + match[0].to_i
        end
      elsif v.match(/^\d+/) || v.downcase != 'coming soon'
        if v.match(/^\d+/)
          item_count = v.match(/^\d+/)[0].to_i
          if v.match(/x(\d+)/)
            item_count = item_count * v.match(/x(\d+)/)[1].to_i
          end
        elsif v.downcase != 'coming soon'
          item_count = 1
        end
        item_name = v.gsub(/\d+x\d?/, '').gsub(/\(.*\)/, '').strip
        if item_name.present? && item_count != 0
          items << {name: item_name, count: item_count}
          count = count + item_count
        end
      end
      if match = v.match(/TR\d/)
        type = match[0]
      end
    end
    hash.merge!({"#{name}" => items}) unless items.blank?
    hash.merge!({"#{name}_count" => count}) unless count == 0
    hash.merge!({"#{name}_type" => type}) unless type.nil?
    hash
  end
end
