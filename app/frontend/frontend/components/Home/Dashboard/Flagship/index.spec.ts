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

describe("HomeDashboardFlagship", () => {
  beforeEach(() => {
    changes = undefined;
  });

  it("shows the ship the pilot marked as flagship", async () => {
    vehicles = [vehicle("1", "Carrack", true), vehicle("2", "Cutlass")];

    const subject = await mount();

    expect(subject.find('[data-test="home-flagship"]').text()).toContain(
      "Carrack",
    );
  });

  it("shows nothing when no ship is marked as flagship", async () => {
    vehicles = [vehicle("1", "Carrack"), vehicle("2", "Cutlass")];

    const subject = await mount();

    expect(subject.find('[data-test="home-flagship"]').exists()).toBe(false);
  });
});
