import { defineStore } from "pinia";

type I18nState = {
  locale: string;
};

const navigatorLocale = navigator.language.split("-")[0];

export const useI18nStore = defineStore("i18n", {
  state: (): I18nState => ({
    locale: navigatorLocale || "en",
  }),
  persist: true,
});
