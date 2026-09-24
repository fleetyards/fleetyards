import { describe, expect, it, vi } from "vitest";
import type { Fleet, FilterOption } from "@/services/fyApi";
import { useSquadronVisibility } from "./useSquadronVisibility";

const enabled = ref(false);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFleetFeatureEnabled: () => enabled.value }),
}));

const options: FilterOption[] = [
  { value: "members_only", label: "Members" },
  { value: "squadron_only", label: "Squadron" },
];

const values = (current: string | null) =>
  useSquadronVisibility({ slug: "maru" } as Fleet, "squadron_only", current)
    .withSquadronChoice(options)
    .map((option) => option.value);

describe("useSquadronVisibility", () => {
  it("offers the squadron choice where the fleet has squadrons", () => {
    enabled.value = true;

    expect(values("members_only")).toEqual(["members_only", "squadron_only"]);
  });

  it("leaves it out where the fleet has none", () => {
    enabled.value = false;

    expect(values("members_only")).toEqual(["members_only"]);
  });

  it("keeps it for a record already held to squadrons", () => {
    enabled.value = false;

    expect(values("squadron_only")).toEqual(["members_only", "squadron_only"]);
  });
});
