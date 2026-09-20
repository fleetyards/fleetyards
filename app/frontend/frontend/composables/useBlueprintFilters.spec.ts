import { describe, expect, it } from "vitest";
import {
  createRouter,
  createWebHashHistory,
  type LocationQueryRaw,
} from "vue-router";
import { createApp } from "vue";
import { useBlueprintFilters } from "./useBlueprintFilters";

// `route.query` hands back a bare string when a param appears once, and the
// API declares these as arrays -- so a single material used to leave as a
// string and come back a 400. Every material chip on a row writes exactly one.
const queryFor = async (query: LocationQueryRaw) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "blueprints", component: { template: "<div />" } },
    ],
  });

  await router.push({ name: "blueprints", query });
  await router.isReady();

  let result: Record<string, unknown> = {};
  const app = createApp({
    setup() {
      result = useBlueprintFilters().getQuery() as Record<string, unknown>;

      return () => null;
    },
  });
  app.use(router);
  app.mount(document.createElement("div"));
  app.unmount();

  return result;
};

describe("useBlueprintFilters", () => {
  it("sends a lone material as a list", async () => {
    expect(
      (await queryFor({ consumingCommodityIn: "iron" })).consumingCommodityIn,
    ).toEqual(["iron"]);
  });

  it("leaves several materials alone", async () => {
    expect(
      (await queryFor({ consumingCommodityIn: ["iron", "corundum"] }))
        .consumingCommodityIn,
    ).toEqual(["iron", "corundum"]);
  });

  it("does not invent a list for a material nobody picked", async () => {
    expect(await queryFor({})).not.toHaveProperty("consumingCommodityIn");
  });

  it("sends a lone craftable type as a list", async () => {
    expect(
      (await queryFor({ craftableTypeIn: "Component" })).craftableTypeIn,
    ).toEqual(["Component"]);
  });

  it("sends a lone alignment as a list", async () => {
    expect(
      (await queryFor({ sourceAlignmentIn: "outlaw" })).sourceAlignmentIn,
    ).toEqual(["outlaw"]);
  });

  it("leaves several alignments alone", async () => {
    expect(
      (await queryFor({ sourceAlignmentIn: ["lawful", "neutral"] }))
        .sourceAlignmentIn,
    ).toEqual(["lawful", "neutral"]);
  });
});
