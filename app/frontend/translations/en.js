import { messages as validationMessages } from 'vee-validate/dist/locale/en.json'
import actions from './en/actions'
import headlines from './en/headlines'
import labels from './en/labels'
import messages from './en/messages'
import nav from './en/nav'
import placeholders from './en/placeholders'
import sublines from './en/sublines'
import texts from './en/texts'
import title from './en/title'
import privacySettings from './en/privacySettings'
import validationError from './en/validationError'

const validations = {}
Object.keys(validationMessages).forEach((key) => {
  validations[key] = validationMessages[key].replace(/\{/g, '%{')
})

export default {
  actions,
  app: 'FleetYards.net',
  celestialObject: {
    danger: 'Danger',
    economy: 'Economy',
    fairchanceakt: 'Fair Chance Akt?',
    habitable: 'Habitable?',
    population: 'Population',
    subType: 'Sub Type',
    type: 'Type',
  },
  commodityItem: {
    damageReduction: 'Damage Reduction',
    extras: 'Additional Info',
    grade: 'Grade',
    itemClass: 'Item Class',
    itemType: 'Item Type',
    location: 'Location',
    manufacturer: 'Manufacturer',
    range: 'Range',
    rateOfFire: 'Rate of Fire',
    shop: 'Shop',
    size: 'Size',
    slot: 'Slot',
    storage: 'Storage',
    type: 'Type',
    unconfirmed: 'Item is unconfirmed',
    weaponClass: 'Weapon Class',
  },
  component: {
    manufacturer: 'Manufacturer',
    size: 'Size',
  },
  datetime: {
    formats: {
      default: "d MMMM y 'at' HH:mm z",
      iso: "yyyy-MM-dd'T'HH:mm:ss.SSSxxx",
    },
  },
  headlines,
  labels,
  messages,
  meta: {
    description:
      'FleetYards.net, Your Database for all Information related to Ships from “Star Citizen“.',
    keywords:
      'Star Citizen, Spaceships, Ships, Fighter, Database, Squadron, 42, Star, Citizen, English, Chris, Roberts, Online, Game, Space, Simulation',
  },
  model: {
    afterburnerGroundSpeed: 'with Afterburner',
    afterburnerSpeed: 'Afterburner Speed',
    beam: 'Beam',
    cargo: 'Cargo',
    classification: 'Classification',
    crew: 'Crew',
    equipment: 'Equipment',
    focus: 'Focus',
    groundSpeed: 'Ground Speed',
    hardpoints: 'Hardpoints',
    height: 'Height',
    hydrogenFuelTankSize: 'Fuel',
    lastUpdatedAt: 'Last updated at?',
    length: 'Length',
    manufacturer: 'Manufacturer',
    mass: 'Mass',
    maxCrew: 'max. Crew',
    maxUpgrades: 'Upgrades',
    minCrew: 'min. Crew',
    modular: 'Modular',
    netCargo: 'Cargo with Rover/Snub',
    ordnance: 'Ordnance',
    pitchMax: 'Pitch Max',
    pledgePrice: 'Pledge Price',
    price: 'Price',
    productionStatus: 'Production Status',
    propulsion: 'Propulsion',
    quantumFuelTankSize: 'Quantum Fuel',
    rentalAt: 'Rental at?',
    rollMax: 'Roll Max',
    scmSpeed: 'SCM Speed',
    size: 'Size',
    soldAt: 'Sold at?',
    speed: 'Speed',
    variants: 'Variants',
    weapons: 'Weapons',
    xaxisAcceleration: 'X-Axis',
    yawMax: 'Yaw Max',
    yaxisAcceleration: 'Y-Axis',
    zaxisAcceleration: 'Z-Axis',
  },
  nav,
  number: {
    cargo: '%{count} SCU',
    distance: '%{count} m',
    format: {
      delimiter: '.',
      precision: 2,
      separator: ',',
      strip_insignificant_zeros: true,
    },
    fuel: '%{count}',
    people: {
      one: '%{count} person',
      other: '%{count} persons',
    },
    percent: '%{count} %',
    rateOfFire: '%{count} shots/min',
    rotation: '%{count} deg/s',
    ships: {
      one: '%{count} ship',
      other: '%{count} ships',
    },
    speed: '%{count} m/s',
    weight: '%{count} t',
  },
  pagination: {
    gap: '&hellip;',
    next: 'Next Page',
    previous: 'Previous Page',
  },
  placeholders,
  privacySettings,
  resources: {
    images: 'Images',
    models: 'Ships',
  },
  shop: {
    celestialObject: 'Location',
    location: '%{name} at %{location}',
    refineryTerminal: 'Refinery Terminal',
    station: 'Station',
    type: 'Type',
  },
  shopCommodity: {
    boughtAt: 'Bought at',
    listedAt: 'Listed at',
    soldAt: 'Sold at',
  },
  starsystem: {
    danger: 'Danger',
    economy: 'Economy',
    population: 'Population',
    size: 'Size',
    type: 'Type',
  },
  station: {
    cargoHub: 'Cargo Hub',
    classification: 'Classification',
    habitable: 'Habitable?',
    location: 'Location',
    refinery: 'Refinery Station',
    type: 'Type',
  },
  sublines,
  texts,
  title,
  validation_error: validationError,
  validations,
}
