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
    fairchanceact: 'Fair Chance Act?',
    population: 'Population',
    economy: 'Économie',
    danger: 'Danger'
  },
  starsystem: {
    type: 'Type',
    size: 'Taille',
    population: 'Population',
    economy: 'Économie',
    danger: 'Danger'
  },
  shop: {
    type: 'Type',
    celestialObject: 'Emplacement',
    station: 'Station',
    location: '%{name} à %{location}',
    refineryTerminal: 'Terminal de raffinerie'
  },
  commodityItem: {
    grade: 'Niveau',
    type: 'Type',
    itemType: 'Type de l\'article',
    itemClass: 'Item Class',
    weaponClass: 'Classe de l\'arme',
    size: 'Taille',
    range: 'Portée',
    damageReduction: 'Réduction de dégâts',
    rateOfFire: 'Cadence de Tir',
    extras: 'Informations complémentaires',
    location: 'Lieu',
    slot: 'Emplacement',
    storage: 'Stockage',
    shop: 'Points de vente',
    unconfirmed: 'L\'article n\'est pas confirmé',
    manufacturer: 'Fabricant'
  },
  shopCommodity: {
    listedAt: 'Listé à',
    soldAt: 'Vendu à',
    boughtAt: 'Acheté à'
  },
  resources: {
    models: 'Vaisseaux',
    images: 'Images'
  },
  pagination: {
    previous: 'Page précédente',
    next: 'Page suivante',
    gap: '&hellip;'
  },
  datetime: {
    formats: {
      default: 'd MMMM y \'à\' HH:mm z',
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
    rateOfFire: '%{count} tirs/min',
    rotation: '%{count} deg/s',
    cargo: '%{count} SCU',
    fuel: '%{count}',
    ships: {
      one: '%{count} vaisseau',
      other: '%{count} vaisseaux'
    },
    people: {
      one: '%{count} personne',
      other: '%{count} personnes'
    }
  }
};