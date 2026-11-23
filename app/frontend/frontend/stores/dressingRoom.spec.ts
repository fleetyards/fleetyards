import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import { type RouteLocationNormalized } from "vue-router";
import { lastVisitGuard, useDressingRoomStore } from "./dressingRoom";

const visit = (query: Record<string, string>) =>
  ({ name: "dressing-room", query }) as unknown as RouteLocationNormalized;

describe("lastVisitGuard", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("sends a bare address on to the last visit", () => {
    const lastQuery = { torso: "adp-core", face: "own-face", body: "female" };
    useDressingRoomStore().lastQuery = lastQuery;

    expect(lastVisitGuard(visit({}))).toEqual({
      name: "dressing-room",
      query: lastQuery,
      replace: true,
    });
  });

  it("leaves a shared address as it is", () => {
    useDressingRoomStore().lastQuery = { torso: "adp-core" };

    expect(lastVisitGuard(visit({ legs: "adp-legs" }))).toBe(true);
  });

  it("lets a bare address through when nothing, or an emptied page, was left", () => {
    expect(lastVisitGuard(visit({}))).toBe(true);

    useDressingRoomStore().lastQuery = {};

    expect(lastVisitGuard(visit({}))).toBe(true);
  });
});
