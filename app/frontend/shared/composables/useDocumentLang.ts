import { useI18nStore } from "@/shared/stores/i18n";

// The server renders `lang="en"` whatever the reader chose. Left that way, a
// browser offers to translate a page already in the reader's language, and a
// translator rewriting the DOM breaks every later patch Vue makes to it.
export const useDocumentLang = () => {
  const i18nStore = useI18nStore();

  watchEffect(() => {
    document.documentElement.lang = i18nStore.locale || "en";
  });
};
