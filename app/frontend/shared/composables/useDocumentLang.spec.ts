import { beforeEach, describe, expect, it } from "vitest";
import { nextTick } from "vue";
import { createPinia, setActivePinia } from "pinia";
import { useDocumentLang } from "./useDocumentLang";
import { useI18nStore } from "@/shared/stores/i18n";

describe("useDocumentLang", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    document.documentElement.lang = "en";
  });

  it("names the language the reader chose", () => {
    useI18nStore().locale = "fr";

    useDocumentLang();

    expect(document.documentElement.lang).toBe("fr");
  });

  it("follows a change of language", async () => {
    const store = useI18nStore();
    store.locale = "de";
    useDocumentLang();

    store.locale = "it";
    await nextTick();

    expect(document.documentElement.lang).toBe("it");
  });
});
