import { describe, expect, it } from "vitest";
import {
  createRouter,
  createWebHashHistory,
  type LocationQueryRaw,
} from "vue-router";
import { createApp } from "vue";
import { useMissionFilters } from "./useMissionFilters";

const queryFor = async (query: LocationQueryRaw) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "missions", component: { template: "<div />" } },
    ],
  });

  await router.push({ name: "missions", query });
  await router.isReady();

  let result: Record<string, unknown> = {};
  const app = createApp({
    setup() {
      result = useMissionFilters().getQuery() as Record<string, unknown>;

      return () => null;
    },
  });
  app.use(router);
  app.mount(document.createElement("div"));
  app.unmount();

  return result;
};

describe("useMissionFilters", () => {
  it("sends a lone location as a list", async () => {
    expect(
      (await queryFor({ locationKindIn: "surface" })).locationKindIn,
    ).toEqual(["surface"]);
  });

  // Ransack ANDs the two, and `surface` beside `[space]` is an empty list.
  it("drops the scalar location once the list is set", async () => {
    const query = await queryFor({
      locationKindEq: "surface",
      locationKindIn: "space",
    });

    expect(query.locationKindIn).toEqual(["space"]);
    expect(query).not.toHaveProperty("locationKindEq");
  });

  it("keeps the ship out of the API query", async () => {
    expect(await queryFor({ ship: "misc-hull-c" })).not.toHaveProperty("ship");
  });
});
