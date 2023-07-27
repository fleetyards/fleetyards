export default {
  chart: {
    labels: {
      view: {
        one: "%{label}:<br><b>%{count}</b> View",
        other: "%{label}:<br><b>%{count}</b> Views",
      },
      ship: {
        one: "%{label}:<br><b>%{count}</b> Ship",
        other: "%{label}:<br><b>%{count}</b> Ships",
      },
      "ship-pie": {
        one: "%{label}:<br><b>%{count}</b> Ship (%{percentage} %)",
        other: "%{label}:<br><b>%{count}</b> Ships (%{percentage} %)",
      },
      "component-pie": {
        one: "%{label}:<br><b>%{count}</b> Component (%{percentage} %)",
        other: "%{label}:<br><b>%{count}</b> Components (%{percentage} %)",
      },
      user: {
        one: "%{label}:<br><b>%{count}</b> User",
        other: "%{label}:<br><b>%{count}</b> Users",
      },
      visit: {
        one: "%{label}:<br><b>%{count}</b> Visit",
        other: "%{label}:<br><b>%{count}</b> Visits",
      },
    },
  },
};
