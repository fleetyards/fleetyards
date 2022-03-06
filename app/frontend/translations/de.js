// import { messages as validationMessages } from 'vee-validate/dist/locale/de.json'
// import actions from './en/actions'
// import headlines from './en/headlines'
// import labels from './en/labels'
// import messages from './en/messages'
// import nav from './en/nav'
// import placeholders from './en/placeholders'
// import sublines from './en/sublines'
// import texts from './en/texts'
// import title from './en/title'

// const validations = {}
// Object.keys(validationMessages).forEach((key) => {
//   validations[key] = validationMessages[key].replace(/\{/g, '%{')
// })

export default {
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
    extras: '',
    grade: 'Grade',
    itemClass: 'Item Class',
    itemType: 'Item Type',
    range: 'Range',
    rateOfFire: 'Rate of Fire',
    size: 'Size',
    type: 'Type',
    weaponClass: 'Weapon Class',
  },

  component: {
    manufacturer: 'Manufacturer',
    size: 'Size',
  },

  datetime: {
    formats: {
      default: "L MMMM y 'um' HH:mm z",
      iso: "yyyy-MM-dd'T'HH:mm:ss.SSSxxx",
    },
  },

  meta: {
    description:
      'FleetYards.net, Deine Datenbank für alle Information rund um die Schiffe & Stationen von “Star Citizen“.',
    keywords:
      'Star, Citizen, Spaceships, Raumschiffe, Weltraum, Ships, Fighter, Database, Squadron, 42, Star, Citizen, English, Chris, Roberts, Online, Game, Space, Simulation',
  },

  model: {
    afterburnerGroundSpeed: 'with Afterburner',
    afterburnerSpeed: 'Afterburner Speed',
    beam: 'Beam',
    cargo: 'Cargo',
    classification: 'Classification',
    crew: 'Crew',
    equipment: 'Equipment',
    focus: 'Fokus',
    groundSpeed: 'Ground Speed',
    hardpoints: 'Hardpoints',
    height: 'Height',
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

  number: {
    cargo: '%{count} SCU',
    distance: '%{count} m',
    format: {
      delimiter: '.',
      precision: 2,
      separator: ',',
      strip_insignificant_zeros: true,
    },
    people: {
      one: '%{count} person',
      other: '%{count} persons',
    },
    percent: '%{count} %',
    rateOfFire: '%{count} shots/min',
    rotation: '%{count} deg/s',
    speed: '%{count} m/s',
    weight: '%{count} t',
  },

  pagination: {
    gap: '&hellip;',
    next: 'Next Page',
    previous: 'Previous Page',
  },

  resources: {
    images: 'Images',
    models: 'Ships',
  },

  shop: {
    celestialObject: 'Location',
    location: '%{name} at %{location}',
    rentalPrice: '%{price} / day',
    station: 'Station',
    type: 'Type',
  },

  starsystem: {
    danger: 'Danger',
    economy: 'Economy',
    population: 'Population',
    size: 'Size',
    type: 'Type',
  },
  // title: {
  //   ...title,
  // },
  // headlines: {
  //   ...headlines,
  // },
  // sublines: {
  //   ...sublines,
  // },
  // nav: {
  //   ...nav,
  // },
  // labels: {
  //   ...labels,
  // },
  // placeholders: {
  //   ...placeholders,
  // },
  // actions: {
  //   ...actions,
  // },
  // texts: {
  //   ...texts,
  // },
  // messages: {
  //   ...messages,
  // },
  // validations: {
  //   ...validations,
  // },
  station: {
    classification: 'Klassifizierung',
    location: 'Ort',
    type: 'Typ',
  },
}
