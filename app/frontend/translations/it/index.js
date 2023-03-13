export default {
  app: 'FleetYards.net',
  meta: {
    description: 'FleetYards.net, il tuo database per tutte le informazioni relative alle navi di “Star Citizen“.',
    keywords: 'Star Citizen, Astronavi, Navi, Caccia, Database, Squadron, 42, Star, Citizen, Italiano, Chris, Roberts, Online, Gioco, Spazio, Simulazione'
  },
  station: {
    type: 'Tipo',
    location: 'Posizione',
    classification: 'Classificazione',
    habitable: 'Abitabile?',
    refinery: 'Stazione Di Raffineria',
    cargoHub: 'Cargo Hub'
  },
  model: {
    focus: 'Focus',
    classification: 'Classificazione',
    size: 'Dimensione',
    beam: 'Raggio',
    cargo: 'Carico',
    netCargo: 'Carico con Rover/Snub',
    crew: 'Equipaggio',
    speed: 'Velocità',
    minCrew: 'min. Equipaggio',
    maxCrew: 'max. Equipaggio',
    scmSpeed: 'Velocità SCM',
    afterburnerSpeed: 'Velocità Afterburner',
    groundSpeed: 'Velocità a Terra',
    afterburnerGroundSpeed: 'con Afterburner',
    pitchMax: 'Beccheggio Massimo',
    yawMax: 'Imbardata Massima',
    rollMax: 'Rollio Massimo',
    price: 'Prezzo',
    pledgePrice: 'Prezzo del Pledge',
    xaxisAcceleration: 'Asse X',
    yaxisAcceleration: 'Asse Y',
    zaxisAcceleration: 'Asse Z',
    quantumFuelTankSize: 'Quantum Fuel',
    hydrogenFuelTankSize: 'Carburante',
    height: 'Altezza',
    length: 'Lunghezza',
    mass: 'Massa',
    manufacturer: 'Produttore',
    hardpoints: 'Hardpoints',
    weapons: 'Armamenti',
    equipment: 'Equipaggiamento',
    variants: 'Varianti',
    maxUpgrades: 'Upgrades',
    productionStatus: 'Stato Della Produzione',
    propulsion: 'Propulsione',
    ordnance: 'Ordinanza',
    modular: 'Modulare',
    soldAt: 'Venduto a?',
    rentalAt: 'Noleggiato a?',
    lastUpdatedAt: 'Ultimo aggiornamento?'
  },
  component: {
    manufacturer: 'Produttore',
    size: 'Dimensione'
  },
  celestialObject: {
    type: 'Tipo',
    subType: 'Sottotipo',
    habitable: 'Abitabile?',
    fairchanceakt: 'Fair Chance Act?',
    population: 'Popolazione',
    economy: 'Economia',
    danger: 'Pericolo'
  },
  starsystem: {
    type: 'Tipo',
    size: 'Dimensione',
    population: 'Popolazione',
    economy: 'Economia',
    danger: 'Pericolo'
  },
  shop: {
    type: 'Tipo',
    celestialObject: 'Posizione',
    station: 'Stazione',
    location: '%{name} in %{location}',
    refineryTerminal: 'Terminale Di Raffinazione'
  },
  commodityItem: {
    grade: 'Grado',
    type: 'Tipo',
    itemType: 'Tipo di Elemento',
    itemClass: 'Classe Elemento',
    weaponClass: 'Classe D\'Arma',
    size: 'Dimensione',
    range: 'Gittata',
    damageReduction: 'Riduzione del Danno',
    rateOfFire: 'Rateo di Fuoco',
    extras: 'Ulteriori Informazioni',
    location: 'Posizione',
    slot: 'Slot',
    storage: 'Storage',
    shop: 'Negozio',
    unconfirmed: 'Elemento non confermato',
    manufacturer: 'Produttore'
  },
  shopCommodity: {
    listedAt: 'Elencato a',
    soldAt: 'Venduto a',
    boughtAt: 'Acquistato a'
  },
  resources: {
    models: 'Navi',
    images: 'Immagini'
  },
  pagination: {
    previous: 'Pagina precedente',
    next: 'Pagina successiva',
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
    rateOfFire: '%{count} spari/min',
    rotation: '%{count} deg/s',
    cargo: '%{count} SCU',
    fuel: '%{count}',
    ships: {
      one: '%{count} nave',
      other: '%{count} navi'
    },
    people: {
      one: '%{count} persona',
      other: '%{count} persone'
    }
  }
};