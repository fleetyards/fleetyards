import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { TourCurrencyEnum } from "@/services/fyApi";
import { useI18nStore } from "@/shared/stores/i18n";
import {
  providePayoutCurrency,
  usePayoutCurrency,
  usePayoutCurrencyOptions,
} from "@/frontend/composables/usePayoutCurrency";

const wrappers: Array<{ unmount: () => void }> = [];

const format = async (
  value: number,
  currency: TourCurrencyEnum | undefined,
  locale = "en",
) => {
  let result = "";

  const Child = defineComponent({
    setup() {
      result = usePayoutCurrency().formatAmount(value);
      return () => h("span");
    },
  });

  const Parent = defineComponent({
    setup() {
      useI18nStore().locale = locale;
      providePayoutCurrency(() => currency);
      return () => h(Child);
    },
  });

  wrappers.push(await mountWithDefaults(Parent, {}));

  return result.replace(/<[^>]+>/g, "").replace(/\s/g, " ");
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }

  useI18nStore().locale = "en";
});

describe("usePayoutCurrency", () => {
  it("counts a ledger without a currency in aUEC", async () => {
    expect(await format(1500, undefined)).toContain("aUEC");
  });

  it("places the symbol the way the reader's locale does", async () => {
    expect(await format(1500.5, TourCurrencyEnum.EUR, "de")).toBe("1.500,50 €");
    expect(await format(1500.5, TourCurrencyEnum.USD, "en")).toBe("$1,500.50");
  });

  it("dims the currency like the aUEC unit", async () => {
    let markup = "";

    const Child = defineComponent({
      setup() {
        markup = usePayoutCurrency(TourCurrencyEnum.EUR).formatAmount(10);
        return () => h("span");
      },
    });

    wrappers.push(await mountWithDefaults(Child, {}));

    expect(markup).toContain('<span class="text-muted">€</span>');
  });

  it("renders nothing as a dash, like toUEC", async () => {
    expect(await format(0, TourCurrencyEnum.EUR)).toBe("-");
  });

  it("lists aUEC first, ahead of the real currencies", async () => {
    let values: string[] = [];

    const Child = defineComponent({
      setup() {
        values = usePayoutCurrencyOptions().value.map((option) => option.value);
        return () => h("span");
      },
    });

    wrappers.push(await mountWithDefaults(Child, {}));

    expect(values[0]).toBe(TourCurrencyEnum.AUEC);
    expect(values.slice(1, 3)).toEqual([
      TourCurrencyEnum.AUD,
      TourCurrencyEnum.BRL,
    ]);
  });
});
