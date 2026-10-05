import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { pageKey } from "./pageKey";

const component = { template: "<div />" };

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/compare/", name: "compare", component },
    {
      path: "/fleets/:slug/squadrons/new/",
      component,
      children: [
        {
          path: "",
          name: "new-details",
          component,
          meta: { nav: "editTabs" },
        },
        {
          path: "appearance/",
          name: "new-appearance",
          component,
          meta: { nav: "editTabs" },
        },
      ],
    },
    {
      path: "/fleets/:slug/",
      component,
      children: [
        { path: "", name: "fleet", component },
        { path: "members/", name: "fleet-members", component },
      ],
    },
  ],
});

const keyOf = (path: string) => pageKey(router.resolve(path));

describe("pageKey", () => {
  it("ignores a trailing slash", () => {
    expect(keyOf("/compare")).toBe(keyOf("/compare/"));
  });

  it("gives every tab of an editor the same key", () => {
    expect(keyOf("/fleets/black-sun/squadrons/new/")).toBe(
      "/fleets/black-sun/squadrons/new",
    );
    expect(keyOf("/fleets/black-sun/squadrons/new/appearance/")).toBe(
      "/fleets/black-sun/squadrons/new",
    );
    expect(keyOf("/fleets/black-sun/squadrons/new/appearance")).toBe(
      "/fleets/black-sun/squadrons/new",
    );
  });

  it("recognises a tab typed in another case", () => {
    expect(keyOf("/fleets/black-sun/squadrons/new/Appearance/")).toBe(
      "/fleets/black-sun/squadrons/new",
    );
  });

  it("keeps editors of different records apart", () => {
    expect(keyOf("/fleets/black-sun/squadrons/new/appearance/")).not.toBe(
      keyOf("/fleets/red-moon/squadrons/new/appearance/"),
    );
  });

  it("keeps child pages that are not editor tabs apart", () => {
    expect(keyOf("/fleets/black-sun/members/")).toBe(
      "/fleets/black-sun/members",
    );
  });
});
