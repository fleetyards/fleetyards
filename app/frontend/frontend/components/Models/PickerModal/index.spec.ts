import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const option = {
  id: "10000000-0000-0000-0000-000000000000",
  name: "Freelancer MAX",
  slug: "misc-freelancer-max",
  manufacturer: { name: "MISC", slug: "misc", code: "MISC" },
  classification: "transport",
  classificationLabel: "Transport",
  inHangar: false,
  onWishlist: false,
  media: {},
};

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useModelOptions: () => ({
    data: ref({
      items: [option],
      meta: { pagination: { currentPage: 1, totalPages: 1, totalCount: 1 } },
    }),
    isLoading: ref(false),
    isFetching: ref(false),
  }),
}));

vi.stubGlobal(
  "IntersectionObserver",
  class {
    observe() {}
    unobserve() {}
    disconnect() {}
  },
);

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props: { title: "Pick", submitLabel: "Add ships", ...props },
  });

describe("Models/PickerModal", () => {
  it("collects picks until they are submitted", async () => {
    const wrapper = await mount();

    await wrapper.find(".model-card__toggle").trigger("click");

    expect(wrapper.emitted("submit")).toBeUndefined();
    expect(wrapper.find(".model-picker__tray").text()).toContain(
      "Freelancer MAX",
    );
    expect(wrapper.find('[data-test="model-picker-submit"]').exists()).toBe(
      true,
    );
  });

  it("submits the clicked ship straight away in single mode", async () => {
    const wrapper = await mount({ single: true });

    await wrapper.find(".model-card__toggle").trigger("click");

    expect(wrapper.emitted("submit")?.[0]).toEqual([[{ option, quantity: 1 }]]);
  });

  it("shows no counter or submit button in single mode", async () => {
    const wrapper = await mount({ single: true });

    expect(wrapper.find('[data-test="model-picker-submit"]').exists()).toBe(
      false,
    );
    expect(wrapper.find(".model-picker__selected").exists()).toBe(false);
  });
});
