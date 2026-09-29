import { describe, expect, it } from "vitest";
import { movedFleetSlug } from "./useMovedFleetRedirect";

const completed = (link: string) => ({
  notificationType: "fleet_fid_claim_completed",
  link,
});

describe("movedFleetSlug", () => {
  it("follows a holder from X to X-N", () => {
    expect(
      movedFleetSlug(
        completed("/fleets/maru-1/settings/rsi/"),
        "maru",
        ["maru"],
        ["maru-1"],
      ),
    ).toBe("maru-1");
  });

  it("follows a claimant from whatever FID it started with", () => {
    expect(
      movedFleetSlug(
        completed("/fleets/maru/settings/rsi/"),
        "maru-temp",
        ["maru-temp", "other"],
        ["maru", "other"],
      ),
    ).toBe("maru");
  });

  it("never moves a page showing somebody else's fleet", () => {
    expect(
      movedFleetSlug(
        completed("/fleets/maru-1/settings/rsi/"),
        "maru",
        ["mine"],
        ["mine", "maru-1"],
      ),
    ).toBeUndefined();
  });

  it("stays on a fleet of the reader's that did not move", () => {
    expect(
      movedFleetSlug(
        completed("/fleets/maru-1/settings/rsi/"),
        "other",
        ["maru", "other"],
        ["maru-1", "other"],
      ),
    ).toBeUndefined();
  });

  it("stays on the page when it already is the new address", () => {
    expect(
      movedFleetSlug(
        completed("/fleets/maru-1/settings/rsi/"),
        "maru-1",
        ["maru-1"],
        ["maru-1"],
      ),
    ).toBeUndefined();
  });

  it("ignores every other notification", () => {
    expect(
      movedFleetSlug(
        { notificationType: "fleet_fid_claim_opened", link: "/fleets/maru-1/" },
        "maru",
        ["maru"],
        ["maru-1"],
      ),
    ).toBeUndefined();
  });
});
