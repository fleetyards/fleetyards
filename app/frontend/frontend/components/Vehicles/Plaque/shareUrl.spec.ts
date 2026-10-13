import { describe, expect, it } from "vitest";
import { plaqueShareUrl } from "./shareUrl";

describe("plaqueShareUrl", () => {
  const id = "e143180d-44fc-44a6-af11-2c03990b8a30";

  it("names the ship by its serial and name where the public may see them", () => {
    const url = new URL(
      plaqueShareUrl("TorlekMaru", {
        id,
        name: "Contorta",
        serial: "L8-4261-HA",
      }),
    );

    expect(url.pathname).toBe("/hangar/TorlekMaru/");
    expect(url.searchParams.get("plaque")).toBe("l8-4261-ha-contorta");
    expect(url.searchParams.has("share")).toBe(false);
  });

  it("falls back to the id when the name and serial are hidden", () => {
    const url = new URL(plaqueShareUrl("TorlekMaru", { id }));

    expect(url.searchParams.get("plaque")).toBe(id);
  });

  it("keeps a hangar share token, so a private hangar's plaque still opens", () => {
    const url = new URL(plaqueShareUrl("TorlekMaru", { id }, "token"));

    expect(url.searchParams.get("share")).toBe("token");
  });
});
