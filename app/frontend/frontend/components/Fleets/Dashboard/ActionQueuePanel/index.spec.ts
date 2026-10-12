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

const none = { totalCount: 0, items: [] };

const healthWith = (
  overrides: Partial<FleetMemberHealth> = {},
): FleetMemberHealth => ({
  inactiveDays: 30,
  inactiveSince: "2026-09-12",
  requestedBefore: "2026-10-05",
  invitedBefore: "2026-09-28",
  fleetRsiVerified: true,
  rsiMemberCount: null,
  memberCount: 10,
  hiddenShipsCount: 0,
  admins: { totalCount: 2, items: [], candidates: [] },
  unverifiedMembers: null,
  membersWithoutRsiHandle: none,
  inactiveMembers: none,
  waitingJoinRequests: none,
  unansweredInvitations: none,
  staleInviteUrls: null,
  membersWithoutDiscord: null,
  membersWithoutSquadron: null,
  emptySquadrons: null,
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

  // Checks, not members: forty inactive members are one thing to look at.
  it("links to the health page with the checks that need attention counted", async () => {
    health = healthWith({
      inactiveMembers: { totalCount: 4, items: [] },
      unverifiedMembers: { totalCount: 2, items: [] },
      waitingJoinRequests: { totalCount: 1, items: [] },
    });

    const subject = await mount({ canCheckMemberHealth: true });

    expect(healthLink(subject).attributes("href")).toBe(
      "#/f/maru/members/health",
    );
    expect(healthLink(subject).text()).toContain("3");
  });

  // Hidden hangars are worth knowing, not something to answer.
  it("stays quiet when nothing needs attention", async () => {
    health = healthWith({ hiddenShipsCount: 4 });

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
