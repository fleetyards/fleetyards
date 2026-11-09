import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type Model } from "@/services/fyApi";

const MODELS: Record<string, Model> = {
  gladius: { slug: "gladius", name: "Gladius" } as unknown as Model,
  arrow: { slug: "arrow", name: "Arrow" } as unknown as Model,
};

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModel: (slug: Ref<string>) => ({
    data: computed(() => MODELS[slug.value.toLowerCase()]),
    isLoading: computed(() => slug.value === "loading"),
    isError: computed(
      () =>
        !!slug.value &&
        slug.value !== "loading" &&
        !MODELS[slug.value.toLowerCase()],
    ),
  }),
}));

vi.mock("@/frontend/components/Models/PickerSelect/index.vue", () => ({
  default: {
    name: "ModelPickerSelect",
    props: ["modelValue", "query", "name", "label"],
    emits: ["update:modelValue"],
    template: "<div />",
  },
}));

vi.mock("@/frontend/components/PaintBooth/index.vue", () => ({
  default: {
    name: "PaintBooth",
    props: ["model", "paint"],
    emits: ["update:paint"],
    template: "<div data-test='paint-booth'><slot name='controls' /></div>",
  },
}));

const { default: Component } = await import("./paint-booth.vue");

const mount = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/tools/paint-booth/",
        name: "paint-booth",
        component: { template: "<div />" },
        meta: { title: "tools.paintBooth" },
      },
    ],
  });
  await router.push({ name: "paint-booth", query });

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    plugins: [router],
  });
  await flushPromises();

  return { wrapper, router };
};

describe("ToolsPaintBoothPage", () => {
  it("asks for a ship until one is picked, offering only painted ones", async () => {
    const { wrapper } = await mount();

    expect(wrapper.find('[data-test="paint-booth-empty"]').exists()).toBe(true);
    expect(
      wrapper.findComponent({ name: "ModelPickerSelect" }).props("query"),
    ).toEqual({ withTexturedHolo: true });
  });

  it("shows the ship and paint the address names", async () => {
    const { wrapper } = await mount({ ship: "gladius", paint: "blue-steel" });

    expect(wrapper.findComponent({ name: "PaintBooth" }).props()).toEqual({
      model: MODELS.gladius,
      paint: "blue-steel",
    });
  });

  it("keeps the picked paint in the address", async () => {
    const { wrapper, router } = await mount({ ship: "gladius" });

    wrapper
      .findComponent({ name: "PaintBooth" })
      .vm.$emit("update:paint", "blue-steel");
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({
      ship: "gladius",
      paint: "blue-steel",
    });
  });

  it("drops the paint when another ship is picked", async () => {
    const { wrapper, router } = await mount({
      ship: "gladius",
      paint: "blue-steel",
    });

    wrapper
      .findComponent({ name: "ModelPickerSelect" })
      .vm.$emit("update:modelValue", "arrow");
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ ship: "arrow" });
    expect(
      wrapper.findComponent({ name: "PaintBooth" }).props("model"),
    ).toEqual(MODELS.arrow);
  });
  it("shows a ship the API answers for under another spelling", async () => {
    const { wrapper } = await mount({ ship: "Gladius" });

    expect(
      wrapper.findComponent({ name: "PaintBooth" }).props("model"),
    ).toEqual(MODELS.gladius);
  });

  it("says a picked ship is loading, or could not be found", async () => {
    const { wrapper, router } = await mount({ ship: "loading" });

    expect(wrapper.find('[data-test="paint-booth-empty"]').text()).toContain(
      "Loading…",
    );

    await router.replace({ name: "paint-booth", query: { ship: "nope" } });
    await flushPromises();

    expect(wrapper.find('[data-test="paint-booth-empty"]').text()).toContain(
      "This ship could not be found.",
    );
  });
});
