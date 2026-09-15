import { describe, expect, it } from "vitest";
import {
  isTabRoute,
  routeName,
} from "@/shared/components/TabNavView/useActiveTab";
import { routes as eventEditRoutes } from "./routes";
import { routes as missionEditRoutes } from "@/frontend/pages/fleets/[slug]/missions/[mission]/edit/routes";

const tabs = (routes: typeof eventEditRoutes) =>
  routes.filter(isTabRoute).map((route) => String(routeName(route)));

/*
 * Both sets keep a retired `description/` path so links people already have go
 * on resolving. It redirects to the tab that absorbed it, and a redirect names
 * its target -- so the strip counted it as a tab of its own, drew it as a
 * second copy of Details labelled `nav.undefined`, and lit both at once.
 */
describe("fleet edit tabs", () => {
  it("offers an event's four tabs and nothing else", () => {
    expect(tabs(eventEditRoutes)).toEqual([
      "fleet-event-edit",
      "fleet-event-edit-schedule",
      "fleet-event-edit-signup",
      "fleet-event-edit-teams",
    ]);
  });

  it("offers a mission's two", () => {
    expect(tabs(missionEditRoutes)).toEqual([
      "fleet-mission-edit",
      "fleet-mission-edit-teams",
    ]);
  });

  // The path has to stay resolvable; it just must not be a tab.
  it("keeps the retired description path", () => {
    for (const routes of [eventEditRoutes, missionEditRoutes]) {
      const retired = routes.find((route) => route.path === "description/");

      expect(retired).toBeDefined();
      expect(isTabRoute(retired!)).toBe(false);
    }
  });

  // Every tab is labelled from `nav.<title>` and titled from `title.<title>`,
  // and neither ever appears as a literal `t()` for a grep to find.
  it("gives every tab a title to resolve in both namespaces", () => {
    for (const routes of [eventEditRoutes, missionEditRoutes]) {
      for (const route of routes.filter(isTabRoute)) {
        expect(route.meta?.title).toBeTruthy();
      }
    }
  });
});
