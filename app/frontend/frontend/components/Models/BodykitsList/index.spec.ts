import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { ModelBodykit } from "@/services/fyApi";
import Component from "./index.vue";

const bodykits = ref<ModelBodykit[] | undefined>();
const isSuccess = ref(false);
const isLoading = ref(true);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelBodykits: () => ({
    data: bodykits,
    isSuccess,
    isLoading,
    isError: ref(false),
  }),
}));

const page = defineComponent({ render: () => null });

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/components/:slug", name: "component", component: page }],
  });

const mount = () =>
  mountWithDefaults(Component, {
    props: { modelSlug: "shiv" },
    plugins: [router()],
  });

const bodykit = (name: string, stock: boolean): ModelBodykit => ({
  slot: "hardpoint_front",
  stock,
  component: { id: `${name}-id`, name, slug: name.toLowerCase() },
});

describe("ModelsBodykitsList", () => {
  beforeEach(() => {
    bodykits.value = undefined;
    isSuccess.value = false;
    isLoading.value = true;
  });

  it("is drawn while the body kits are on their way", async () => {
    const wrapper = await mount();

    expect(wrapper.find("#bodykits").exists()).toBe(true);
  });

  it("lists each body kit and marks the one the ship comes with", async () => {
    bodykits.value = [bodykit("Slasher", true), bodykit("Barebones", false)];
    isSuccess.value = true;
    isLoading.value = false;

    const wrapper = await mount();
    const items = wrapper.findAll("[data-test='model-bodykit']");

    expect(items.map((item) => item.text())).toEqual([
      "Slasher Factory fitted",
      "Barebones",
    ]);
  });

  it("leaves the section out for a ship without body kits", async () => {
    bodykits.value = [];
    isSuccess.value = true;
    isLoading.value = false;

    const wrapper = await mount();

    expect(wrapper.find("#bodykits").exists()).toBe(false);
  });
});
