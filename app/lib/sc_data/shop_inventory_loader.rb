# frozen_string_literal: true

module ScData
  class ShopInventoryLoader < ::ScData::BaseLoader
    def run
      inventory_data = load_inventory_data

      shops = extract_shops(inventory_data)

      missing_shops = shops.select { |shop| shop[:shop] }
      missing_stations = shops.select { |shop| shop[:station] }

      {
        count: shops.size,
        found_shops_count: shops.size - missing_stations.size - missing_shops.size,
        missing_stations_count: missing_stations.size,
        missing_shops_count: missing_shops.size,
        missing_stations: missing_stations,
        missing_shops: missing_shops,
      }
    end

    private def load_inventory_data
      load_from_export('/shops.json')
    end

    private def extract_shops(inventory_data)
      inventory_data.filter_map do |shop_data|
        name_data = shop_data['name'].split(', ').map do |item|
          item.split('_')
        end.flatten

        next if excluded_from_import?(name_data.first, shop_data['name'])

        station = Station.where('name LIKE ?', "%#{station_name_mapping(name_data.second, shop_data['name'])}%").first if name_data.size > 1
        station = Station.where('name LIKE ?', "%#{station_name_mapping(name_data.third, shop_data['name'])}%").first if station.blank? && name_data.size > 2
        station = Station.where('name LIKE ?', "%#{shop_to_station_name_mapping(name_data.first)}%").first if station.blank?

        next { missing: name_data, full_name: shop_data['name'], station: true } if station.blank?

        shop = station.shops.where('name LIKE ?', "%#{shop_name_mapping(name_data.first, shop_data['name'])}%").first
        shop = station.shops.find_by(name: 'Admin Office') if shop.blank? && shop_to_station_name_mapping(name_data.first) == station.name

        if shop.blank?
          next {
            resolved_name: shop_name_mapping(name_data.first, shop_data['name']),
            missing: name_data,
            full_name: shop_data['name'],
            shop: true,
            station_name: station.name
          }
        end

        {
          station_id: station.id,
          shop_id: shop.id,
        }
      end
    end

    private def station_name_mapping(name, full_name)
      mapping = {
        'PortOlisar' => 'Port Olisar',
        'Everus Harbour' => 'Everus Harbor',
        'Hurston HUR-L1' => 'HUR-L1',
        'Hurston HUR-L2' => 'HUR-L2',
        'Hurston HUR-L3' => 'HUR-L3',
        'Hurston HUR-L4' => 'HUR-L4',
        'Hurston HUR-L5' => 'HUR-L5',
        'Microtech MIC-L1' => 'MIC-L1',
        'MIC-LEO1' => 'MIC-L1',
        'New Babbage Spaceport' => 'New Babbage',
        'GrimHex' => 'GrimHEX',
        'Grimhex' => 'GrimHEX',
        'Lorville Workers DistrictX' => 'Lorville',
        'New Babbage Plaza' => 'New Babbage',
        'New Babbage Double Bubble' => 'New Babbage',
        'Area 18 Plaza' => 'Area 18',
        'ARC-LEO1' => 'ARC-L1',
        'HUR-LEO1' => 'HUR-L1',
        'LiveFireWeapons_Stanton4_L1' => 'MIC-L1',
        'NewBab_Hospital' => 'New Babbage',
        'A18_Hospital' => 'Area 18',
        'MPOH_Hospital' => 'Lorville',
        'RS_RefineryStore_Stanton1_L1' => 'HUR-L1',
        'RS_RefineryStore_Stanton1_L2' => 'HUR-L2',
        'RS_RefineryStore_Stanton2_L1' => 'CRU-L1',
        'RS_RefineryStore_Stanton3_L1' => 'ARC-L1',
        'RS_RefineryStore_Stanton4_L1' => 'MIC-L1',
        'MiningKiosks_RS_Stanton1_L1' => 'HUR-L1',
        'MiningKiosks_RS_Stanton1_L2' => 'HUR-L2',
        'MiningKiosks_RS_Stanton2_L1' => 'CRU-L1',
        'MiningKiosks_RS_Stanton3_L1' => 'ARC-L1',
        'MiningKiosks_RS_Stanton4_L1' => 'MIC-L1',
      }

      return name if mapping[name].blank? && mapping[full_name].blank?

      mapping[full_name] || mapping[name]
    end

    private def shop_to_station_name_mapping(name)
      mapping = {
        'CousinCrows' => 'Orison',
        'KelTo' => 'Orison',
        'Humbolt Mines' => 'Humboldt Mines',
        'HMDS Perlman' => 'HDMS Perlman',
        'ArcCorp mining Area 45' => 'ArcCorp Mining Area 045',
        'ArcCorp mining Area 48' => 'ArcCorp Mining Area 048',
        'ArcCorp mining Area 56' => 'ArcCorp Mining Area 056',
        'ArcCorp mining Area 61' => 'ArcCorp Mining Area 061',
        'Private Property' => 'PRIVATE PROPERTY',
        'Tram & Meyers Mining' => 'Tram & Myers Mining',
        'OrisonProvidenceSurplus' => 'Orison',
        'Covalex-Orison' => 'Orison',
        'Voyager' => 'Orison',
        'CrusaderShowroom' => 'Orison',
      }

      return name if mapping[name].blank?

      mapping[name]
    end

    private def shop_name_mapping(name, full_name)
      mapping = {
        'NewBab_Hospital' => 'BRENTWORTH - CARE CENTER',
        'A18_Hospital' => 'EMPIRE',
        'MPOH_Hospital' => 'MARIA - Pure of Heart',
        'DumpersDepot' => "Dumper's Depot",
        'GarrityDefense' => 'Garrity Defense',
        'Centermass' => 'CenterMass',
        'LiveFireWeapons' => 'Live Fire Weapons',
        'CargoOffice' => 'Cargo Office',
        'TDD' => 'Trade & Development Division',
        'AdminOffice' => 'Admin Office',
        'AdminOffice_Orison' => 'Orison Municipal Services',
        'CasabaOutlet' => 'Casaba Outlet',
        'CousinCrows' => 'Cousin Crows',
        'GrandBarterBazaar' => 'Grand Barter',
        'GrandBarterBazaar' => 'Grand Barter',
        'Covalex-Orison' => 'Covalex Shipping',
        'OrisonProvidenceSurplus' => 'Providence Surplus',
        'TravelerRentals' => 'Traveler Rentals',
        'CrusaderShowroom' => 'Crusader Showroom',
        'CrusaderShowroomWeaponry' => 'Crusader Showroom',
        'M&V Bar' => 'M & V',
        'G-Loc' => 'G-LOC Bar',
        'Cafe Musain' => 'Cafe Musáin',
        'FPS Armour' => 'Bulwark Armor',
        'Ship Weapons' => 'Congreve Weapons',
        'LiveFireWeapons_Stanton4_L1' => 'Live Fire Weapons',
        'Hurston Dynamics Showcase' => 'HD Showcase',
        'Transfers Room' => 'CBD Transfers',
        'RS_RefineryStore_Stanton1_L1' => 'Refinery Store',
        'RS_RefineryStore_Stanton1_L2' => 'Refinery Store',
        'RS_RefineryStore_Stanton2_L1' => 'Refinery Store',
        'RS_RefineryStore_Stanton3_L1' => 'Refinery Store',
        'RS_RefineryStore_Stanton4_L1' => 'Refinery Store',
        'MiningKiosks_RS_Stanton1_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton1_L2' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton2_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton3_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton4_L1' => 'Mining Kiosks',
        'KelTo' => 'Kel-To',
        'Locker Room' => 'Blackmarket Terminal',
      }

      return name if mapping[name].blank? && mapping[full_name].blank?

      mapping[full_name] || mapping[name]
    end

    private def excluded_from_import?(name, full_name)
      mapping = [
        'CryAstro', # CryAstro no longer exists
        'Klescher Prison Commissary', # Ignore Klesher stuff
        'ExpoHall', # Ignore Expo stuff
        'BestInShow', # Ignore Expo stuff
        'ARGO', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - Aopoa', # Ignore Expo stuff
        'CRUS', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - Anvil', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - RSI', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - Drake', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - Aegis', # Ignore Expo stuff
        'IAE Expo Anniversary Sales - Origin', # Ignore Expo stuff
        'FPSWeaponsArmor', # Ignore Expo stuff
        'ShipWeaponsItems', # Ignore Expo stuff
        'MISC', # Ignore Expo stuff
        'Xenothreat-SecurityStation', # Ignore Xeno stuff
        'Burrito', # Ignore Food stuff
        'HotDog', # Ignore Food stuff
        'HotDogBar', # Ignore Food stuff
        'PizzaBar', # Ignore Food stuff
        'JuiceBar', # Ignore Food stuff
        'CoffeeStand', # Ignore Food stuff
        'CoffeeShop', # Ignore Food stuff
        'CoffeeShop', # Ignore Food stuff
        'DrinksShop', # Ignore Food stuff
        'NoodleBar', # Ignore Food stuff
        "Whammer's", # Ignore Food stuff
        'Ellroys', # Ignore Food stuff
        'BurritoBar', # Ignore Food stuff
        'Burrito', # Ignore Food stuff
        'Shallow Fields Station Admin Office, CRU-L4 (removed)', # Ignore Removed Station
        'NewBabbage_Spaceport', # Ignore Food stuff
        'RestStop_Bars', # Ignore Food stuff
        'Generic', # Ignore Food stuff
        'KetTo_Food', # Ignore Food stuff
        'Refinery_Rentals', # Ignore Refinery Rentals for now
        'CargoOffice_Rentals', # Ignore Refinery Rentals for now
        'stanton_4_shubin_001', # Can't map to remaining Microtech Shubin Outposts
        'stanton_4_shubin_002', # Can't map to remaining Microtech Shubin Outposts
        'stanton_4_shubin_005', # Can't map to remaining Microtech Shubin Outposts
        'Cellin Stash House',
        'Fence Junkyard',
      ]

      return true if mapping.include?(name) || mapping.include?(full_name)

      false
    end
  end
end
