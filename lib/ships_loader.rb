class ShipsLoader
  BASE_STATIC_URL = "https://robertsspaceindustries.com/rsi/static/images/"
  def self.run
    body = Typhoeus.get(
      "https://robertsspaceindustries.com/cache/en/rsi-js.js"
    ).body
    match = body.match(/this\.shipData=\[(.+)\]/)
    ships = JSON.parse("[#{match[1]}]")

    ships.each do |ship_data|
      ShipRole.find_or_create_by(rsi_name: ship_data["role"])

    end

    ships.each do |ship_data|
      ship = Ship.find_or_create_by(rsi_name: ship_data["title"])

      ship.update(
        description_en: ship_data["description"],
        length: ship_data["length"],
        beam: ship_data["beam"],
        height: ship_data["height"],
        mass: ship_data["mass"],
        cargo: ship_data["cargocapacity"],
        crew: ship_data["maxcrew"],
        remote_image_url: ("#{BASE_STATIC_URL}game/ship-specs/#{ship_data["imageurl"]}" unless ship.image.present?)
      )

      ship.ship_role = ShipRole.find_or_create_by(rsi_name: ship_data["role"])

      manufacturer = Manufacturer.find_or_create_by(rsi_name: ship_data["manufacturer"])
      logo_name = manufacturer.slug.gsub('-', '')
      manufacturer.update(
        remote_logo_url: "#{BASE_STATIC_URL}Temp/starcitizen/logo_#{logo_name}.png"
      ) unless manufacturer.logo.present?
      ship.manufacturer = manufacturer

      ship.enabled = true

      ship.save
    end
  end
end
