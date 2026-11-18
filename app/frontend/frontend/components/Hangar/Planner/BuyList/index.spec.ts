import { afterEach, describe, expect, it } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  clearSyncExtensionOverride,
  overrideSyncExtension,
} from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  FleetyardsSyncCartErrorEnum,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";
import {
  HangarPlanCartItemKindEnum,
  HangarPlanPurchaseKindEnum,
  HangarPlanSlotStateEnum,
  type HangarPlanModel,
  type HangarPlanPurchase,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 100,
});

const slot = (id: string, label: string): HangarPlanSlot => ({
  id,
  label,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  starts: [],
  candidates: [],
});

const purchase = (
  attrs: Partial<HangarPlanPurchase> & Pick<HangarPlanPurchase, "kind">,
): HangarPlanPurchase => ({
  fromModel: null,
  model: null,
  name: "",
  price: 0,
  quantity: 1,
  tokenCount: 0,
  slotIds: [],
  notOnSale: false,
  cartItems: [],
  ...attrs,
});

type CartRequest = { items: { id: string; kind: string }[] };

// Answers like an extension that can fill the cart, with what `answer` says
// for each item, and keeps what each request asked for.
const stubExtension = (
  answer: (id: string) => { ok: boolean; error?: FleetyardsSyncCartErrorEnum },
  actions = [FleetyardsSyncAction.ADD_TO_CART],
) => {
  const requests: CartRequest[] = [];
  const stub = async (
    action: FleetyardsSyncAction,
    params: Record<string, unknown> = {},
  ): Promise<FleetyardsSyncMessage> => {
    if (action === FleetyardsSyncAction.HEALTH) {
      return { action, code: 200, payload: { actions } };
    }

    const request = params as CartRequest;
    requests.push(request);

    return {
      action,
      code: 200,
      payload: {
        results: request.items.map(({ id }) => ({ id, ...answer(id) })),
      },
    };
  };
  overrideSyncExtension(stub);
  installed.push(stub);

  return requests;
};

const installed: Parameters<typeof overrideSyncExtension>[0][] = [];

afterEach(() => {
  installed.splice(0).forEach(clearSyncExtensionOverride);
});

const sku = (skuId: number) => ({
  kind: HangarPlanCartItemKindEnum.SKU,
  skuId,
});
const upgrade = (fromShipId: number, toShipId: number) => ({
  kind: HangarPlanCartItemKindEnum.UPGRADE,
  fromShipId,
  toShipId,
  toSkuId: toShipId * 100,
});
const buyback = (pledgeId: string) => ({
  kind: HangarPlanCartItemKindEnum.BUYBACK,
  pledgeId,
});

const avenger = model("Avenger");
const cutlass = model("Cutlass");
const slots = [slot("hauler", "Hauler"), slot("miner", "Miner")];

describe("HangarPlannerBuyList", () => {
  it("says when there is nothing to buy", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { purchases: [], slots },
    });

    expect(wrapper.text()).toContain("Nothing to buy yet");
  });

  it("lists each purchase under its kind with the slots it is for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.CCU,
            fromModel: avenger,
            model: cutlass,
            name: "Avenger → Cutlass",
            price: 60,
            quantity: 2,
            slotIds: ["hauler", "miner"],
            notOnSale: true,
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.BUYBACK,
            model: cutlass,
            name: "Cutlass",
            price: 90,
            tokenCount: 1,
            slotIds: ["hauler"],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.EXTRA,
            name: "Cutlass - Ghoul",
            price: null,
            slotIds: ["miner"],
          }),
        ],
      },
    });

    const ccus = wrapper.find('[data-test="hangar-plan-buy-list-ccu"]');
    expect(ccus.text()).toContain("Upgrades from the store");
    expect(ccus.text()).toContain("Avenger");
    expect(ccus.text()).toContain("×2");
    expect(ccus.text()).toContain("$60");
    expect(ccus.text()).toContain("Hauler, Miner");
    expect(ccus.text()).toContain("Not on sale right now");

    const buybacks = wrapper.find('[data-test="hangar-plan-buy-list-buyback"]');
    expect(buybacks.text()).toContain("1 paid with a buy-back token");

    const extras = wrapper.find('[data-test="hangar-plan-buy-list-extra"]');
    expect(extras.text()).toContain("Cutlass - Ghoul");
    expect(extras.text()).toContain("Unknown");
  });

  it("offers no cart without an extension that can fill one", async () => {
    stubExtension(() => ({ ok: true }), [FleetyardsSyncAction.SYNC]);

    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: cutlass,
            cartItems: [sku(1)],
          }),
        ],
      },
    });
    await flushPromises();

    expect(wrapper.text()).not.toContain("Add to RSI cart");
  });

  it("adds a row to the RSI cart and says it is there", async () => {
    const requests = stubExtension(() => ({ ok: true }));

    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: cutlass,
            quantity: 2,
            cartItems: [sku(17402), sku(17402)],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: avenger,
            cartItems: [],
          }),
        ],
      },
    });
    await flushPromises();

    expect(
      wrapper.findAll('[data-test^="hangar-plan-buy-list-add-ship:"]'),
    ).toHaveLength(1);

    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-ship:0"]')
      .trigger("click");
    await flushPromises();

    expect(requests).toEqual([
      {
        items: [
          { id: "sku-17402:0", kind: "sku", skuId: 17402 },
          { id: "sku-17402:1", kind: "sku", skuId: 17402 },
        ],
      },
    ]);
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-status-ship:0"]').text(),
    ).toBe("In your RSI cart");
    expect(
      wrapper
        .find('[data-test="hangar-plan-buy-list-open-cart"]')
        .attributes("href"),
    ).toBe("https://robertsspaceindustries.com/en/store/pledge/cart");
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-add-ship:0"]').exists(),
    ).toBe(false);
  });

  it("never sends what is already in the cart again", async () => {
    const requests = stubExtension((id) =>
      id.startsWith("sku-2:")
        ? { ok: false, error: FleetyardsSyncCartErrorEnum.UNAVAILABLE }
        : { ok: true },
    );

    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: cutlass,
            cartItems: [sku(1)],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: avenger,
            cartItems: [sku(2)],
          }),
        ],
      },
    });
    await flushPromises();

    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-ship:0"]')
      .trigger("click");
    await flushPromises();
    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-all-ship"]')
      .trigger("click");
    await flushPromises();

    expect(
      requests.map((request) => request.items.map((item) => item.id)),
    ).toEqual([["sku-1:0"], ["sku-2:0"]]);
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-add-all-ship"]').exists(),
    ).toBe(true);
  });

  it("adds a whole group, and says why RSI refused an item", async () => {
    const requests = stubExtension((id) =>
      id.startsWith("upgrade-2-")
        ? { ok: false, error: FleetyardsSyncCartErrorEnum.UNAVAILABLE }
        : { ok: true },
    );

    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.CCU,
            fromModel: avenger,
            model: cutlass,
            cartItems: [upgrade(1, 3)],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.CCU,
            fromModel: cutlass,
            model: avenger,
            cartItems: [upgrade(2, 4)],
          }),
        ],
      },
    });
    await flushPromises();

    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-all-ccu"]')
      .trigger("click");
    await flushPromises();

    expect(requests[0]?.items.map((item) => item.id)).toEqual([
      "upgrade-1-3-300:0",
      "upgrade-2-4-400:0",
    ]);
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-status-ccu:0"]').text(),
    ).toBe("In your RSI cart");
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-status-ccu:1"]').text(),
    ).toBe("RSI does not sell this right now.");
  });

  it("puts buy-backs in one at a time, and forgets what they pushed out of the cart", async () => {
    const requests = stubExtension(() => ({ ok: true }));

    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots,
        purchases: [
          purchase({
            kind: HangarPlanPurchaseKindEnum.SHIP,
            model: avenger,
            cartItems: [sku(1)],
          }),
          purchase({
            kind: HangarPlanPurchaseKindEnum.BUYBACK,
            model: cutlass,
            quantity: 2,
            cartItems: [buyback("115575665"), buyback("115575666")],
          }),
        ],
      },
    });
    await flushPromises();

    const buybacks = wrapper.find('[data-test="hangar-plan-buy-list-buyback"]');
    expect(
      buybacks
        .find('[data-test="hangar-plan-buy-list-buyback-alone"]')
        .exists(),
    ).toBe(true);
    expect(
      buybacks
        .find('[data-test="hangar-plan-buy-list-add-all-buyback"]')
        .exists(),
    ).toBe(false);

    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-ship:0"]')
      .trigger("click");
    await flushPromises();
    await wrapper
      .find('[data-test="hangar-plan-buy-list-add-buyback:0-1"]')
      .trigger("click");
    await flushPromises();

    expect(requests[1]?.items).toEqual([
      { id: "buyback-115575666:1", kind: "buyback", pledgeId: "115575666" },
    ]);
    expect(
      wrapper.find('[data-test="hangar-plan-buy-list-status-ship:0"]').exists(),
    ).toBe(false);
    expect(
      wrapper
        .find('[data-test="hangar-plan-buy-list-status-buyback:0"]')
        .text(),
    ).toBe("In your RSI cart");
  });
});
