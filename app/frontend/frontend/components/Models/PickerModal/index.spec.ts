import { afterEach, describe, expect, it, vi } from "vitest";
import { nextTick, type Ref, ref } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import FocusSelect from "@/frontend/components/base/ModelFocusSelect/index.vue";
import SizeSelect from "@/frontend/components/base/ModelSizeSelect/index.vue";
import ProductionStatusSelect from "@/frontend/components/base/ProductionStatusSelect/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import { type ModelQuery } from "@/services/fyApi";
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

const requested = vi.hoisted(() => ({
  params: undefined as Ref<{ q: ModelQuery }> | undefined,
}));

const lastQuery = () => requested.params?.value.q;

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useModelOptions: (params: Ref<{ q: ModelQuery }>) => {
    requested.params = params;

    return {
      data: ref({
        items: [option],
        meta: { pagination: { currentPage: 1, totalPages: 1, totalCount: 1 } },
      }),
      isLoading: ref(false),
      isFetching: ref(false),
    };
  },
}));

const viewport = vi.hoisted(() => ({ mobile: false }));

vi.stubGlobal(
  "matchMedia",
  vi.fn((query: string) => ({
    matches: viewport.mobile && query.includes("max-width"),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  })),
);

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

// The folded filters teleport by id, which only resolves in the document.
const attached: { unmount: () => void }[] = [];

const mountOnPhone = async (props: Record<string, unknown> = {}) => {
  viewport.mobile = true;

  const wrapper = await mountWithDefaults(Component, {
    props: { title: "Pick", submitLabel: "Add ships", ...props },
    attachTo: document.body,
  });

  attached.push(wrapper);

  return wrapper;
};

describe("Models/PickerModal", () => {
  afterEach(() => {
    viewport.mobile = false;
    attached.splice(0).forEach((wrapper) => wrapper.unmount());
  });

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

  it("does not submit the picks when the form is submitted with Enter", async () => {
    const wrapper = await mount();

    await wrapper.find(".model-card__toggle").trigger("click");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.emitted("submit")).toBeUndefined();

    await wrapper.find('[data-test="model-picker-submit"]').trigger("click");

    expect(wrapper.emitted("submit")?.[0]).toEqual([[{ option, quantity: 1 }]]);
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

  it("keeps the extra filters folded away until asked for", async () => {
    const wrapper = await mount();
    const display = () =>
      wrapper.find(".model-picker__toolbar--more").element.parentElement?.style
        .display;

    expect(display()).toBe("none");

    await wrapper
      .find('[data-test="model-picker-more-filters"]')
      .trigger("click");

    expect(display()).toBe("");
  });

  it("labels the filter toggle with an icon, not text", async () => {
    const wrapper = await mount();
    const toggle = wrapper.find('[data-test="model-picker-more-filters"]');

    expect(toggle.text()).toBe("");
    expect(toggle.find(".fa-filter").exists()).toBe(true);
  });

  it("keeps manufacturer and classification in the toolbar on a desktop", async () => {
    const wrapper = await mount();

    const manufacturer = wrapper.findComponent(ManufacturerSelect);

    expect(manufacturer.exists()).toBe(true);
    expect(
      wrapper
        .find(".model-picker__toolbar--more")
        .element.contains(manufacturer.element),
    ).toBe(false);
  });

  it("folds every filter but the search away on a phone", async () => {
    const wrapper = await mountOnPhone();
    const more = wrapper.find(".model-picker__toolbar--more");

    const manufacturer = wrapper.findAllComponents(ManufacturerSelect);

    expect(manufacturer).toHaveLength(1);
    expect(more.element.contains(manufacturer[0]?.element ?? null)).toBe(true);
    expect(more.element.parentElement?.style.display).toBe("none");
  });

  it("folds the container load away on a phone and counts it", async () => {
    const wrapper = await mountOnPhone({
      containerFilter: true,
      containerFit: { "32": 2 },
    });

    expect(
      wrapper
        .find("#model-picker-more-filters")
        .element.contains(wrapper.find(".model-picker__containers").element),
    ).toBe(true);
    expect(wrapper.find(".model-picker__filter-count").text()).toBe("1");
  });

  it("counts a folded manufacturer pick on a phone", async () => {
    const wrapper = await mountOnPhone();

    wrapper
      .findComponent(ManufacturerSelect)
      .vm.$emit("update:modelValue", ["misc"]);
    await nextTick();

    expect(wrapper.find(".model-picker__filter-count").text()).toBe("1");
    expect(
      wrapper
        .find('[data-test="model-picker-more-filters"]')
        .attributes("aria-label"),
    ).toBe("Filter (1)");
    expect(lastQuery()).toEqual({ manufacturerIn: ["misc"] });
  });

  it("offers no production status filter when the caller pins one", async () => {
    const offered = await mount();
    const pinned = await mount({
      query: { productionStatusIn: ["flight-ready"] },
    });

    expect(offered.findComponent(ProductionStatusSelect).exists()).toBe(true);
    expect(pinned.findComponent(ProductionStatusSelect).exists()).toBe(false);
  });

  it("asks for the focus, size and production status picked", async () => {
    const wrapper = await mount();

    wrapper
      .findComponent(FocusSelect)
      .vm.$emit("update:modelValue", ["mining"]);
    wrapper.findComponent(SizeSelect).vm.$emit("update:modelValue", ["large"]);
    wrapper
      .findComponent(ProductionStatusSelect)
      .vm.$emit("update:modelValue", ["in-concept"]);
    await nextTick();

    expect(lastQuery()).toEqual({
      focusIn: ["mining"],
      sizeIn: ["large"],
      productionStatusIn: ["in-concept"],
    });
  });

  it("drops the extra filters on reset", async () => {
    const wrapper = await mount();

    wrapper
      .findComponent(FocusSelect)
      .vm.$emit("update:modelValue", ["mining"]);
    wrapper.findComponent(SizeSelect).vm.$emit("update:modelValue", ["large"]);
    await nextTick();

    await wrapper.find(".model-picker__reset").trigger("click");

    expect(lastQuery()).toEqual({});
  });

  it("keeps the caller's production status pin whatever else is picked", async () => {
    const wrapper = await mount({
      query: { productionStatusIn: ["flight-ready"] },
    });

    wrapper
      .findComponent(FocusSelect)
      .vm.$emit("update:modelValue", ["mining"]);
    await nextTick();

    expect(lastQuery()).toEqual({
      productionStatusIn: ["flight-ready"],
      focusIn: ["mining"],
    });
  });
});
