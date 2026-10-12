import qs from "qs";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { Model, ModelOwners } from "@/services/fyApi";
import Component from "./index.vue";

const owners = ref<ModelOwners>();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelOwners: () => ({
    data: owners,
    isLoading: ref(false),
    error: ref(null),
  }),
}));

const stub = { template: "<div />" };

// The app's router writes queries with qs, which is what lets a fleet link
// carry the nested `q` filter at all.
const router = createRouter({
  history: createMemoryHistory(),
  stringifyQuery: (query) => qs.stringify(query, { arrayFormat: "brackets" }),
  routes: [
    { path: "/ships/:slug/", name: "ship", component: stub },
    { path: "/hangar/:id/", name: "hangar-vehicle-overview", component: stub },
    { path: "/hangar/:username/", name: "hangar-public", component: stub },
    { path: "/fleets/:slug/ships/", name: "fleet-ships", component: stub },
  ],
});

const model = {
  slug: "andromeda",
  name: "Constellation Andromeda",
  media: { storeImage: { smallUrl: "/store.jpg" } },
} as Model;

const emptyOwners = (): ModelOwners => ({
  vehicles: [],
  friends: { total: 0, items: [] },
  fleets: [],
});

const mount = async (data: ModelOwners) => {
  owners.value = data;
  await router.push("/ships/andromeda/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { model },
    plugins: [router],
  });
};

describe("ModelOwnersList", () => {
  it("says so when nobody in the circle flies the model", async () => {
    const wrapper = await mount(emptyOwners());

    expect(wrapper.text()).toContain("Nobody you know has one yet.");
    expect(wrapper.find('[data-test="model-owners-vehicles"]').exists()).toBe(
      false,
    );
  });

  it("links the reader's own ship by its serial", async () => {
    const wrapper = await mount({
      ...emptyOwners(),
      vehicles: [{ id: "v-1", serial: "ANDR-1", flagship: true }],
    });

    const block = wrapper.find('[data-test="model-owners-vehicles"]');

    expect(block.text()).toContain("Constellation Andromeda");
    expect(block.find("a").attributes("href")).toBe("/hangar/ANDR-1/");
  });

  it("shows the ship's own picture before the model's", async () => {
    const wrapper = await mount({
      ...emptyOwners(),
      vehicles: [
        { id: "v-1", flagship: false, image: { smallUrl: "/own.jpg" } },
        { id: "v-2", flagship: false },
      ] as ModelOwners["vehicles"],
    });

    const thumbs = wrapper
      .findAll('[data-test="model-owners-vehicles"] img')
      .map((img) => img.attributes("src"));

    expect(thumbs).toEqual(["/own.jpg", "/store.jpg"]);
  });

  it("counts the friends it could not list", async () => {
    const wrapper = await mount({
      ...emptyOwners(),
      friends: {
        total: 14,
        items: [{ username: "torlek", count: 2 }],
      },
    });

    const block = wrapper.find('[data-test="model-owners-friends"]');

    expect(block.text()).toContain("torlek");
    expect(block.text()).toContain("×2");
    expect(block.text()).toContain("+13 more");
  });

  it("links each fleet to its ship list filtered to the model", async () => {
    const wrapper = await mount({
      ...emptyOwners(),
      fleets: [
        {
          id: "f-1",
          fid: "AEGIS",
          name: "Aegis Wing",
          slug: "aegis-wing",
          total: 3,
          ownersTotal: 3,
          members: ["torlek", "wren"],
        },
      ],
    });

    const block = wrapper.find('[data-test="model-owners-fleets"]');
    const href = decodeURIComponent(block.find("a").attributes("href") ?? "");

    expect(href).toContain("/fleets/aegis-wing/ships/");
    expect(href).toContain("q[modelSlugIn][]=andromeda");
    expect(block.text()).toContain("torlek, wren");
    expect(block.text()).toContain("+1 more");
  });
});
