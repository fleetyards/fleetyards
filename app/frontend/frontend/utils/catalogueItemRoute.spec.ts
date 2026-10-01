import { describe, expect, it } from "vitest";
import { catalogueItemRoute } from "./catalogueItemRoute";

describe("catalogueItemRoute", () => {
  it("routes each catalogue to its own detail page", () => {
    expect(
      catalogueItemRoute({ type: "Component", slug: "omnisky-ix" }),
    ).toEqual({ name: "component", params: { slug: "omnisky-ix" } });
    expect(
      catalogueItemRoute({ type: "Equipment", slug: "p4-ar-rifle" }),
    ).toEqual({ name: "equipment-item", params: { slug: "p4-ar-rifle" } });
    expect(catalogueItemRoute({ type: "Commodity", slug: "titanium" })).toEqual(
      { name: "commodity", params: { slug: "titanium" } },
    );
  });

  it("routes a contract and an event under their fleet, and a user to the hangar", () => {
    expect(
      catalogueItemRoute({
        type: "FleetContract",
        slug: "haul",
        fleetSlug: "maru",
      }),
    ).toEqual({
      name: "fleet-contract",
      params: { slug: "maru", contract: "haul" },
    });
    expect(
      catalogueItemRoute({
        type: "FleetEvent",
        slug: "mining",
        fleetSlug: "maru",
      }),
    ).toEqual({
      name: "fleet-event",
      params: { slug: "maru", event: "mining" },
    });
    expect(catalogueItemRoute({ type: "User", slug: "mortik" })).toEqual({
      name: "hangar-public",
      params: { username: "mortik" },
    });
    expect(
      catalogueItemRoute({ type: "FleetEvent", slug: "mining" }),
    ).toBeUndefined();
  });

  // A reference the catalogue cannot resolve reads as plain text rather than
  // as a link to the not-found page.
  it("gives no route without a slug or for a type with no page", () => {
    expect(
      catalogueItemRoute({ type: "Equipment", slug: null }),
    ).toBeUndefined();
    expect(catalogueItemRoute({ type: "Vehicle", slug: "x" })).toBeUndefined();
    expect(catalogueItemRoute(null)).toBeUndefined();
  });

  // A hidden equipment variant has no page, and a link to it would 404.
  it("gives no route for a record the catalogue leaves out", () => {
    expect(
      catalogueItemRoute({
        type: "Equipment",
        slug: "p4-ar-boneyard",
        listed: false,
      }),
    ).toBeUndefined();
  });
});
