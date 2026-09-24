import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import {
  type Fleet,
  type FleetContract,
  type FleetMember,
  FleetContractCrewRoleEnum,
  FleetContractCrewStateEnum,
  FleetContractStateEnum,
} from "@/services/fyApi";
import Component from "./[contract].vue";

const Stub = defineComponent({ name: "PageStub", render: () => h("div") });

const routerWithRoutes = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleet", name: "fleet", component: Stub },
      { path: "/contracts", name: "fleet-contracts", component: Stub },
      { path: "/contracts/:contract", name: "fleet-contract", component: Stub },
      {
        path: "/contracts/:contract/edit",
        name: "fleet-contract-edit",
        component: Stub,
      },
    ],
  });

  await router.push("/contracts/haul");
  await router.isReady();

  return router;
};

const CONTRACTOR_ID = "11111111-1111-4111-8111-111111111111";

const current = ref<FleetContract | undefined>();

const contract = (state: FleetContractStateEnum): FleetContract =>
  ({
    id: "contract",
    slug: "haul",
    title: "Haul",
    kind: "procurement",
    state,
    reward: "1000.0",
    deadline: null,
    requiresPickup: false,
    progress: { complete: false, fraction: 0.5, lines: [], shares: [] },
    crew: [
      {
        id: "seat",
        role: FleetContractCrewRoleEnum.LEAD,
        state: FleetContractCrewStateEnum.ACCEPTED,
        user: { id: CONTRACTOR_ID, username: "hauler" },
      },
    ],
  }) as unknown as FleetContract;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  const mutation = () => ({ mutateAsync: vi.fn() });

  return {
    ...actual,
    useFleetContract: () => ({
      data: current,
      isLoading: ref(false),
      refetch: vi.fn(),
    }),
    usePublishFleetContract: mutation,
    useClaimFleetContract: mutation,
    useReleaseFleetContract: mutation,
    useFulfilFleetContract: mutation,
    useCancelFleetContract: mutation,
    useJoinFleetContractCrew: mutation,
    useAcceptFleetContractCrew: mutation,
    useDeclineFleetContractCrew: mutation,
    useLeaveFleetContractCrew: mutation,
  };
});

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ currentUser: { id: CONTRACTOR_ID } }),
}));

let wrapper: VueWrapper | undefined;
let teleportTarget: HTMLElement | undefined;

beforeEach(() => {
  teleportTarget = document.createElement("div");
  teleportTarget.id = "header-right";
  document.body.appendChild(teleportTarget);
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  teleportTarget?.remove();
  teleportTarget = undefined;
  current.value = undefined;
});

const mount = async (state: FleetContractStateEnum) => {
  current.value = contract(state);

  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      membership: {} as FleetMember,
      resourceAccess: ["fleet:contracts:read"],
    },
    plugins: [await routerWithRoutes()],
  });

  return wrapper;
};

describe("FleetContractPage", () => {
  it("invites the crew to deliver while the contract is in progress", async () => {
    const subject = await mount(FleetContractStateEnum.IN_PROGRESS);

    expect(subject.find("[data-test='contract-deliver-hint']").exists()).toBe(
      true,
    );
    expect(subject.find("[data-test='contract-expired-hint']").exists()).toBe(
      false,
    );
  });

  // New linked transfers are refused once it has expired; only the ones
  // already on their way can still land.
  it("stops inviting deliveries once the contract has expired", async () => {
    const subject = await mount(FleetContractStateEnum.EXPIRED);

    expect(subject.find("[data-test='contract-deliver-hint']").exists()).toBe(
      false,
    );
    expect(subject.find("[data-test='contract-expired-hint']").exists()).toBe(
      true,
    );
  });

  it("shows neither hint on a fulfilled contract", async () => {
    const subject = await mount(FleetContractStateEnum.FULFILLED);

    expect(subject.find("[data-test='contract-deliver-hint']").exists()).toBe(
      false,
    );
    expect(subject.find("[data-test='contract-expired-hint']").exists()).toBe(
      false,
    );
  });
});
