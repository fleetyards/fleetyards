import { describe, expect, it } from "vitest";
import { movedFleetSlug } from "./useMovedFleetRedirect";

const completed = (link: string) => ({
  notificationType: "fleet_fid_claim_completed",
  link,
});

describe("movedFleetSlug", () => {
  it("follows a holder from X to X-N", () => {
    expect(
      movedFleetSlug(completed("/fleets/maru-1/settings/rsi/"), "maru"),
    ).toBe("maru-1");
  });

  it("follows a claimant from X-N to X", () => {
    expect(
      movedFleetSlug(completed("/fleets/maru/settings/rsi/"), "maru-1"),
    ).toBe("maru");
  });

  it("stays on an unrelated fleet", () => {
    expect(
      movedFleetSlug(completed("/fleets/maru-1/settings/rsi/"), "other"),
    ).toBeUndefined();
  });

  it("stays on the page when it already is the new address", () => {
    expect(
      movedFleetSlug(completed("/fleets/maru-1/settings/rsi/"), "maru-1"),
    ).toBeUndefined();
  });

  it("ignores every other notification", () => {
    expect(
      movedFleetSlug(
        { notificationType: "fleet_fid_claim_opened", link: "/fleets/maru-1/" },
        "maru",
      ),
    ).toBeUndefined();
  });

  it("does nothing off a fleet page", () => {
    expect(
      movedFleetSlug(completed("/fleets/maru-1/settings/rsi/"), undefined),
    ).toBeUndefined();
  });
});
