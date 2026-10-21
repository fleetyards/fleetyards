import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { computed, ref } from "vue";
import type { HomepageSetting } from "@/services/fyAdminApi";
import Page from "./homepage.vue";

let settings: HomepageSetting = { featuredModelIds: [], featuredRandom: true };
const mutateAsync = vi.fn(async ({ data }) => ({
  featuredModelIds: data.featuredModelIds,
  featuredRandom: data.featuredRandom,
}));

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyAdminApi")>()),
  useHomepageSettings: () => ({
    data: computed(() => settings),
    isPending: ref(false),
    isFetching: ref(false),
    isLoading: ref(false),
    isRefetching: ref(false),
    error: ref(null),
  }),
  useUpdateHomepageSettings: () => ({ mutateAsync }),
}));

// The real picker fetches ships; the page only cares about the id it holds.
vi.mock("@/admin/components/base/ModelSelect/index.vue", () => ({
  default: {
    name: "ModelSelect",
    props: { modelValue: { type: Array, default: undefined }, name: String },
    emits: ["update:modelValue"],
    render: () => null,
  },
}));

// vee-validate settles a submit over several ticks, not one microtask flush.
const submit = async (
  wrapper: Awaited<ReturnType<typeof mountWithDefaults>>,
) => {
  await wrapper.find("form#admin-homepage-form").trigger("submit");
  await flushPromises();
  await new Promise((resolve) => setTimeout(resolve, 20));
  await flushPromises();
};

describe("AdminHomepagePage", () => {
  it("removes every featured ship", async () => {
    mutateAsync.mockClear();
    settings = {
      featuredModelIds: [
        "8d0e3c7a-0000-4000-8000-000000000001",
        "8d0e3c7a-0000-4000-8000-000000000002",
      ],
      featuredRandom: false,
    };
    const wrapper = await mountWithDefaults(Page);
    await flushPromises();

    await wrapper
      .find("[data-test='homepage-clear-featured-models']")
      .trigger("click");
    await submit(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: { featuredModelIds: [], featuredRandom: false },
    });
    expect(
      wrapper.find("[data-test='homepage-clear-featured-models']").exists(),
    ).toBe(false);
  });

  it("offers no removal while no ship is featured", async () => {
    settings = { featuredModelIds: [], featuredRandom: true };
    const wrapper = await mountWithDefaults(Page);
    await flushPromises();

    expect(
      wrapper.find("[data-test='homepage-clear-featured-models']").exists(),
    ).toBe(false);
  });
});
