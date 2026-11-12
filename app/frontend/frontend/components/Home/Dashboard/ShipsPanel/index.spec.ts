import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { MyPatchChanges, Vehicle } from "@/services/fyApi";
import Component from "./index.vue";

let vehicles: Vehicle[] = [];
let changes: MyPatchChanges | undefined;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  const answer = <T>(value: () => T) => ({
    data: computed(value),
    isLoading: ref(false),
    isFetching: ref(false),
    isLoadingError: ref(false),
  });

  return {
    ...actual,
    useHangar: () =>
      answer(() => ({
        items: vehicles,
        meta: { pagination: { totalCount: vehicles.length } },
      })),
    useMyPatchChanges: () => answer(() => changes),
    useSyncRsiHangarLastRead: () => answer(() => undefined),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/hangar", name: "hangar", component: Stub },
      { path: "/:rest(.*)*", component: Stub },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const vehicle = (id: string, name: string, flagship = false): Vehicle =>
  ({
    id,
    flagship,
    hangarGroups: [],
    model: {
      id: `m-${id}`,
      name,
      slug: name.toLowerCase(),
      media: {},
      manufacturer: { name: "Anvil" },
    },
  }) as unknown as Vehicle;

const mount = async () =>
  mountWithDefaults(Component, { plugins: [await router()] });

const tags = async () =>
  (await mount())
    .findAll('[data-test="home-ship-tile-tag"]')
    .map((tag) => tag.text());

const listed = async () =>
  (await mount())
    .findAll('[data-test="home-ships-item"]')
    .map((item) => item.attributes("title"));

describe("HomeDashboardShipsPanel", () => {
  beforeEach(() => {
    // The tiles carry a store image, and jsdom has no IntersectionObserver for
    // the lazy background to hand it to.
    vi.stubGlobal(
      "IntersectionObserver",
      class {
        observe() {}
        unobserve() {}
        disconnect() {}
      },
    );
    vehicles = [vehicle("1", "Carrack"), vehicle("2", "Cutlass")];
    changes = undefined;
  });

  it("tags the owned ships the live patch changed, listed or not", async () => {
    changes = {
      environment: "live",
      version: "4.3.2",
      totalCount: 12,
      ownedCount: 1,
      ownedModelIds: ["m-1"],
      items: [],
    } as unknown as MyPatchChanges;

    expect(await tags()).toEqual(["Changed in 4.3.2"]);
  });

  it("shows no tag when the patch left the hangar alone", async () => {
    expect(await tags()).toEqual([]);
  });

  it("leaves a flagship to the header", async () => {
    vehicles = [vehicle("1", "Carrack", true), vehicle("2", "Cutlass")];

    expect(await listed()).toEqual(["Cutlass"]);
  });

  it("lists the newest ship when none is marked as flagship", async () => {
    expect(await listed()).toEqual(["Carrack", "Cutlass"]);
  });
});
