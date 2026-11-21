import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { VueQueryPlugin } from "@tanstack/vue-query";
import Component from "./index.vue";

const mutateAsync = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async (original) => ({
  ...(await original<Record<string, unknown>>()),
  useHandOverFleetInventoryStock: () => ({ mutateAsync }),
  fleetMembers: vi.fn().mockResolvedValue({ items: [] }),
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  mutateAsync.mockReset();
});

const lot = {
  id: "pos-1",
  slug: "quantanium--commodity--scu",
  name: "Quantanium",
  category: "commodity",
  unit: "scu",
  quality: 600,
  netQuantity: 100,
  holders: [
    { holder: { id: "alice", username: "alice" }, netQuantity: 70 },
    { holder: null, netQuantity: 30 },
  ],
};

const build = async () => {
  wrapper = mount(Component, {
    attachTo: document.body,
    props: {
      fleet: { slug: "crew" } as never,
      inventory: { slug: "depot" } as never,
      lot,
    },
    global: {
      plugins: [createTestingPinia(), VueQueryPlugin],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        BaseSelect: true,
      },
    },
  });

  await flushPromises();

  return wrapper;
};

const select = (name: string) =>
  wrapper!
    .findAllComponents({ name: "BaseSelect" })
    .find((component) => component.attributes("data-test") === name);

describe("FleetLogisticsHandoverModal", () => {
  it("hands the largest share over whole, keeping the lot's grade", async () => {
    await build();

    await select("handover-to")?.vm.$emit("update:modelValue", "bob");
    await flushPromises();
    await wrapper!.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      fleetSlug: "crew",
      fleetInventorySlug: "depot",
      slug: "quantanium--commodity--scu",
      data: {
        fromHolderId: "alice",
        toHolderId: "bob",
        quantity: 70,
        quality: 600,
        craftedBlueprintId: null,
        craftedQualities: null,
      },
    });
  });

  it("hands the unassigned share over as a null giver", async () => {
    await build();

    await select("handover-from")?.vm.$emit("update:modelValue", "unassigned");
    await select("handover-to")?.vm.$emit("update:modelValue", "alice");
    await flushPromises();
    await wrapper!.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          fromHolderId: null,
          toHolderId: "alice",
          quantity: 30,
        }),
      }),
    );
  });

  it("sends nothing until someone is named to take it", async () => {
    await build();

    await wrapper!.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(
      wrapper!.find('[data-test="handover-submit"]').attributes("disabled"),
    ).toBeDefined();
  });
});
