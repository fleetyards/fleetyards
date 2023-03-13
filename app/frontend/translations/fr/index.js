export default {
  app: 'FleetYards.net',
  meta: {
    description: 'FleetYards.net, votre base de données pour toutes les informations relatives aux vaisseaux de « Star Citizen ».',
    keywords: 'Star Citizen, vaisseaux spatiaux, vaisseaux, Fighter, Database, Squadron, 42, Star, Citizen, Français, Chris, Roberts, Online, Game, Espace, Simulation'
  },
  station: {
    type: 'Type',
    location: 'Lieu',
    classification: 'Classification',
    habitable: 'Habitable?',
    refinery: 'Raffinerie',
    cargoHub: 'Centre de marchandise'
  },
  model: {
    focus: 'Domaine',
    classification: 'Classification',
    size: 'Taille',
    beam: 'Rayon',
    cargo: 'Soute',
    netCargo: 'Soute avec véhicule',
    crew: 'Équipage',
    speed: 'Vitesse',
    minCrew: 'Équipage min.',
    maxCrew: 'Équipage max.',
    scmSpeed: 'Vitesse SCM',
    afterburnerSpeed: 'Vitesse Afterburner',
    groundSpeed: 'Vitesse terrestre',
    afterburnerGroundSpeed: 'avec Afterburner',
    pitchMax: 'Pitch max',
    yawMax: 'Yaw max',
    rollMax: 'Roll max',
    price: 'Prix',
    pledgePrice: 'Prix réel',
    xaxisAcceleration: 'Axe X',
    yaxisAcceleration: 'Axe Y',
    zaxisAcceleration: 'Axe Z',
    quantumFuelTankSize: 'Carburant Quantum',
    hydrogenFuelTankSize: 'Carburant',
    height: 'Hauteur',
    length: 'Longueur',
    mass: 'Masse',
    manufacturer: 'Fabricant',
    hardpoints: 'Hardpoints',
    weapons: 'Armes',
    equipment: 'Équipement',
    variants: 'Variantes',
    maxUpgrades: 'Améliorations',
    productionStatus: 'Statut du produit',
    propulsion: 'Propulsion',
    ordnance: 'Munition',
    modular: 'Modulaire',
    soldAt: 'Vendu à?',
    rentalAt: 'Location à ?',
    lastUpdatedAt: 'Dernière mise à jour le ?'
  },
  component: {
    manufacturer: 'Fabricant',
    size: 'Taille'
  },
  celestialObject: {
    type: 'Type',
    subType: 'Sous-type',
    habitable: 'Habitable?',
    fairchanceakt: 'Fair Chance Akt?',
    population: 'Population',
    economy: 'Economy',
    danger: 'Danger'
  },
  starsystem: {
    type: 'Type',
    size: 'Size',
    population: 'Population',
    economy: 'Economy',
    danger: 'Danger'
  },
  shop: {
    type: 'Type',
    celestialObject: 'Location',
    station: 'Station',
    location: '%{name} at %{location}',
    refineryTerminal: 'Refinery Terminal'
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
    extras: 'Additional Info',
    location: 'Location',
    slot: 'Slot',
    storage: 'Storage',
    shop: 'Shop',
    unconfirmed: 'Item is unconfirmed',
    manufacturer: 'Manufacturer'
  },
  shopCommodity: {
    listedAt: 'Listed at',
    soldAt: 'Sold at',
    boughtAt: 'Bought at'
  },
  resources: {
    models: 'Ships',
    images: 'Images'
  },
  pagination: {
    previous: 'Previous Page',
    next: 'Next Page',
    gap: '&hellip;'
  },
  datetime: {
    formats: {
      default: 'd MMMM y \'at\' HH:mm z',
      iso: 'yyyy-MM-dd\'T\'HH:mm:ss.SSSxxx'
    }
  },
  number: {
    format: {
      precision: 2,
      strip_insignificant_zeros: true,
      delimiter: '.',
      separator: ','
    },
    percent: '%{count} %',
    distance: '%{count} m',
    weight: '%{count} t',
    speed: '%{count} m/s',
    rateOfFire: '%{count} shots/min',
    rotation: '%{count} deg/s',
    cargo: '%{count} SCU',
    fuel: '%{count}',
    ships: {
      one: '%{count} ship',
      other: '%{count} ships'
    },
    people: {
      one: '%{count} person',
      other: '%{count} persons'
    }
  }
};