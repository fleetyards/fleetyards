import type { Config } from "tailwindcss";
import defaultTheme from "tailwindcss/defaultTheme";
import colors from "tailwindcss/colors";
import formsPlugin from "@tailwindcss/forms";
import aspectRatioPlugin from "@tailwindcss/aspect-ratio";
import typographyPlugin from "@tailwindcss/typography";
import containerQueriesPlugin from "@tailwindcss/container-queries";
import safeAreaPlugin from "tailwindcss-safe-area";

export default {
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
    formsPlugin,
    aspectRatioPlugin,
    typographyPlugin,
    containerQueriesPlugin,
    safeAreaPlugin,
  ],
} satisfies Config;
