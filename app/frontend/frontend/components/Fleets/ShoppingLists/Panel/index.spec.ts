import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Fleet,
  type FleetShoppingList,
  type FleetShoppingListDetail,
} from "@/services/fyApi";

const emit = vi.fn();
const detail = ref<FleetShoppingListDetail | undefined>(undefined);
let enabled: { value: boolean } | undefined;

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useFleetShoppingList: (
    _slug: unknown,
    _id: unknown,
    options: { query: { enabled: { value: boolean } } },
  ) => {
    enabled = options.query.enabled;

    return {
      data: detail,
      isLoading: ref(false),
      isFetching: ref(false),
      isError: ref(false),
      error: ref(null),
      refetch: vi.fn(),
    };
  },
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

const Component = (await import("./index.vue")).default;

const fleet = { slug: "merc" } as Fleet;

const list = {
  id: "kit",
  name: "Standard kit",
  description: "Buy before the op",
  visibility: "members_only",
  fleetSquadrons: [],
  linesCount: 1,
  itemsCount: 2,
} as unknown as FleetShoppingList;

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { fleet, list, ...props },
  });

describe("FleetShoppingListPanel", () => {
  beforeEach(() => {
    emit.mockClear();
    enabled = undefined;
    detail.value = {
      ...list,
      items: [
        {
          id: "line",
          quantity: 2,
          item: {
            id: "helmet",
            type: "Equipment",
            name: "Morozov Helmet",
            slug: "morozov-helmet",
            listed: false,
          },
          total: 2000,
          price: { location: "Area18 - Cousin Crow's" },
        },
      ],
      totals: { total: 2000 },
    } as unknown as FleetShoppingListDetail;
  });

  it("asks for the lines only once the list is opened", async () => {
    const wrapper = await mount();

    expect(enabled?.value).toBe(false);
    expect(
      wrapper.findAll("[data-test='fleet-shopping-list-line']"),
    ).toHaveLength(0);

    await wrapper
      .find("[data-test='fleet-shopping-list-toggle']")
      .trigger("click");

    expect(enabled?.value).toBe(true);
    expect(
      wrapper.find("[data-test='fleet-shopping-list-line']").text(),
    ).toContain("Morozov Helmet");
  });

  it("offers the copy to every reader and the menu only to editors", async () => {
    const reader = await mount();

    expect(reader.find("[data-test='fleet-shopping-list-copy']").exists()).toBe(
      true,
    );
    expect(reader.find("[data-test='fleet-shopping-list-menu']").exists()).toBe(
      false,
    );

    const editor = await mount({ editable: true });

    expect(editor.find("[data-test='fleet-shopping-list-menu']").exists()).toBe(
      true,
    );
  });

  it("opens the copy modal for this list", async () => {
    const wrapper = await mount();

    await wrapper
      .find("[data-test='fleet-shopping-list-copy']")
      .trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { fleet, list } }),
    );
  });
});
