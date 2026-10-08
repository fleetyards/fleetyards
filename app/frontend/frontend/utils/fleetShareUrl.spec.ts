import { afterEach, describe, expect, it } from "vitest";
import { fleetShipsShareUrl } from "./fleetShareUrl";

const fleet = { fid: "FY", slug: "fleetyards" };

describe("fleetShipsShareUrl", () => {
  afterEach(() => {
    window.SHORT_DOMAIN = "";
  });

  describe("with a short domain", () => {
    it("links the ships by FID", () => {
      window.SHORT_DOMAIN = "fltyrd.net";

      expect(fleetShipsShareUrl(fleet)).toBe(
        `${window.location.protocol}//fltyrd.net/f/FY/ships`,
      );
    });
  });

  describe("without a short domain", () => {
    it("links the ships page by slug", () => {
      expect(fleetShipsShareUrl(fleet)).toBe(
        `${window.location.origin}/fleets/fleetyards/ships`,
      );
    });
  });
});
