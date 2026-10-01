import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Location, LocationKindEnum } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "location", params: { slug: "levski" } });
  await instance.isReady();

  return instance;
};

const link = (name: string, slug: string) => ({
  id: `${slug}-0000-0000-0000-000000000000`,
  name,
  slug,
  kind: LocationKindEnum.STAR,
  parentName: null,
});

const mount = async (attrs: Partial<Location>) =>
  mountWithDefaults(Component, {
    props: {
      location: {
        shownOnStarmap: true,
        shownWithParentOnly: false,
        alwaysShown: false,
        quantumTravelDestination: true,
        parent: link("Delamar", "delamar"),
        mapParent: null,
        ...attrs,
      } as Location,
    },
    plugins: [await router()],
  });

describe("LocationStarmapFacts", () => {
  // The map pins Levski under the Nyx star while it sits inside Delamar, and
  // the page says so rather than smoothing it over.
  it("names where the map draws a place when that is not where it is", async () => {
    const wrapper = await mount({
      alwaysShown: true,
      mapParent: link("Nyx", "nyx"),
    });

    expect(wrapper.find('[data-test="starmap-visibility"]').text()).toBe(
      "Always shown on the map",
    );
    expect(wrapper.find('[data-test="starmap-map-parent"]').text()).toContain(
      "draws it under Nyx, although it sits inside Delamar",
    );
  });

  it("says a place only shows once its parent is selected", async () => {
    const wrapper = await mount({ shownWithParentOnly: true });

    expect(wrapper.find('[data-test="starmap-visibility"]').text()).toBe(
      "Shown once Delamar is selected",
    );
    expect(wrapper.find('[data-test="starmap-map-parent"]').exists()).toBe(
      false,
    );
  });

  it("says a place is hidden on the map", async () => {
    const wrapper = await mount({ shownOnStarmap: false });

    expect(wrapper.find('[data-test="starmap-visibility"]').text()).toBe(
      "Hidden on the map",
    );
  });
});
