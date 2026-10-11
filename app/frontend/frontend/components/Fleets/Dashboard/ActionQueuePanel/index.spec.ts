import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref, toValue } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetMemberHealth } from "@/services/fyApi";
import Component from "./index.vue";

let health: FleetMemberHealth | undefined;
let healthAsked = false;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  const idle = () => ({
    data: computed(() => undefined),
    isLoading: ref(false),
    isFetching: ref(false),
    isLoadingError: ref(false),
    refetch: vi.fn(),
  });

  return {
    ...actual,
    useFleetMembers: idle,
    useFleetInventoryTransfers: idle,
    useFleetMemberHealth: (
      _slug: unknown,
      _params: unknown,
      options: { query: { enabled: unknown } },
    ) => {
      healthAsked = !!toValue(options.query.enabled);

      return {
        data: computed(() => (healthAsked ? health : undefined)),
        isLoading: ref(false),
        isFetching: ref(false),
        isLoadingError: ref(false),
      };
    },
    useAcceptFleetMember: () => ({ mutateAsync: vi.fn() }),
    useDeclineFleetMember: () => ({ mutateAsync: vi.fn() }),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const healthWith = (
  overrides: Partial<FleetMemberHealth> = {},
): FleetMemberHealth => ({
  inactiveDays: 30,
  inactiveMembers: { totalCount: 0, items: [] },
  fleetRsiVerified: true,
  unverifiedMembers: null,
  emptyRoles: null,
  ...overrides,
});

const mount = async (props: { canCheckMemberHealth?: boolean } = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      {
        path: "/f/:slug/members",
        name: "fleet-members-index",
        component: Stub,
      },
      {
        path: "/f/:slug/members/health",
        name: "fleet-members-health",
        component: Stub,
      },
      {
        path: "/f/:slug/transfers",
        name: "fleet-logistics-transfers",
        component: Stub,
      },
    ],
  });
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru" } as Fleet,
      canAnswerJoinRequests: true,
      canAnswerTransfers: false,
      ...props,
    },
    plugins: [router],
  });
};

const healthLink = (subject: Awaited<ReturnType<typeof mount>>) =>
  subject.find("[data-test='fleet-dashboard-member-health']");

describe("FleetDashboardActionQueuePanel", () => {
  beforeEach(() => {
    health = undefined;
    healthAsked = false;
  });

  it("links to the health page with every loose end counted", async () => {
    health = healthWith({
      inactiveMembers: { totalCount: 4, items: [] },
      unverifiedMembers: { totalCount: 2, items: [] },
      emptyRoles: [{ id: "r", name: "Officer", slug: "officer" }],
    });

    const subject = await mount({ canCheckMemberHealth: true });

    expect(healthLink(subject).attributes("href")).toBe(
      "#/f/maru/members/health",
    );
    expect(healthLink(subject).text()).toContain("7");
  });

  it("stays quiet when nothing needs attention", async () => {
    health = healthWith({ emptyRoles: [] });

    const subject = await mount({ canCheckMemberHealth: true });

    expect(healthLink(subject).exists()).toBe(false);
    expect(subject.find("[data-test='fleet-dashboard-empty']").exists()).toBe(
      true,
    );
  });

  it("does not ask for the roster's health without the right to act on it", async () => {
    health = healthWith({ inactiveMembers: { totalCount: 4, items: [] } });

    const subject = await mount({ canCheckMemberHealth: false });

    expect(healthAsked).toBe(false);
    expect(healthLink(subject).exists()).toBe(false);
  });
});
