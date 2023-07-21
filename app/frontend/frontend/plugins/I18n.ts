import { createI18n } from "vue-i18n";

const i18n = createI18n({
  legacy: false,
  locale: "en",
  messages: {
    en: {
      "Hello World": "Hello World",
    },
  },
});

export default i18n;
