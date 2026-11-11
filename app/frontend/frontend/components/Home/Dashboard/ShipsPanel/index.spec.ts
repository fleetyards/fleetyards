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

const vehicle = (id: string, name: string): Vehicle =>
  ({
    id,
    hangarGroups: [],
    model: {
      id: `m-${id}`,
      name,
      slug: name.toLowerCase(),
      media: {},
      manufacturer: { name: "Anvil" },
    },
  }) as unknown as Vehicle;

const tags = async () => {
  const subject = await mountWithDefaults(Component, {
    plugins: [await router()],
  });

  return subject
    .findAll('[data-test="home-ship-tile-tag"]')
    .map((tag) => tag.text());
};

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

  it("tags only the ships the live patch changed", async () => {
    changes = {
      environment: "live",
      version: "4.3.2",
      totalCount: 1,
      items: [
        {
          model: { id: "m-1", name: "Carrack", slug: "carrack" },
          changeCount: 3,
        },
      ],
    } as unknown as MyPatchChanges;

    expect(await tags()).toEqual(["Changed in 4.3.2"]);
  });

  it("shows no tag when the patch left the hangar alone", async () => {
    expect(await tags()).toEqual([]);
  });
});
