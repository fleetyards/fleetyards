import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type ModelExtendedCarriedByItem } from "@/services/fyApi";
import Component from "./index.vue";

// Each carrier panel carries a store image, and jsdom has no
// IntersectionObserver for useLazyBackground to hand it to.
beforeEach(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

// Every carrier links to `ship`, so the router has to know the route.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/ships/:slug", name: "ship", component: { template: "<div />" } },
  ],
});

const mount = async (props: {
  carriedBy?: ModelExtendedCarriedByItem[] | null;
}) => {
  await router.push({ name: "home" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props,
    plugins: [router],
  });
};

/*
 * The panel reads `carriedBy.length` before anything else renders, so an
 * absent field takes the whole ship page down rather than just this section.
 * A response cached from before the field shipped is exactly that case.
 */
describe("ModelsCarriedByList", () => {
  it("renders nothing when the field is absent", async () => {
    const wrapper = await mount({});

    expect(wrapper.find("#carried-by").exists()).toBe(false);
  });

  it("renders nothing when the field is null", async () => {
    const wrapper = await mount({ carriedBy: null });

    expect(wrapper.find("#carried-by").exists()).toBe(false);
  });

  it("renders nothing when no ship carries this one", async () => {
    const wrapper = await mount({ carriedBy: [] });

    expect(wrapper.find("#carried-by").exists()).toBe(false);
  });

  it("names every carrier it is given", async () => {
    const wrapper = await mount({
      carriedBy: [
        { slug: "idris-m", name: "Idris-M", dockType: "hangar" },
        { slug: "polaris", name: "Polaris", dockType: "hangar" },
      ],
    });

    expect(wrapper.find("#carried-by").exists()).toBe(true);
    expect(wrapper.text()).toContain("Idris-M");
    expect(wrapper.text()).toContain("Polaris");
  });

  // The label says how the ship gets in. A berth nobody has looked at says
  // nothing at all rather than rendering an empty pill.
  it("shows how a berth is reached, and only where it is recorded", async () => {
    const wrapper = await mount({
      carriedBy: [
        {
          slug: "idris-m",
          name: "Idris-M",
          dockType: "hangar",
          accessLabel: "Ramp",
        },
        { slug: "polaris", name: "Polaris", dockType: "hangar" },
      ],
    });

    const pills = wrapper.findAll('[data-test="pill"]');

    expect(wrapper.text()).toContain("Ramp");
    expect(pills).toHaveLength(3);
  });
});
