import translations from "@/translations";
import { useI18nStore } from "@/shared/stores/i18n";

// The server renders `lang="en"` whatever the reader chose. Left that way, a
// browser offers to translate a page already in the reader's language, and a
// translator rewriting the DOM breaks every later patch Vue makes to it.
//
// The stored locale comes from the browser and may have no translations, in
// which case the page falls back to English and must say so.
export const useDocumentLang = () => {
  const i18nStore = useI18nStore();

  watchEffect(() => {
    const locale = i18nStore.locale;

    document.documentElement.lang =
      locale && locale in translations ? locale : "en";
  });
};
