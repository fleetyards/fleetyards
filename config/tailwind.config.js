const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/frontend/**/*.{js,vue}",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: "#428bca",
          primaryDark: "#3071a9",
          grayBg: "#272B30",
          grayBgDark: "#1f1f1f",
          grayBorder: "#1e2226",
        },
        "litepie-primary": colors.sky, // color system for light mode
        "litepie-secondary": colors.gray, // color system for dark mode
        "vtd-primary": colors.sky, // Light mode Datepicker color
        "vtd-secondary": colors.gray, // Dark mode Datepicker color
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
        hero: ["Orbitron", "Inter var", ...defaultTheme.fontFamily.sans],
      },
      borderWidth: {
        3: "3px",
        5: "5px",
      },
      borderRadius: {
        panel: "1.25rem",
        button: "0.625rem;",
      },
      height: {
        "3px": "3px",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
    require("tailwindcss-safe-area"),
  ],
};
