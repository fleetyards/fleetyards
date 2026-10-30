import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  HangarPlanStartKindEnum,
  HangarPlanVehicleMarkEnum,
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
} from "@/services/fyApi";
import { useHangarPlanPairing } from "./useHangarPlanPairing";

const plan = {
  id: "plan",
  vehicleMarks: [],
  slots: [
    { id: "old", candidates: [] },
    { id: "new", candidates: [{ id: "candidate-new" }] },
  ],
} as unknown as HangarPlan;

const calls: [string, unknown][] = [];
const mutation = (name: string) => ({
  mutateAsync: vi.fn((input: unknown) => {
    calls.push([name, input]);
    return Promise.resolve(plan);
  }),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useChooseHangarPlanSlotCandidate: () => mutation("choose"),
  useCreateHangarPlanAcquisition: () => mutation("createAcquisition"),
  useUpdateHangarPlanAcquisition: () => mutation("updateAcquisition"),
  useDestroyHangarPlanAcquisition: () => mutation("destroyAcquisition"),
  useCreateHangarPlanSlot: () => mutation("createSlot"),
  useCreateHangarPlanCandidate: () => mutation("createCandidate"),
  useCreateHangarPlanKeep: () => mutation("keep"),
  useCreateHangarPlanVehicleMark: () => mutation("createMark"),
  useUpdateHangarPlanVehicleMark: () => mutation("updateMark"),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn(), refreshDerived: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert: vi.fn() }),
}));

const carrack = {
  id: "candidate-carrack",
  model: { id: "carrack", name: "Carrack" },
} as HangarPlanCandidate;

const route = { id: "route" } as HangarPlanAcquisition;

describe("useHangarPlanPairing", () => {
  beforeEach(() => {
    calls.length = 0;
  });

  it("starts a slot's ship from a hangar ship, or buys it outright", async () => {
    const { pairStart } = useHangarPlanPairing("plan", plan);

    await pairStart(carrack, { kind: "owned", vehicleId: "vehicle" });
    await pairStart(carrack, { kind: "store" }, route);

    expect(calls).toEqual([
      [
        "createAcquisition",
        {
          hangarPlanId: "plan",
          data: {
            candidateId: "candidate-carrack",
            startKind: HangarPlanStartKindEnum.OWNED,
            sourceVehicleId: "vehicle",
            buybackPledgeId: null,
            startModelId: null,
          },
        },
      ],
      [
        "updateAcquisition",
        {
          hangarPlanId: "plan",
          id: "route",
          // A new start leaves the old upgrades leading from somewhere else.
          data: {
            startKind: HangarPlanStartKindEnum.STORE,
            sourceVehicleId: null,
            buybackPledgeId: null,
            startModelId: "carrack",
            steps: [],
          },
        },
      ],
    ]);
  });

  it("ends a hangar ship on a new ship in a slot of its own", async () => {
    const { pairEnd } = useHangarPlanPairing("plan", plan);

    await pairEnd(
      { kind: "model", modelId: "vulture", name: "Vulture" },
      { vehicleId: "vehicle" },
    );

    expect(calls.map(([name]) => name)).toEqual([
      "createSlot",
      "createCandidate",
      "createAcquisition",
    ]);
    expect(calls[1][1]).toEqual({
      hangarPlanId: "plan",
      data: { slotId: "new", modelId: "vulture" },
    });
    expect(calls[2][1]).toMatchObject({
      data: { candidateId: "candidate-new", sourceVehicleId: "vehicle" },
    });
  });

  it("moves a route to another ship, and keeps or releases a hangar ship", async () => {
    const { pairEnd } = useHangarPlanPairing("plan", plan);

    await pairEnd(
      { kind: "candidate", candidate: carrack },
      { acquisition: route },
    );
    await pairEnd(
      { kind: "same" },
      { vehicleId: "vehicle", acquisition: route },
    );
    await pairEnd({ kind: "remove" }, { vehicleId: "vehicle" });

    expect(calls).toEqual([
      [
        "updateAcquisition",
        {
          hangarPlanId: "plan",
          id: "route",
          data: { candidateId: "candidate-carrack", steps: [] },
        },
      ],
      ["destroyAcquisition", { hangarPlanId: "plan", id: "route" }],
      ["keep", { hangarPlanId: "plan", data: { vehicleIds: ["vehicle"] } }],
      [
        "createMark",
        {
          hangarPlanId: "plan",
          data: {
            vehicleId: "vehicle",
            mark: HangarPlanVehicleMarkEnum.PENDING,
          },
        },
      ],
    ]);
  });

  it("settles a slot still choosing its ship on the one a start is for", async () => {
    const { decide } = useHangarPlanPairing("plan", plan);

    await decide(plan.slots[0], carrack);

    expect(calls).toEqual([
      [
        "choose",
        {
          hangarPlanId: "plan",
          id: "old",
          data: { candidateId: "candidate-carrack" },
        },
      ],
    ]);
  });
});
