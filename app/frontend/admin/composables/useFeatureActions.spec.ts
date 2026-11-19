import { describe, it, expect, vi } from "vitest";

const api = vi.hoisted(() => ({
  enableAdminFeatureGroup: vi.fn(),
  disableAdminFeature: vi.fn(),
}));

vi.mock("@/services/fyAdminApi", () => ({
  ...api,
  getAdminFeaturesQueryKey: () => ["features"],
}));

vi.mock("@tanstack/vue-query", () => ({
  useQueryClient: () => ({ invalidateQueries: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

import { useFeatureActions } from "./useFeatureActions";

describe("useFeatureActions", () => {
  // The detail page's header and panels each hold their own actions; a write in
  // one has to hold back the others.
  it("is busy everywhere the same flag is edited while a write runs", async () => {
    let finish: (value?: unknown) => void = () => {};
    api.enableAdminFeatureGroup.mockReturnValue(
      new Promise((resolve) => {
        finish = resolve;
      }),
    );

    const panel = useFeatureActions("fleet_tours");
    const header = useFeatureActions("fleet_tours");
    const other = useFeatureActions("hangar_planner");

    const write = panel.addGroup("testers");

    expect(header.busy.value).toBe(true);
    expect(other.busy.value).toBe(false);

    finish();
    await write;

    expect(header.busy.value).toBe(false);
  });

  it("clears the busy state when a write fails", async () => {
    api.disableAdminFeature.mockRejectedValue(new Error("nope"));

    const actions = useFeatureActions("fleet_tours");

    expect(await actions.setGlobal(false)).toBe(false);
    expect(actions.busy.value).toBe(false);
  });
});
