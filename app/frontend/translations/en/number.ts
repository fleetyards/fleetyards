export default {
  format: {
    precision: 2,
    strip_insignificant_zeros: true,
    delimiter: ".",
    separator: ",",
  },
  units: {
    au: "AU",
    uec: "aUEC",
    uecPerUnit: "aUEC / Unit",
  },
  percent: "%{count} %",
  distance: "%{count} m",
  weight: "%{count} t",
  speed: "%{count} m/s",
  seconds: "%{count} s",
  rateOfFire: "%{count} shots/min",
  rotation: "%{count} deg/s",
  cargo: "%{count} SCU",
  fuel: "%{count}",
  ships: {
    one: "%{count} ship",
    other: "%{count} ships",
  },
  people: {
    one: "%{count} person",
    other: "%{count} persons",
  },
};
