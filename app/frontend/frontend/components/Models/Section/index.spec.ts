import { flushPromises, mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import Component from "./index.vue";
import { useModelsStore } from "@/frontend/stores/models";

const mountAt = async (path: string, collapsed: Record<string, string[]>) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/ships/:slug/", component: { template: "<div />" } }],
  });
  await router.push(path);

  // A real store: the shared helper's testing pinia stubs every action, and
  // the toggle is an action.
  const pinia = createPinia();
  setActivePinia(pinia);
  useModelsStore().collapsedSections = collapsed;

  const wrapper = mount(Component, {
    props: { anchor: "paints", modelSlug: "andromeda", title: "Paints" },
    slots: { default: "<p>content</p>" },
    global: { plugins: [router, pinia] },
  });
  await flushPromises();

  return wrapper;
};

const toggle = (wrapper: Awaited<ReturnType<typeof mountAt>>) =>
  wrapper.find('[data-test="model-section-toggle-paints"]');

describe("ModelSection", () => {
  it("closes when its heading is clicked", async () => {
    const wrapper = await mountAt("/ships/andromeda/", {});

    expect(toggle(wrapper).attributes("aria-expanded")).toBe("true");

    await toggle(wrapper).trigger("click");

    expect(toggle(wrapper).attributes("aria-expanded")).toBe("false");
    expect(useModelsStore().sectionCollapsed("andromeda", "paints")).toBe(true);
  });

  it("opens when a link points at it", async () => {
    const wrapper = await mountAt("/ships/andromeda/#paints", {
      andromeda: ["paints"],
    });

    expect(toggle(wrapper).attributes("aria-expanded")).toBe("true");
  });
});
