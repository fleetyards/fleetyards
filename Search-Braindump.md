Model -> Model Detail
  name
  description
  manufacturer_name
Component -> Shop Detail
  name
  description
  manufacturer_name
Shop -> Shop Detail
  name
  description
  station_name
  planet_name
ShopCommodities -> Shop Detail
  commodity_item_name
  shop_name
  station_name
  planet_name
  starsystem_name
Station -> Station Detail
  name
  description
  planet_name
Planet -> Planet Detail
  name
  description
  starsystem_name
StarSystem -> Starsystem Detail
  name
  description
Equipment -> Shop Detail
  name
  description
  manufacturer_name
Manufacturer -> Model Detail or Shop Detail
  name
  description
