import { describe, expect, it } from "vitest";
import { plaqueShareUrl } from "./shareUrl";

describe("plaqueShareUrl", () => {
  it("opens the owner's public hangar on the plaque", () => {
    const url = new URL(plaqueShareUrl("TorlekMaru", "vehicle-1"));

    expect(url.pathname).toBe("/hangar/TorlekMaru/");
    expect(url.searchParams.get("plaque")).toBe("vehicle-1");
    expect(url.searchParams.has("share")).toBe(false);
  });

  it("keeps a hangar share token, so a private hangar's plaque still opens", () => {
    const url = new URL(plaqueShareUrl("TorlekMaru", "vehicle-1", "token"));

    expect(url.searchParams.get("share")).toBe("token");
  });
});
