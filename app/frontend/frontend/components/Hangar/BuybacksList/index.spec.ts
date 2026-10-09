import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type BuybackPledge } from "@/services/fyApi";
import Component from "./index.vue";

const destroyBuyback = vi.fn();
const invalidateQueries = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useDestroyHangarBuyback: () => ({
      mutateAsync: destroyBuyback,
      isPending: ref(false),
    }),
  };
});

vi.mock("@tanstack/vue-query", async () => {
  const actual = await vi.importActual<Record<string, unknown>>(
    "@tanstack/vue-query",
  );

  return { ...actual, useQueryClient: () => ({ invalidateQueries }) };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert,
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

const routerOnBuybacks = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/hangar/buybacks",
        name: "hangar-buybacks",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "hangar-buybacks", query: { nameCont: "cut" } });
  await router.isReady();

  return router;
};

const buyback = (attrs: Partial<BuybackPledge> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    rsiPledgeId: "1000001",
    kind: "ship",
    name: "Standalone Ship - Cutter plus Groundswell Paint",
    upgraded: false,
    available: true,
    lifetimeInsurance: false,
    reclaimedOn: "2023-11-26",
    contained: "Cutter Scout and 3 items",
    createdAt: "2026-10-07T12:00:00Z",
    updatedAt: "2026-10-07T12:00:00Z",
    ...attrs,
  }) as BuybackPledge;

const mount = async (buybacks: BuybackPledge[], emptyVisible = false) =>
  mountWithDefaults(Component, {
    props: { buybacks, emptyVisible },
    plugins: [await routerOnBuybacks()],
  });

describe("Hangar/BuybacksList", () => {
  beforeEach(() => {
    window.RSI_ENDPOINT = "https://robertsspaceindustries.com";
    destroyBuyback.mockReset().mockResolvedValue(undefined);
    invalidateQueries.mockReset();
    displayAlert.mockReset();
  });

  // A pledge bought back on RSI leaves its list; removing the one row saves
  // re-syncing all of them.
  it("removes a single pledge and reloads the list", async () => {
    const wrapper = await mount([buyback()]);

    await wrapper.find('[data-test="buyback-remove"]').trigger("click");
    await flushPromises();

    expect(destroyBuyback).toHaveBeenCalledWith({
      id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    });
    expect(invalidateQueries).toHaveBeenCalledWith({
      queryKey: ["hangar", "buybacks"],
    });
    expect(displayAlert).not.toHaveBeenCalled();
  });

  it("says so when the pledge could not be removed", async () => {
    destroyBuyback.mockRejectedValue(new Error("nope"));
    const wrapper = await mount([buyback()]);

    await wrapper.find('[data-test="buyback-remove"]').trigger("click");
    await flushPromises();

    expect(invalidateQueries).not.toHaveBeenCalled();
    expect(displayAlert).toHaveBeenCalled();
  });

  it("offers removal for a pledge RSI no longer offers", async () => {
    const wrapper = await mount([buyback({ available: false })]);

    expect(wrapper.find('[data-test="buyback-rsi-link"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="buyback-remove"]').exists()).toBe(true);
  });

  it("shows the pledge with what it contains", async () => {
    const wrapper = await mount([buyback()]);

    expect(wrapper.text()).toContain(
      "Standalone Ship - Cutter plus Groundswell Paint",
    );
    expect(wrapper.text()).toContain("Cutter Scout and 3 items");
    expect(wrapper.text()).toContain("26 Nov 2023");
  });

  // The kind is a filter like every other value on a row, and narrowing by it
  // keeps the search the reader already typed.
  it("links the kind to the list filtered by it", async () => {
    const wrapper = await mount([buyback({ kind: "upgrade" })]);

    const kindLink = wrapper
      .findAll("a")
      .find((link) => link.text() === "Upgrade");

    expect(kindLink?.attributes("href")).toContain("kindEq=upgrade");
    expect(kindLink?.attributes("href")).toContain("nameCont=cut");
  });

  it("marks an upgraded pledge", async () => {
    const wrapper = await mount([buyback({ upgraded: true })]);

    expect(wrapper.text()).toContain("Upgraded");
  });

  it("links a pledge to its buy-back on RSI", async () => {
    const wrapper = await mount([buyback()]);

    const link = wrapper.find("[data-test='buyback-rsi-link']");

    expect(link.attributes("href")).toBe(
      "https://robertsspaceindustries.com/pledge/buyback/1000001",
    );
    expect(link.attributes("target")).toBe("_blank");
  });

  // An upgrade's buy-back is a modal on RSI's list, with no page of its own.
  it("links an upgrade to RSI's buy-back list", async () => {
    const wrapper = await mount([buyback({ kind: "upgrade" })]);

    expect(
      wrapper.find("[data-test='buyback-rsi-link']").attributes("href"),
    ).toBe("https://robertsspaceindustries.com/account/buy-back-pledges");
  });

  it("shows the price in USD", async () => {
    const wrapper = await mount([buyback({ price: 100 })]);

    expect(wrapper.text()).toContain("$100.00");
  });

  it("shows the insurance", async () => {
    const wrapper = await mount([
      buyback({ insuranceMonths: 120 }),
      buyback({ id: "lti", lifetimeInsurance: true }),
    ]);

    expect(wrapper.text()).toContain("120 months");
    expect(wrapper.text()).toContain("LTI");
  });

  it("marks a pledge RSI no longer offers for buy-back", async () => {
    const wrapper = await mount([buyback({ available: false })]);

    expect(wrapper.text()).toContain("Not available");
    expect(wrapper.find("[data-test='buyback-rsi-link']").exists()).toBe(false);
  });

  it("shows the empty state", async () => {
    const wrapper = await mount([], true);

    expect(wrapper.find("[data-test='buyback-row']").exists()).toBe(false);
  });
});
