import { describe, expect, it } from "vitest";
import { landingServicesText } from "./LandingServices";

const t = (key: string) => key.split(".").pop() as string;

describe("landingServicesText", () => {
  it("reads both fuels as one refuel, then rearm and repair", () => {
    expect(
      landingServicesText(
        {
          landingServices: [
            "repair",
            "rearm",
            "quantum_refuel",
            "hydrogen_refuel",
          ],
        },
        t,
      ),
    ).toBe("refuel, rearm, repair");
  });

  it("names the one fuel a ship offers alone", () => {
    expect(
      landingServicesText({ landingServices: ["hydrogen_refuel"] }, t),
    ).toBe("hydrogenRefuel");
    expect(
      landingServicesText({ landingServices: ["quantum_refuel", "repair"] }, t),
    ).toBe("quantumRefuel, repair");
  });

  it("says nothing for a ship that services none", () => {
    expect(landingServicesText({ landingServices: [] }, t)).toBeUndefined();
    expect(landingServicesText({}, t)).toBeUndefined();
  });
});
