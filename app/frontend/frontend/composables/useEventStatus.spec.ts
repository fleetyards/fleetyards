import { describe, expect, it } from "vitest";
import { useEventStatus } from "./useEventStatus";
import { FleetEventSignupStatusEnum } from "@/services/fyApi";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

const { signupPillVariantFor } = useEventStatus();

describe("signupPillVariantFor", () => {
  it("colours only a commitment either way", () => {
    expect(signupPillVariantFor(FleetEventSignupStatusEnum.CONFIRMED)).toBe(
      PillVariantsEnum.SUCCESS,
    );
    expect(signupPillVariantFor(FleetEventSignupStatusEnum.TENTATIVE)).toBe(
      PillVariantsEnum.WARNING,
    );
  });

  // Withdrawn was missing from the dashboard's own map, so it fell back to the
  // primary blue there while the event page showed it neutral.
  it.each([
    FleetEventSignupStatusEnum.INTERESTED,
    FleetEventSignupStatusEnum.PENDING,
    FleetEventSignupStatusEnum.WITHDRAWN,
  ])("keeps %s neutral", (status) => {
    expect(signupPillVariantFor(status)).toBe(PillVariantsEnum.NEUTRAL);
  });

  it("stays neutral for a status it does not know", () => {
    expect(signupPillVariantFor("unknown")).toBe(PillVariantsEnum.NEUTRAL);
    expect(signupPillVariantFor(undefined)).toBe(PillVariantsEnum.NEUTRAL);
  });
});
