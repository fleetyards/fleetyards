import actions from './en/actions'
import headlines from './en/headlines'
import labels from './en/labels'
import messages from './en/messages'
import nav from './en/nav'
import placeholders from './en/placeholders'
import sublines from './en/sublines'
import texts from './en/texts'
import title from './en/title'

export default {
  app: 'FleetYards.net',
  meta: {
    description: 'FleetYards.net, Your Database for all Information related to Ships from “Star Citizen“.',
    keywords: 'Star Citizen, Spaceships, Ships, Fighter, Database, Squadron, 42, Star, Citizen, English, Chris, Roberts, Online, Game, Space, Simulation',
  },
  title: {
    ...title,
  },
  headlines: {
    ...headlines,
  },
  sublines: {
    ...sublines,
  },
  nav: {
    ...nav,
  },
  labels: {
    ...labels,
  },
  placeholders: {
    ...placeholders,
  },
  actions: {
    ...actions,
  },
  texts: {
    ...texts,
  },
  messages: {
    ...messages,
  },
  station: {
    type: 'Type',
    location: 'Location',
  },
  model: {
    focus: 'Focus',
    classification: 'Classification',
    size: 'Size',
    beam: 'Beam',
    cargo: 'Cargo',
    netCargo: 'Cargo with Rover/Snub',
    crew: 'Crew',
    speed: 'Speed',
    minCrew: 'min. Crew',
    maxCrew: 'max. Crew',
    scmSpeed: 'SCM Speed',
    afterburnerSpeed: 'Afterburner Speed',
    groundSpeed: 'Ground Speed',
    afterburnerGroundSpeed: 'with Afterburner',
    pitchMax: 'Pitch Max',
    yawMax: 'Yaw Max',
    rollMax: 'Roll Max',
    price: 'Price',
    pledgePrice: 'Pledge Price',
    xaxisAcceleration: 'X-Axis',
    yaxisAcceleration: 'Y-Axis',
    zaxisAcceleration: 'Z-Axis',
    height: 'Height',
    length: 'Length',
    mass: 'Mass',
    manufacturer: 'Manufacturer',
    hardpoints: 'Hardpoints',
    weapons: 'Weapons',
    equipment: 'Equipment',
    variants: 'Variants',
    maxUpgrades: 'Upgrades',
    productionStatus: 'Production Status',
    propulsion: 'Propulsion',
    ordnance: 'Ordnance',
    modular: 'Modular',
    soldAt: 'Sold at?',
    rentalAt: 'Rental at?',
    lastUpdatedAt: 'Last updated at?',
  },
  component: {
    manufacturer: 'Manufacturer',
    size: 'Size',
  },
  celestialObject: {
    type: 'Type',
    subType: 'Sub Type',
    habitable: 'Habitable?',
    fairchanceakt: 'Fair Chance Akt?',
    population: 'Population',
    economy: 'Economy',
    danger: 'Danger',
  },
  starsystem: {
    type: 'Type',
    size: 'Size',
    population: 'Population',
    economy: 'Economy',
    danger: 'Danger',
  },
  shop: {
    type: 'Type',
    celestialObject: 'Location',
    station: 'Station',
    rentalPrice1Day: '1 day for',
    rentalPrice3Days: '3 days for',
    rentalPrice7Days: '7 days for',
    rentalPrice30Days: '30 days for',
    location: '%{name} at %{location}',
  },
  commodityItem: {
    grade: 'Grade',
    type: 'Type',
    itemType: 'Item Type',
    itemClass: 'Item Class',
    weaponClass: 'Weapon Class',
    size: 'Size',
    range: 'Range',
    damageReduction: 'Damage Reduction',
    rateOfFire: 'Rate of Fire',
    extras: '',
  },
  resources: {
    models: 'Ships',
    images: 'Images',
  },
  pagination: {
    previous: 'Previous Page',
    next: 'Next Page',
    gap: '&hellip;',
  },
  datetime: {
    formats: {
      default: "d MMMM y 'at' HH:mm z",
      iso: "yyyy-MM-dd'T'HH:mm:ss.SSSxxx",
    },
  },
  number: {
    format: {
      precision: 2,
      strip_insignificant_zeros: true,
      delimiter: '.',
      separator: ',',
    },
    percent: '%{count} %',
    distance: '%{count} m',
    weight: '%{count} t',
    speed: '%{count} m/s',
    rateOfFire: '%{count} shots/min',
    rotation: '%{count} deg/s',
    cargo: '%{count} SCU',
    ships: {
      one: '%{count} ship',
      other: '%{count} ships',
    },
    people: {
      one: '%{count} person',
      other: '%{count} persons',
    },
  },
}
