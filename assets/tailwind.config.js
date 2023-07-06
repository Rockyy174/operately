// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");

module.exports = {
  content: ["./js/**/*.js", "./js/**/*.tsx", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        brand: {
          1: "#3185FF",
          2: "#E3F2FF",
        },
        dark: {
          // original
          1: "rgba(30,30,34,1)",
          2: "rgba(35,35,39,1)",
          3: "rgba(43,45,49,1)",
          4: "rgba(49,51,56,1)",
          5: "rgba(60,60,64,1)",
          6: "rgba(65,65,69,1)",
          7: "rgba(73,75,79,1)",
          8: "rgba(79,81,86,1)",

          // /* Lighter Shades */
          // rgba(60,60,64,1)
          // rgba(65,65,69,1)
          // rgba(73,75,79,1)
          // rgba(79,81,86,1)

          // /* Even Lighter Shades */
          // rgba(90,90,94,1)
          // rgba(95,95,99,1)
          // rgba(103,105,109,1)
          // rgba(109,111,116,1)

          // /* Lightest Shades */
          // rgba(120,120,124,1)
          // rgba(125,125,129,1)
          // rgba(133,135,139,1)
          // rgba(139,141,146,1)

          // 1: "#171020",
          // 2: "#191931",
          // 3: "#1e223d",
          // 4: "#222b48",
          // 5: "#273250",

          // blue gray
          // 0: "#263238",
          // 1: "#37474f",
          // 2: "#455a64",
          // 3: "#546e7a",
          // 4: "#607d8b",
          // 5: "#78909c",
          // 6: "#90a4ae",
          // 7: "#b0bec5",
          // 8: "#cfd8dc",
          // 9: "#eceff1",
        },

        shade: {
          1: "rgba(255,255,255,0.05)",
          2: "rgba(255,255,255,0.1)",
          3: "rgba(255,255,255,0.2)",
        },

        white: {
          1: "rgba(255,255,255,1.00)",
          2: "rgba(255,255,255,0.50)",
          3: "rgba(255,255,255,0.25)",
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
    function ({ addBase, theme }) {
      function extractColorVars(colorObj, colorGroup = "") {
        return Object.keys(colorObj).reduce((vars, colorKey) => {
          const value = colorObj[colorKey];

          const newVars =
            typeof value === "string"
              ? { [`--color${colorGroup}-${colorKey}`]: value }
              : extractColorVars(value, `-${colorKey}`);

          return { ...vars, ...newVars };
        }, {});
      }

      addBase({
        ":root": extractColorVars(theme("colors")),
      });
    },
  ],
};
