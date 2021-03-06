# frozen_string_literal: true

require 'test_helper'
require 'hangar_importer'
require 'rsi/models_loader'

class HangarImporterTest < ActiveSupport::TestCase
  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:importer) { ::HangarImporter.new }
  let(:user) { users :data }
  let(:subject) { ::HangarImporter.new(data).run(user.id) }
  let(:imported_ships) do
    [
      '100i',
      '125a',
      '135c',
      '300i',
      '315p',
      '325a',
      '350r',
      '600i Executive Edition',
      '600i Explorer',
      '600i Touring',
      '85X',
      '890 Jump',
      'A2 Hercules',
      'Apollo Medivac',
      'Apollo Triage',
      'Ares Inferno',
      'Ares Ion',
      'Arrow',
      'Aurora CL',
      'Aurora ES',
      'Aurora LN',
      'Aurora LX',
      'Aurora MR',
      'Avenger Stalker',
      'Avenger Titan',
      'Avenger Titan Renegade',
      'Avenger Warlock',
      'Ballista',
      'Ballista Dunestalker',
      'Ballista Snowblind',
      'Blade',
      'Buccaneer',
      'C2 Hercules',
      'C8 Pisces',
      'C8X Pisces Expedition',
      'Carrack',
      'Carrack Expedition',
      'Caterpillar',
      'Caterpillar Best In Show Edition',
      'Caterpillar Pirate Edition',
      'Constellation Andromeda',
      'Constellation Aquila',
      'Constellation Phoenix',
      'Constellation Phoenix Emerald',
      'Constellation Taurus',
      'Corsair',
      'Crucible',
      'Cutlass Black',
      'Cutlass Black Best In Show Edition',
      'Cutlass Blue',
      'Cutlass Red',
      'Cyclone',
      'Cyclone-AA',
      'Cyclone-RC',
      'Cyclone-RN',
      'Cyclone-TR',
      'Defender',
      'Dragonfly Black',
      'Dragonfly Star Kitten Edition',
      'Dragonfly Yellowjacket',
      'Eclipse',
      'Endeavor',
      'F7A Hornet',
      'F7C Hornet',
      'F7C Hornet Wildfire',
      'F7C-M Super Hornet',
      'F7C-M Super Hornet Heartseeker',
      'F7C-R Hornet Tracker',
      'F7C-S Hornet Ghost',
      'F8C',
      'F8C Lightning Executive-Edition',
      'Freelancer',
      'Freelancer DUR',
      'Freelancer MAX',
      'Freelancer MIS',
      'Genesis Starliner',
      'Gladiator',
      'Gladius',
      'Gladius Valiant',
      'Glaive',
      'Hammerhead',
      'Hammerhead Best In Show Edition',
      'Hawk',
      'Herald',
      'Hull A',
      'Hull B',
      'Hull C',
      'Hull D',
      'Hull E',
      'Hurricane',
      'Idris-M',
      'Idris-P',
      'Idris-P',
      'Javelin',
      'Khartu-Al',
      'Kraken',
      'Kraken Privateer',
      'M2 Hercules',
      'M50',
      'MPUV Cargo',
      'MPUV Personnel',
      'Mantis',
      'Merchantman',
      'Mercury Star Runner',
      'Mole',
      'Mole Carbon Edition',
      'Mole Talus Edition',
      'Mustang Alpha',
      'Mustang Alpha Vindicator',
      'Mustang Beta',
      'Mustang Delta',
      'Mustang Gamma',
      'Mustang Omega',
      'Nautilus',
      'Nautilus Solstice Edition',
      'Nova',
      'Nox',
      'Nox Kue',
      'Orion',
      'P-52 Merlin',
      'P-72 Archimedes',
      'P-72 Archimedes Emerald',
      'PTV',
      'Pioneer',
      'Pirate Gladius',
      'Polaris',
      'Prospector',
      'Prowler',
      'Ranger CV',
      'Ranger RC',
      'Ranger TR',
      'Razor',
      'Razor EX',
      'Razor LX',
      'Reclaimer',
      'Reclaimer Best In Show Edition',
      'Redeemer',
      'Reliant Kore',
      'Reliant Mako',
      'Reliant Sen',
      'Reliant Tana',
      'Retaliator Base',
      'Retaliator Bomber',
      'SRV',
      'Sabre',
      'Sabre Comet',
      'Sabre Raven',
      "San'tok.yāi",
      'Scythe',
      'Starfarer',
      'Starfarer Gemini',
      'Terrapin',
      'Ursa Rover',
      'Ursa Rover Fortuna',
      'Valkyrie',
      'Valkyrie Liberator Edition',
      'Vanguard Harbinger',
      'Vanguard Hoplite',
      'Vanguard Sentinel',
      'Vanguard Warden',
      'Vulcan',
      'Vulture',
      'X1 Base',
      'X1 Force',
      'X1 Velocity'
    ]
  end

  before do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.all
    end
  end

  describe 'export' do
    let(:data) { JSON.parse(File.read(Rails.root.join('test/fixtures/imports/export.json'))) }

    it 'imports all data' do
      assert_equal(
        {
          missing: [],
          imported: imported_ships,
          success: true
        },
        subject
      )
    end
  end

  describe 'starship42' do
    let(:data) { JSON.parse(File.read(Rails.root.join('test/fixtures/imports/starship42.json'))) }

    it 'imports all data' do
      assert_equal(
        {
          missing: [],
          imported: imported_ships,
          success: true
        },
        subject
      )
    end
  end

  describe 'hangarXPLOR' do
    let(:data) { JSON.parse(File.read(Rails.root.join('test/fixtures/imports/hangarXPLOR.json'))) }

    it 'imports all data' do
      assert_equal(
        {
          missing: [
            'Rover',
          ],
          imported: imported_ships,
          success: true
        },
        subject
      )
    end
  end
end
