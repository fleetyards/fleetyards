import { defineStore } from "pinia";

type I18nState = {
  locale: string;
};

export const useI18nStore = defineStore("i18n", {
  state: (): I18nState => ({
    locale: "en",
  }),
  persist: true,
});
