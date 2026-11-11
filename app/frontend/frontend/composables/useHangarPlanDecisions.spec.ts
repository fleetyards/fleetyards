import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { HangarPlan, HangarPlanComparison } from "@/services/fyApi";
import { useHangarPlanDecisions } from "./useHangarPlanDecisions";

const calls: [string, unknown][] = [];
const mutation = (name: string) => ({
  mutateAsync: vi.fn((input: unknown) => {
    calls.push([name, input]);
    return Promise.resolve({});
  }),
});

const comlinkEmit = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCreateHangarPlanKeep: () => mutation("keep"),
  useCreateHangarPlanVehicleMark: () => mutation("createMark"),
  useUpdateHangarPlanVehicleMark: () => mutation("updateMark"),
  useDestroyHangarPlanMelt: () => mutation("destroyMelt"),
  useDestroyHangarPlanAcquisition: () => mutation("destroyAcquisition"),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert: vi.fn() }),
}));

const melt = {
  id: "melt",
  vehicleId: "vehicle-ironclad",
  model: { name: "Ironclad Assault" },
  pledgeShips: [],
};

const plan = (routes: unknown[] = []) =>
  ({
    id: "plan",
    vehicleMarks: [],
    melts: [melt],
    slots: [{ starts: [], candidates: [{ acquisitions: routes }] }],
  }) as unknown as HangarPlan;

const comparison = { vehicles: [] } as unknown as HangarPlanComparison;

const confirmed = () => {
  const [[event, options]] = comlinkEmit.mock.calls as [
    [string, { text: string; onConfirm: () => void }],
  ];
  expect(event).toBe("show-confirm");
  return options;
};

describe("useHangarPlanDecisions", () => {
  beforeEach(() => {
    calls.length = 0;
    comlinkEmit.mockClear();
  });

  it("asks before taking a melt back", async () => {
    const { decide } = useHangarPlanDecisions("plan", plan(), comparison);

    decide("vehicle-ironclad", "pending");
    expect(calls).toEqual([]);

    const options = confirmed();
    expect(options.text).toBe("hangarPlanner.unmelt.confirm");

    options.onConfirm();
    await flushPromises();

    expect(calls.map(([name]) => name)).toEqual(["destroyMelt", "createMark"]);
  });

  it("warns that a route buying the pledge back loses its start", () => {
    const { confirmUnmelt } = useHangarPlanDecisions(
      "plan",
      plan([
        {
          id: "route",
          startKind: "melted",
          sourceVehicleId: "vehicle-ironclad",
        },
      ]),
      comparison,
    );

    confirmUnmelt(melt as never, vi.fn());

    expect(confirmed().text).toBe("hangarPlanner.unmelt.confirmRoutes");
  });

  it("leaves a route buying the pledge back to the melt it goes with", async () => {
    const { decide } = useHangarPlanDecisions(
      "plan",
      plan([
        {
          id: "route",
          startKind: "melted",
          sourceVehicleId: "vehicle-ironclad",
        },
      ]),
      comparison,
    );

    decide("vehicle-ironclad", "pending");
    confirmed().onConfirm();
    await flushPromises();

    expect(calls.map(([name]) => name)).not.toContain("destroyAcquisition");
  });
});
