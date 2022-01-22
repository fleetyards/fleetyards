const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#428bca',
          grayBackground: '#272B30',
          grayBorder: '#c8c8c8',
        },
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
        hero: ['Orbitron', 'Inter var', ...defaultTheme.fontFamily.sans],
      },
      borderWidth: {
        3: '3px',
        5: '5px',
      },
      borderRadius: {
        panel: '1.25rem',
        button: '0.625rem;',
      },
      height: {
        '3px': '3px',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
  ],
}
