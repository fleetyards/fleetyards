import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { SupportProgress } from "@/services/fyApi";

const progress = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", () => ({
  useSupportersProgress: () => ({ data: progress }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useCurrencyFormat", () => ({
  useCurrencyFormat: () => ({
    formatCents: (cents: number, currency: string) => `${cents} ${currency}`,
  }),
}));

import Component from "./index.vue";

const RouterLinkStub = {
  props: ["to"],
  template: '<a :href="to.params.username"><slot /></a>',
};

const mountWith = (
  contributions: SupportProgress["contributions"],
  props: { compact?: boolean } = {},
) => {
  progress.value = {
    monthlyTotal: { amountCents: 1000, currency: "EUR" },
    contributions,
  } satisfies SupportProgress;

  return mount(Component, {
    props,
    global: {
      stubs: { "router-link": RouterLinkStub, ProgressBar: true },
      directives: { tooltip: () => {} },
    },
  });
};

const supporter = (
  attributes: Partial<SupportProgress["contributions"][number]>,
) => ({
  displayName: "Alice",
  amountCents: 500,
  currency: "EUR",
  recurring: false,
  ...attributes,
});

describe("SupportProgress", () => {
  it("links a supporter that carries a username to their hangar", () => {
    const wrapper = mountWith([
      supporter({ displayName: "linked", username: "linked" }),
    ]);

    const link = wrapper.get(".support-progress__thanks__item a");

    expect(link.text()).toBe("linked");
    expect(link.attributes("href")).toBe("linked");
  });

  it("renders an unlinked supporter as plain text", () => {
    const wrapper = mountWith([supporter({ displayName: "Dora" })]);

    expect(wrapper.find(".support-progress__thanks__item a").exists()).toBe(
      false,
    );
    expect(wrapper.get(".support-progress__thanks__item").text()).toContain(
      "Dora",
    );
  });

  it("never links an anonymous supporter", () => {
    // The payload withholds `username` for anonymous rows, so there is nothing
    // to point at even though the entry is listed.
    const wrapper = mountWith([supporter({ displayName: "Anonymous" })]);

    expect(wrapper.find(".support-progress__thanks__item a").exists()).toBe(
      false,
    );
  });

  it("omits the supporter list in compact mode", () => {
    const wrapper = mountWith([supporter({ username: "linked" })], {
      compact: true,
    });

    expect(wrapper.find(".support-progress__thanks").exists()).toBe(false);
  });

  it("omits the supporter list when nobody contributed", () => {
    const wrapper = mountWith([]);

    expect(wrapper.find(".support-progress__thanks").exists()).toBe(false);
  });
});
