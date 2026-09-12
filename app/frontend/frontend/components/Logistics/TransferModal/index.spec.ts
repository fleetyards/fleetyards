import { afterEach, describe, expect, it, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { VueQueryPlugin } from "@tanstack/vue-query";
import TransferModal from "./index.vue";
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
  value: "inventory:other",
  label: "Locker",
  needsAnswer: false,
  payload: { inventoryId: "other" },
};

const pendingTarget: TransferTargetOption = {
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
) => {
  wrapper = mount(TransferModal, {
    props: {
      source: { id: "src", name: "Caterpillar" },
      positions,
      targets,
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

const select = async (slug: string) => {
  await wrapper!.find(`[data-test="transfer-select-${slug}"]`).setValue(true);
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

  it("cannot send with nothing selected", async () => {
    await build([position()]);

    expect(
      wrapper!.find('[data-test="transfer-submit"]').attributes("disabled"),
    ).toBeDefined();
  });

  // The whole position is the common case; a part of one is the exception.
  it("defaults a selected line to the full net quantity", async () => {
    const { onSend } = await build([position()]);

    await select("titanium--commodity--scu");
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

  // All-or-nothing, the same rule the API applies: the button does not offer to
  // send a partly valid shipment.
  it("refuses to send when a line asks for more than the position holds", async () => {
    const { onSend } = await build([position()]);

    await select("titanium--commodity--scu");
    await wrapper!.find('[data-test="input-quantity-pos-1"]').setValue("500");
    await flushPromises();

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
});
