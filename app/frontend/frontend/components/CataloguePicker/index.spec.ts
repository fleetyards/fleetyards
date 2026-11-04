import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";

const page = (id: string, currentPage: number) => ({
  items: [{ id, name: id, slug: id, media: {} }],
  meta: { pagination: { currentPage, totalPages: 2, totalCount: 2 } },
});

const fetchEquipment = vi.fn((_params: unknown) =>
  Promise.resolve(page("first", 1)),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  equipment: (params: unknown) => fetchEquipment(params),
}));

const { default: CataloguePicker } = await import("./index.vue");

describe("CataloguePicker", () => {
  it("keeps the load more button until the next page has landed", async () => {
    const wrapper = await mountWithDefaults<typeof CataloguePicker>(
      CataloguePicker,
      {
        props: {
          kind: "Equipment",
          query: { slotIn: ["helmet"] },
          cardTestPrefix: "card",
        },
      },
    );
    await flushPromises();

    let land: (value: ReturnType<typeof page>) => void = () => undefined;
    fetchEquipment.mockReturnValueOnce(
      new Promise((resolve) => {
        land = resolve;
      }),
    );

    const more = '[data-test="catalogue-picker-more"]';
    await wrapper.find(more).trigger("click");
    await flushPromises();

    expect(wrapper.find(more).exists()).toBe(true);
    expect(wrapper.find('[data-test="card-second"]').exists()).toBe(false);

    land(page("second", 2));
    await flushPromises();

    expect(wrapper.find(more).exists()).toBe(false);
    expect(wrapper.find('[data-test="card-first"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="card-second"]').exists()).toBe(true);
  });
});
