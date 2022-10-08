# frozen_string_literal: true

module ScData
  class ShopInventoryLoader < ::ScData::BaseLoader
    def run
      inventory_data = load_inventory_data

      shops = extract_shops(inventory_data)

      missing_shops = shops.select { |shop| shop[:missing_shop].present? }
      missing_stations = shops.select { |shop| shop[:missing_station].present? }

      shops.each do |shop|
        import_inventory(shop)
      end

      {
        missing_stations_count: missing_stations.size,
        missing_shops_count: missing_shops.size,
        missing_stations: missing_stations,
        missing_shops: missing_shops,
      }
    end

    private def load_inventory_data
      load_from_export('shops.json')
    end

    private def import_inventory(shop)
      shop[:shop_inventory] do |item|
        # "name": "crlf_consumable_adrenaline_01",
        # "displayName": "MedPen (Hemozal)",
        # "basePrice": 100.0,
        # "basePriceOffsetPercentage": 0.0,
        # "maxDiscountPercentage": 0.0,
        # "maxPremiumPercentage": 0.0,
        # "inventory": 1000.0,
        # "optimalInventoryLevel": 100.0,
        # "maxInventory": 5000.0,
        # "autoRestock": true,
        # "autoConsume": false,
        # "refreshRatePercentagePerMinute": 5.0,
        # "shopBuysThis": false,
        # "shopSellsThis": true,
        # "shopRentThis": false,
        # "filename": "Data\\Libs\\Foundry\\Records\\Entities\\SCItem\\Consumables\\crlf_consumable_adrenaline_01.xml",
        # "type": "FPS_Consumable",
        # "subType": "MedPack",
        # "tags": [
        #   "Stash_MediPen",
        #   "medical_injection"
        # ],
        # "rentalTemplates": [],
        # "node_reference": "3f5933b2-a945-4c0c-9395-dbc4b0b3c854",
        # "item_reference": "a6768bc4-5245-4df0-bd57-49fe5ec1994b"
      end
    end

    private def extract_shops(inventory_data)
      inventory_data.filter_map do |shop_data|
        full_name = shop_data['name']
        name_data = extract_name_data(full_name)

        next if excluded_from_import?(name_data.first, full_name)

        station = lookup_station(name_data, full_name: full_name)

        next { missing_station: name_data, full_name: full_name } if station.blank?

        shop = lookup_shop(name_data, full_name: full_name, station: station)

        if shop.blank?
          shop = create_shop(
            name_data,
            full_name: full_name,
            shop_data: shop_data,
            station: station
          )

          unless shop.valid?
            next {
              missing_shop: name_data,
              full_name: full_name,
              station_name: station.name,
              errors: shop.errors.full_messages
            }
          end
        end

        {
          station_id: station.id,
          shop_id: shop.id,
          shop_inventory: shop_data['inventory'],
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
        'Shubin Mining Facility SMO-18' => 'Shubin Mining Facility SM0-18',
        'Shubin Mining Facility SMO-13' => 'Shubin Mining Facility SM0-13',
        'RS_RefineryStore_Stanton1_L1' => 'HUR-L1',
        'RS_RefineryStore_Stanton1_L2' => 'HUR-L2',
        'RS_RefineryStore_Stanton2_L1' => 'CRU-L1',
        'RS_RefineryStore_Stanton3_L1' => 'ARC-L1',
        'RS_RefineryStore_Stanton3_L2' => 'ARC-L2',
        'RS_RefineryStore_Stanton3_L4' => 'ARC-L4',
        'RS_RefineryStore_Stanton4_L1' => 'MIC-L1',
        'RS_RefineryStore_Stanton4_L2' => 'MIC-L2',
        'RS_RefineryStore_Stanton4_L5' => 'MIC-L5',
        'MiningKiosks_RS_Stanton1_L1' => 'HUR-L1',
        'MiningKiosks_RS_Stanton1_L2' => 'HUR-L2',
        'MiningKiosks_RS_Stanton2_L1' => 'CRU-L1',
        'MiningKiosks_RS_Stanton3_L1' => 'ARC-L1',
        'MiningKiosks_RS_Stanton3_L2' => 'ARC-L2',
        'MiningKiosks_RS_Stanton3_L4' => 'ARC-L4',
        'MiningKiosks_RS_Stanton4_L1' => 'MIC-L1',
        'MiningKiosks_RS_Stanton4_L2' => 'ARC-L2',
        'MiningKiosks_RS_Stanton4_L5' => 'MIC-L5',
        'ShipWeapons_Generic_Stanton3_L2' => 'ARC-L2',
        'ShipWeapons_Generic_Stanton3_L3' => 'ARC-L3',
        'ShipWeapons_Generic_Stanton3_L5' => 'ARC-L5',
        'ShipWeapons_Generic_Stanton4_L3' => 'MIC-L3'
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
        'Shubin Mining Facility SMO-13' => 'Shubin Mining Facility SM0-13',
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
        'RS_RefineryStore_Stanton3_L2' => 'Refinery Store',
        'RS_RefineryStore_Stanton3_L4' => 'Refinery Store',
        'RS_RefineryStore_Stanton4_L1' => 'Refinery Store',
        'RS_RefineryStore_Stanton4_L2' => 'Refinery Store',
        'RS_RefineryStore_Stanton4_L5' => 'Refinery Store',
        'MiningKiosks_RS_Stanton1_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton1_L2' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton2_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton3_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton3_L2' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton3_L4' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton4_L1' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton4_L2' => 'Mining Kiosks',
        'MiningKiosks_RS_Stanton4_L5' => 'Mining Kiosks',
        'KelTo' => 'Kel-To',
        'Locker Room' => 'Blackmarket Terminal',
        'Terra Mills Hydro Farm' => 'Admin Office',
        'ShipWeapons_Generic_Stanton4_L3' => 'Congreve Weapons',
        'ShipWeapons_Generic_Stanton3_L2' => 'Congreve Weapons',
        'ShipWeapons_Generic_Stanton3_L5' => 'Congreve Weapons',
        'ShipWeapons_Generic_Stanton3_L3' => 'Congreve Weapons'
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

    def franchise_company_mapping(name)
      franchise_company_mapping = {
        "Dumper's Depot" => :components,
        'Garrity Defense' => :armor,
        'CenterMass' => :weapons,
        'Live Fire Weapons' => :weapons,
        'Cargo Office' => :cargo,
        'Trade & Development Division' => :cargo,
        'Admin Office' => :admin,
        'Casaba Outlet' => :clothing,
        'Traveler Rentals' => :rental,
        'Bulwark Armor' => :armor,
        'Congreve Weapons' => :weapons,
        'Refinery Store' => :refinery,
        'Mining Kiosks' => :mining_equipment,
        'Kel-To' => :superstore
      }

      return :unknown if franchise_company_mapping[name].blank?

      franchise_company_mapping[name]
    end

    private def extract_name_data(full_name)
      full_name.split(', ').map do |item|
        item.split('_')
      end.flatten
    end

    private def lookup_station(name_data, full_name:)
      station = Station.where(name: shop_to_station_name_mapping(name_data.first)).first unless name_data.size.zero?
      station = Station.where('name LIKE ?', "%#{shop_to_station_name_mapping(name_data.first)}%").first if station.blank? && name_data.size.positive?
      station = Station.where('name LIKE ?', "%#{station_name_mapping(name_data.second, full_name)}%").first if station.blank? && name_data.size > 1
      station = Station.where('name LIKE ?', "%#{station_name_mapping(name_data.third, full_name)}%").first if station.blank? && name_data.size > 2

      station
    end

    private def lookup_shop(name_data, full_name:, station:)
      shop = station.shops.where('name LIKE ?', "%#{shop_name_mapping(name_data.first, full_name)}%").first
      shop = station.shops.find_by(name: 'Admin Office') if shop.blank? && shop_to_station_name_mapping(name_data.first) == station.name

      shop
    end

    private def create_shop(name_data, full_name:, shop_data:, station:)
      name = shop_name_mapping(name_data.first, full_name)
      name = 'Admin Office' if shop_to_station_name_mapping(name_data.first) == station.name

      shop = station.shops.find_or_create_by(name: name, rsi_reference: shop_data['reference']) do |new_shop|
        new_shop.shop_type = franchise_company_mapping(name)
      end

      if shop.valid?
        shop.update(
          accepts_stolen_goods: shop_data['acceptsStolenGoods'],
          profit_margin: shop_data['profitMargin'],
          rsi_reference: shop.rsi_reference || shop_data['reference']
        )
      end

      shop
    end
  end
end
