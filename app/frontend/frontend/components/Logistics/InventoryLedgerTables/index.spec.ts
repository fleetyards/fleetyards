import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const viewport = vi.hoisted(() => ({ mobile: false }));

// A desktop table unless a test says otherwise: on a phone the quality column
// folds away, and the catalogue card moves off the name.
vi.mock("@/shared/composables/useMobile", async () => {
  const { ref } = await import("vue");

  return { useMobile: () => ref(viewport.mobile) };
});

vi.mock("@/frontend/components/CatalogueItemPopover/index.vue", () => ({
  default: {
    name: "CatalogueItemPopover",
    props: ["item", "crafted", "link", "linkLabel"],
    template: '<span data-test="catalogue-popover"><slot /></span>',
  },
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  viewport.mobile = false;
});

const crafted = {
  blueprint: { id: "bp-1", name: "Absolute Zero", slug: "absolute-zero" },
  qualities: { 1: 750, 2: 500 },
};

const stockRow = {
  id: "pos-1",
  slug: "absolutezero--component--units",
  name: "AbsoluteZero",
  category: "component",
  unit: "units",
  netQuantity: 1,
  item: { id: "c-1", type: "Component", slug: "absolutezero" },
  crafted,
};

const mount = async (props: Record<string, unknown>) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: props as never,
  });

  return wrapper;
};

describe("InventoryLedgerTables", () => {
  // The name is the way to the catalogue card, not an icon beside it.
  it("opens the catalogue card from the item's name", async () => {
    const subject = await mount({
      activeTab: "stock",
      stockRecords: [stockRow],
      logRecords: [],
    });

    const popover = subject.findComponent({ name: "CatalogueItemPopover" });

    expect(popover.text()).toContain("AbsoluteZero");
    expect(popover.props("crafted")).toEqual(crafted);
    expect(subject.find(".fa-book-open").exists()).toBe(false);
  });

  it("marks a crafted entry in the log", async () => {
    const subject = await mount({
      activeTab: "log",
      stockRecords: [],
      logRecords: [
        {
          id: "entry-1",
          name: "AbsoluteZero",
          category: "component",
          unit: "units",
          entryType: "deposit",
          quantity: 1,
          item: stockRow.item,
          crafted,
        },
      ],
    });

    expect(subject.find("[data-test='ledger-crafted-entry-1']").exists()).toBe(
      true,
    );
    expect(
      subject.findComponent({ name: "CatalogueItemPopover" }).props("crafted"),
    ).toEqual(crafted);
  });

  it("leaves a name nothing in the catalogue backs as plain text", async () => {
    const subject = await mount({
      activeTab: "stock",
      stockRecords: [{ ...stockRow, item: null, crafted: undefined }],
      logRecords: [],
    });

    expect(
      subject.findComponent({ name: "CatalogueItemPopover" }).exists(),
    ).toBe(false);
    expect(subject.text()).toContain("AbsoluteZero");
  });

  // A tap on the name would follow its link before the card could open, so a
  // phone gets the card from an icon beside it.
  it("hangs the catalogue card off an icon on a phone", async () => {
    viewport.mobile = true;

    const subject = await mount({
      activeTab: "stock",
      stockRecords: [stockRow],
      logRecords: [],
    });

    const popover = subject.findComponent({ name: "CatalogueItemPopover" });

    expect(popover.find(".fa-book-open").exists()).toBe(true);
    expect(popover.text()).not.toContain("AbsoluteZero");
    expect(popover.props("crafted")).toEqual(crafted);
  });
});
