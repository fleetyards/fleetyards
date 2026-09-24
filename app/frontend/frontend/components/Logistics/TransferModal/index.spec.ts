import { afterEach, describe, expect, it, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { VueQueryPlugin } from "@tanstack/vue-query";
import TransferModal from "./index.vue";

vi.mock("@/services/fyApi/services/fleet-members/fleet-members", () => ({
  fleetMembers: vi.fn().mockResolvedValue({ items: [] }),
}));
import { fleetMembers } from "@/services/fyApi/services/fleet-members/fleet-members";

const openContracts = { value: [] as { id: string; title: string }[] };

vi.mock("@/services/fyApi/services/contracts/contracts", async (original) => ({
  ...(await original<Record<string, unknown>>()),
  useFleetContracts: () => ({
    data: computed(() => ({ items: openContracts.value })),
  }),
}));
import type { InventoryStockPosition } from "@/services/fyApi";
import type { TransferTargetOption } from "./types";

const position = (
  overrides: Partial<InventoryStockPosition> = {},
): InventoryStockPosition =>
  ({
    id: "pos-1",
    slug: "titanium--commodity--scu",
    name: "Titanium",
    category: "commodity",
    unit: "scu",
    netQuantity: 96,
    entriesCount: 1,
    ...overrides,
  }) as InventoryStockPosition;

const immediateTarget: TransferTargetOption = {
  kind: "inventory",
  value: "inventory:other",
  label: "Locker",
  needsAnswer: false,
  payload: { inventoryId: "other" },
};

const pendingTarget: TransferTargetOption = {
  kind: "fleet",
  value: "fleet:crew",
  label: "Crew (fleet)",
  needsAnswer: true,
  payload: { recipientFleetSlug: "crew" },
};

// A wrapper left mounted keeps its pinia alive and the next test asserts
// against a second store, passing either way.
let wrapper: ReturnType<typeof mount> | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const build = async (
  positions: InventoryStockPosition[],
  targets: TransferTargetOption[] = [immediateTarget],
  onSend = vi.fn().mockResolvedValue(undefined),
  memberFleets: { value: string; label: string }[] = [],
  actingForFleet = false,
) => {
  wrapper = mount(TransferModal, {
    props: {
      source: { id: "src", name: "Caterpillar" },
      positions,
      targets,
      memberFleets,
      actingForFleet,
      onSend,
    },
    global: {
      plugins: [
        createTestingPinia({
          initialState: {
            user: { user: { id: 1, email: "", enabledFeatures: [] } },
          },
        }),
        VueQueryPlugin,
      ],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        Empty: { template: "<div class='empty' />" },
        BaseSelect: true,
      },
      directives: { Tooltip: {} },
    },
  });

  await flushPromises();

  return { wrapper, onSend };
};

describe("TransferModal", () => {
  it("offers only positions that hold something", async () => {
    await build([
      position(),
      position({ id: "pos-2", slug: "empty--commodity--scu", netQuantity: 0 }),
    ]);

    expect(
      wrapper!
        .find('[data-test="transfer-line-titanium--commodity--scu"]')
        .exists(),
    ).toBe(true);
    expect(
      wrapper!
        .find('[data-test="transfer-line-empty--commodity--scu"]')
        .exists(),
    ).toBe(false);
  });

  // The reader already chose these rows in the list, so they are going.
  it("starts every chosen line at its full quantity", async () => {
    const { onSend } = await build([position()]);

    await wrapper!.find('[data-test="transfer-submit"]').trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({
        sourceInventoryId: "src",
        lines: [{ positionId: "pos-1", quantity: 96 }],
        inventoryId: "other",
      }),
    );
  });

  // One position can arrive as several rows -- `current_stock` groups per
  // quality -- and they are one thing to move, at the sum of their amounts.
  it("collapses several quality rows of one position into one line", async () => {
    const { onSend } = await build([
      position({ netQuantity: 60 }),
      position({ netQuantity: 36 }),
    ]);

    expect(wrapper!.findAll('[data-test^="transfer-line-"]')).toHaveLength(1);

    await wrapper!.find('[data-test="transfer-submit"]').trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({
        lines: [{ positionId: "pos-1", quantity: 96 }],
      }),
    );
  });

  it("offers a reset only once the amount has moved off the maximum", async () => {
    await build([position()]);

    expect(
      wrapper!
        .find('[data-test="transfer-reset-titanium--commodity--scu"]')
        .exists(),
    ).toBe(false);

    await wrapper!.find('[data-test="input-quantity-pos-1"]').setValue("10");

    const reset = wrapper!.find(
      '[data-test="transfer-reset-titanium--commodity--scu"]',
    );

    expect(reset.exists()).toBe(true);

    await reset.trigger("click");

    expect(
      (
        wrapper!.find('[data-test="input-quantity-pos-1"]')
          .element as HTMLInputElement
      ).value,
    ).toBe("96");
  });

  // Trimming a bulk selection is removing a line; a single line has nothing to
  // trim down to, so it carries no remove.
  it("removes a line only when several are in play", async () => {
    const { onSend } = await build([
      position(),
      position({
        id: "pos-2",
        slug: "medpen--consumable--units",
        name: "Medpen",
        netQuantity: 5,
      }),
    ]);

    await wrapper!
      .find('[data-test="transfer-remove-medpen--consumable--units"]')
      .trigger("click");

    expect(
      wrapper!
        .find('[data-test="transfer-remove-titanium--commodity--scu"]')
        .exists(),
    ).toBe(false);

    await wrapper!.find('[data-test="transfer-submit"]').trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({
        lines: [{ positionId: "pos-1", quantity: 96 }],
      }),
    );
  });

  // All-or-nothing, the same rule the API applies.
  it("refuses to send when a line asks for more than the position holds", async () => {
    const { onSend } = await build([position()]);

    await wrapper!.find('[data-test="input-quantity-pos-1"]').setValue("500");

    expect(
      wrapper!
        .find('[data-test="transfer-over-stock-titanium--commodity--scu"]')
        .exists(),
    ).toBe(true);
    expect(
      wrapper!.find('[data-test="transfer-submit"]').attributes("disabled"),
    ).toBeDefined();

    await wrapper!.find('[data-test="transfer-submit"]').trigger("click");
    await flushPromises();

    expect(onSend).not.toHaveBeenCalled();
  });

  it("says so when the far end has to answer", async () => {
    await build([position()], [pendingTarget]);

    expect(wrapper!.find('[data-test="transfer-hint"]').exists()).toBe(true);
  });

  it("says nothing extra when the move happens on the spot", async () => {
    await build([position()], [immediateTarget]);

    expect(wrapper!.find('[data-test="transfer-hint"]').exists()).toBe(false);
  });

  // An option that disappears when its list comes back empty is unreadable:
  // "no fleet can receive this" and "there is no such thing" look the same.
  it("offers the fleet kind even when no fleet can receive", async () => {
    const { wrapper: w } = await build([position()], [immediateTarget]);

    expect(w.find('[data-test="transfer-target-kind"]').exists()).toBe(true);

    (w.vm as unknown as { targetKind?: string }).targetKind = "fleet";
    await w.vm.$nextTick();

    expect(w.find('[data-test="transfer-no-targets"]').exists()).toBe(true);
    expect(
      w.find('[data-test="transfer-submit"]').attributes("disabled"),
    ).toBeDefined();
  });

  it("offers a kind picker once there are both", async () => {
    await build([position()], [immediateTarget, pendingTarget]);

    expect(wrapper!.find('[data-test="transfer-target-kind"]').exists()).toBe(
      true,
    );
  });

  // `mine` is a split rather than a kind: separating the reader's own
  // inventories out only means something when the source belongs to a fleet.
  it("splits off the reader's own inventories only for a fleet", async () => {
    const kinds = (w: ReturnType<typeof mount>) =>
      (w.vm as unknown as { availableKinds: string[] }).availableKinds;

    const asPerson = await build([position()]);
    expect(kinds(asPerson.wrapper)).not.toContain("mine");
    asPerson.wrapper.unmount();

    const asFleet = await build(
      [position()],
      [immediateTarget],
      vi.fn(),
      [],
      true,
    );
    expect(kinds(asFleet.wrapper)).toContain("mine");
  });

  // The member search names the fleet in its path, so asking with no group
  // chosen requests the members of "".
  it("asks for nobody's members when there is no group to pick from", async () => {
    const { wrapper: w } = await build([position()], [], vi.fn(), []);

    (w.vm as unknown as { targetKind?: string }).targetKind = "user";
    await w.vm.$nextTick();
    await flushPromises();

    expect(w.find('[data-test="transfer-target"]').exists()).toBe(false);
    expect(w.find('[data-test="transfer-no-targets"]').exists()).toBe(true);
    expect(fleetMembers).not.toHaveBeenCalled();
  });

  // People are reached through a fleet, so the kind is offered whenever the
  // reader is in one -- there is no flat list of people that could be empty.
  // The person list lives in the select, so nothing in `targetOptions` reacts
  // to a fleet change: a stale username would send the goods to the wrong
  // person entirely.
  it("clears the chosen person when the fleet they were picked from changes", async () => {
    const { wrapper: w } = await build([position()], [], vi.fn(), [
      { value: "crew", label: "Crew" },
      { value: "other", label: "Other" },
    ]);

    const target = w.findComponent({
      name: "BaseSelect",
      props: { name: "target" },
    });

    await w.vm.$nextTick();
    (w.vm as unknown as { targetValue?: string }).targetValue = "user:alice";
    await w.vm.$nextTick();

    (w.vm as unknown as { memberFleet?: string }).memberFleet = "other";
    await w.vm.$nextTick();

    expect(
      (w.vm as unknown as { targetValue?: string }).targetValue,
    ).toBeUndefined();
    expect(target).toBeDefined();
  });

  it("offers the person kind on fleet membership alone", async () => {
    await build([position()], [immediateTarget], vi.fn(), [
      { value: "crew", label: "Crew" },
    ]);

    expect(wrapper!.find('[data-test="transfer-target-kind"]').exists()).toBe(
      true,
    );
  });
});

// `Contracts::Progress` counts what a transfer naming the contract delivered,
// not what landed in the inventory -- so a delivery that cannot name one never
// moves the bar, however exactly it matches the line.
describe("TransferModal towards a contract", () => {
  afterEach(() => {
    openContracts.value = [];
  });

  it("does not ask about contracts when the fleet has none running", async () => {
    const { wrapper } = await build([position()], [pendingTarget]);

    expect(wrapper.find("[data-test='transfer-contract']").exists()).toBe(
      false,
    );
  });

  it("sends the chosen contract with the transfer", async () => {
    openContracts.value = [{ id: "contract-1", title: "Craft 10 rifles" }];

    const { wrapper, onSend } = await build([position()], [pendingTarget]);

    const picker = wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find(
        (component) =>
          component.attributes("data-test") === "transfer-contract",
      );

    expect(picker).toBeDefined();

    await picker?.vm.$emit("update:modelValue", "contract-1");
    await wrapper.find("[data-test='transfer-submit']").trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({ contractId: "contract-1" }),
    );
  });

  it("leaves it out when no contract was picked", async () => {
    openContracts.value = [{ id: "contract-1", title: "Craft 10 rifles" }];

    const { wrapper, onSend } = await build([position()], [pendingTarget]);

    await wrapper.find("[data-test='transfer-submit']").trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({ contractId: undefined }),
    );
  });

  const contractTarget: TransferTargetOption = {
    kind: "contract",
    value: "contract:c-1",
    label: "Buy titanium (Crew): Locker",
    needsAnswer: true,
    payload: { inventoryId: "locker", contractId: "c-1" },
  };

  it("offers the contract kind only when there is a contract to deliver to", async () => {
    const kinds = (w: ReturnType<typeof mount>) =>
      (w.vm as unknown as { availableKinds: string[] }).availableKinds;

    const without = await build([position()], [immediateTarget]);
    expect(kinds(without.wrapper)).not.toContain("contract");
    without.wrapper.unmount();

    const withContract = await build([position()], [contractTarget]);
    expect(kinds(withContract.wrapper)).toContain("contract");
  });

  // The target names its contract, so the separate picker has nothing to add
  // and must not override it.
  it("sends a contract target under its own contract", async () => {
    openContracts.value = [{ id: "other", title: "Something else" }];

    const { wrapper, onSend } = await build([position()], [contractTarget]);

    expect(wrapper.find("[data-test='transfer-contract']").exists()).toBe(
      false,
    );

    await wrapper.find("[data-test='transfer-submit']").trigger("click");
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith(
      expect.objectContaining({ inventoryId: "locker", contractId: "c-1" }),
    );
  });
});
