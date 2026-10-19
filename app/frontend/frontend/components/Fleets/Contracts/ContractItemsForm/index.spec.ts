import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

// jsdom reports a narrow viewport, and the list folds its row actions into a
// closed dropdown there -- the edit button would not be in the document at all.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => false,
}));

const items = [
  {
    id: "line-1",
    name: "Quantanium",
    category: "commodity",
    unit: "scu",
    quantity: "1200.0",
    quality: 500,
    qualityMatch: "at_least",
    item: null,
  },
];

const fleet = { slug: "black-sun" } as never;
const contract = (lines: unknown[] = items) =>
  ({ slug: "haul", kind: "transport", items: lines }) as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  emit.mockClear();
});

const mount = async (lines?: unknown[]) => {
  wrapper = await mountWithDefaults(Component, {
    props: { fleet, contract: contract(lines), kind: "transport" as never },
  });

  return wrapper;
};

const modalCalls = () =>
  emit.mock.calls.filter(([event]) => event === "open-modal");

describe("FleetContractsItemsForm", () => {
  it("lists the goods through the app's editable list", async () => {
    const subject = await mount();

    expect(subject.findComponent({ name: "InlineEditableList" }).exists()).toBe(
      true,
    );
    expect(subject.text()).toContain("Quantanium");
    expect(subject.text()).toContain("1200");
  });

  // "500" alone would leave a courier guessing whether better also passes.
  it("says how a grade is read rather than printing a bare number", async () => {
    const subject = await mount();

    expect(subject.text()).toMatch(/500/);
    expect(subject.find(".contract-items__quality").text()).not.toBe("500");
  });

  it("asks for new goods in the modal", async () => {
    const subject = await mount();

    await subject.find("[data-test='add-item']").trigger("click");

    expect(modalCalls()).toHaveLength(1);
    expect(modalCalls()[0][1].props.item).toBeUndefined();
  });

  // A line that was entered wrongly has to be fixable in place.
  it("reopens the modal on the line being edited", async () => {
    const subject = await mount();

    await subject.find("[data-test='edit-item']").trigger("click");

    expect(modalCalls()).toHaveLength(1);
    expect(modalCalls()[0][1].props.item).toMatchObject({ id: "line-1" });
  });

  describe("drafts", () => {
    const mountDrafts = async (drafts: unknown[] = []) => {
      wrapper = await mountWithDefaults(Component, {
        props: { fleet, kind: "crafting" as never, drafts: drafts as never },
      });

      return wrapper;
    };

    // The API input carries the part's id, not whether the game counts it in
    // pieces; reopening a draft must still offer `units` for it.
    it("reopens a draft with its part and how the game counts it", async () => {
      const subject = await mountDrafts();

      await subject.find("[data-test='add-item']").trigger("click");

      const draft = {
        name: "Hadanite",
        category: "commodity",
        unit: "units",
        quantity: "3",
        itemType: "Commodity",
        itemId: "hadanite",
      };

      modalCalls()[0][1].props.onDraft(draft, { counted: true });

      const [next] = subject.emitted("update:drafts")!.at(-1) as unknown[][];

      await subject.setProps({ drafts: next } as never);
      await subject.find("[data-test='edit-item']").trigger("click");

      expect(modalCalls()[1][1].props.item.item).toMatchObject({
        id: "hadanite",
        type: "Commodity",
        counted: true,
      });
    });

    it("reopens a draft with its crafting", async () => {
      const subject = await mountDrafts([
        {
          name: "Bulwark",
          category: "component",
          unit: "units",
          quantity: "1",
          itemType: "Component",
          itemId: "bulwark",
          craftedBlueprintId: "bp-1",
          craftedBlueprintSlug: "bulwark-bp",
          craftedQualities: { 1: 700 },
        },
      ]);

      expect(subject.find("[data-test='contract-item-crafted']").exists()).toBe(
        true,
      );

      await subject.find("[data-test='edit-item']").trigger("click");

      expect(modalCalls()[0][1].props.item.crafted).toMatchObject({
        blueprint: { id: "bp-1", slug: "bulwark-bp" },
        qualities: { 1: 700 },
      });
    });
  });
});
