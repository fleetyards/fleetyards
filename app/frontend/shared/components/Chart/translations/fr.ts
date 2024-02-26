export default {
  chart: {
    labels: {
      view: {
        one: "%{label}:<br><b>%{count}</b> Vue",
        other: "%{label}:<br><b>%{count}</b> Vues",
      },
      ship: {
        one: "%{label}:<br><b>%{count}</b> Vaisseau",
        other: "%{label}:<br><b>%{count}</b> Vaisseaux",
      },
      "ship-pie": {
        one: "%{label}:<br><b>%{count}</b> Vaisseau (%{percentage} %)",
        other: "%{label}:<br><b>%{count}</b> Vaisseaux (%{percentage} %)",
      },
      "component-pie": {
        one: "%{label}:<br><b>%{count}</b> Composant (%{percentage} %)",
        other: "%{label}:<br><b>%{count}</b> Composants (%{percentage} %)",
      },
      user: {
        one: "%{label}:<br><b>%{count}</b> Utilisateur",
        other: "%{label}:<br><b>%{count}</b> Utilisateurs",
      },
      visit: {
        one: "%{label}:<br><b>%{count}</b> Visite",
        other: "%{label}:<br><b>%{count}</b> Visites",
      },
    },
  },
};
