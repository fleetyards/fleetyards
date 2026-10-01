import { describe, expect, it } from "vitest";
import {
  catalogueTokenIcon,
  catalogueTokenName,
  catalogueTokenPrefix,
} from "./CatalogueTokens";

describe("catalogueTokenName", () => {
  it("shows the name after a known prefix, and the whole of any other", () => {
    expect(catalogueTokenName("commodity:Mercury")).toBe("Mercury");
    expect(catalogueTokenName("Mk2: Deluxe")).toBe("Mk2: Deluxe");
    expect(catalogueTokenName("user:mortik")).toBe("mortik");
  });

  it("shows a contract's or an event's title without its fleet", () => {
    expect(catalogueTokenName("contract:MARU/Salvage Run")).toBe("Salvage Run");
    expect(catalogueTokenName("event: MARU / Weekly Mining")).toBe(
      "Weekly Mining",
    );
    expect(catalogueTokenName("event:MARU/Ops 1/2")).toBe("Ops 1/2");
    expect(catalogueTokenName("contract:Salvage Run")).toBe("Salvage Run");
  });
});

describe("catalogueTokenPrefix", () => {
  it("reads the new prefixes in any case", () => {
    expect(catalogueTokenPrefix("Contract:MARU/Run")).toBe("contract");
    expect(catalogueTokenPrefix("USER:mortik")).toBe("user");
    expect(catalogueTokenPrefix("fleet:MARU")).toBeUndefined();
  });
});

describe("catalogueTokenIcon", () => {
  it("gives a prefix and the type the lookup answers the same icon", () => {
    expect(catalogueTokenIcon("contract")).toBe(
      catalogueTokenIcon("FleetContract"),
    );
    expect(catalogueTokenIcon("event")).toBe(catalogueTokenIcon("FleetEvent"));
    expect(catalogueTokenIcon("user")).toBe(catalogueTokenIcon("User"));
  });
});
