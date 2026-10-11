import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref, toValue } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type {
  Fleet,
  FleetMember,
  FleetMemberHealth,
  FleetMemberHealthMember,
  FleetMemberHealthParams,
} from "@/services/fyApi";
import Component from "./health.vue";

let health: FleetMemberHealth;
const asked: (FleetMemberHealthParams | undefined)[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetMemberHealth: (_slug: unknown, params: unknown) => {
      asked.push(toValue(params) as FleetMemberHealthParams);

      return {
        data: computed(() => health),
        isLoading: ref(false),
        isPending: ref(false),
        isFetching: ref(false),
        isRefetching: ref(false),
        error: ref(null),
        refetch: vi.fn(),
      };
    },
  };
});

const Stub = defineComponent({ render: () => h("div") });

const member = (
  username: string,
  overrides: Partial<FleetMemberHealthMember> = {},
): FleetMemberHealthMember => ({
  id: username,
  username,
  leader: false,
  verificationGap: null,
  fleetRole: { id: "r", name: "Member", slug: "member" },
  ...overrides,
});

const section = (
  items: FleetMemberHealthMember[],
  totalCount = items.length,
) => ({
  totalCount,
  items,
});

const healthWith = (
  overrides: Partial<FleetMemberHealth> = {},
): FleetMemberHealth => ({
  inactiveDays: 30,
  fleetRsiVerified: true,
  rsiMemberCount: null,
  memberCount: 10,
  hiddenShipsCount: 0,
  admins: section([member("aria", { leader: true })], 2),
  emptyRoles: null,
  unverifiedMembers: null,
  membersWithoutRsiHandle: section([]),
  inactiveMembers: section([]),
  waitingJoinRequests: section([]),
  unansweredInvitations: section([]),
  staleInviteUrls: null,
  membersWithoutDiscord: null,
  membersWithoutSquadron: null,
  emptySquadrons: null,
  ...overrides,
});

const mount = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/f/:slug", name: "fleet", component: Stub },
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
        path: "/f/:slug/settings/roles",
        name: "fleet-settings-roles",
        component: Stub,
      },
      {
        path: "/f/:slug/settings/rsi",
        name: "fleet-settings-rsi",
        component: Stub,
      },
      {
        path: "/f/:slug/settings/discord",
        name: "fleet-settings-discord",
        component: Stub,
      },
      {
        path: "/f/:slug/squadrons/:squadron",
        name: "fleet-squadron",
        component: Stub,
      },
    ],
  });
  await router.push({
    name: "fleet-members-health",
    params: { slug: "maru" },
    query,
  });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru", rsiSid: "MARU" } as Fleet,
      membership: {
        capabilities: {
          readMembers: true,
          updateMembers: true,
          destroyMembers: true,
        },
      } as FleetMember,
    },
    plugins: [router],
  });
};

type Subject = Awaited<ReturnType<typeof mount>>;

const check = (subject: Subject, key: string) =>
  subject.find(`[data-test='health-${key}']`);

const overviewKeys = (subject: Subject) =>
  subject
    .findAll("[data-test^='health-overview-']")
    .map((item) =>
      item.attributes("data-test")?.replace("health-overview-", ""),
    );

describe("FleetMembersHealthPage", () => {
  beforeEach(() => {
    health = healthWith();
    asked.length = 0;
  });

  it("asks for 30 days unless the page says otherwise", async () => {
    await mount();

    expect(asked.at(-1)).toEqual({ inactiveDays: 30 });
  });

  it("takes the threshold from the URL", async () => {
    await mount({ days: "90" });

    expect(asked.at(-1)).toEqual({ inactiveDays: 90 });
  });

  it("falls back to 30 days for a threshold it does not offer", async () => {
    await mount({ days: "7" });

    expect(asked.at(-1)).toEqual({ inactiveDays: 30 });
  });

  it("lists the worst checks first in the overview", async () => {
    health = healthWith({
      admins: section([member("aria", { leader: true })]),
      inactiveMembers: section([member("gone")]),
      hiddenShipsCount: 3,
    });

    const subject = await mount();

    expect(overviewKeys(subject).slice(0, 3)).toEqual([
      "admins",
      "inactive",
      "hiddenShips",
    ]);
  });

  it("collapses a clear check to one line", async () => {
    const subject = await mount();

    expect(check(subject, "inactive").attributes("data-tone")).toBe("ok");
    expect(subject.find("[data-test^='health-inactive-']").exists()).toBe(
      false,
    );
  });

  it("warns when the fleet has a single admin", async () => {
    health = healthWith({ admins: section([member("aria")]) });

    const subject = await mount();

    expect(check(subject, "admins").attributes("data-tone")).toBe("critical");
    expect(subject.find("[data-test='health-single-admin']").text()).toContain(
      "aria",
    );
  });

  it("marks inactive officers and links to the rest", async () => {
    health = healthWith({
      inactiveMembers: section(
        [
          member("kestrel", { leader: true, lastActiveAt: null }),
          member("gone", { lastActiveAt: "2026-05-01T00:00:00Z" }),
        ],
        12,
      ),
    });

    const subject = await mount();

    expect(
      subject
        .find("[data-test='health-inactive-kestrel'] .health-row__chip--loud")
        .exists(),
    ).toBe(true);
    expect(
      subject
        .find("[data-test='health-inactive-gone'] .health-row__chip--loud")
        .exists(),
    ).toBe(false);

    const href = subject
      .find("[data-test='health-inactive-all']")
      .attributes("href");
    expect(href).toContain("inactiveSince=");
    expect(href).toContain("lastActiveAt+asc");
  });

  it("says why each member is not verified", async () => {
    health = healthWith({
      membersWithoutRsiHandle: null,
      unverifiedMembers: section([
        member("vesna", {
          verificationGap: "org_not_listed",
          rsiOrganizationsCheckedAt: "2026-10-01T00:00:00Z",
        }),
        member("grimsby", { verificationGap: "no_handle" }),
      ]),
      rsiMemberCount: 40,
    });

    const subject = await mount();

    expect(
      subject.find("[data-test='health-unverified-vesna']").text(),
    ).toContain("MARU");
    expect(subject.find("[data-test='health-org-stats']").text()).toContain(
      "30",
    );
  });

  it("warns that nobody shows as verified while the fleet's SID is unproven", async () => {
    health = healthWith({
      fleetRsiVerified: false,
      membersWithoutRsiHandle: null,
      unverifiedMembers: section([member("stranger")]),
    });

    const subject = await mount();

    expect(subject.find("[data-test='health-fleet-unverified']").exists()).toBe(
      true,
    );
  });

  it("answers a waiting join request in place", async () => {
    health = healthWith({
      waitingJoinRequests: section([
        member("bria", { requestedAt: "2026-09-30T00:00:00Z" }),
      ]),
    });

    const subject = await mount();
    const row = subject.find("[data-test='health-joinRequests-bria']");

    expect(row.find("[data-test='health-accept']").exists()).toBe(true);
    // A request is not on the roster, only in the invites view.
    const href = row.find(".health-row__title").attributes("href");
    expect(href).toContain("view=invites");
    expect(href).toContain("searchCont=bria");
    expect(row.find("[data-test='health-decline']").exists()).toBe(true);
  });

  it("links the empty roles to the role settings", async () => {
    health = healthWith({
      emptyRoles: [{ id: "r", name: "Officer", slug: "officer" }],
    });

    const subject = await mount();

    expect(subject.find("[data-test='health-empty-role-officer']").text()).toBe(
      "Officer",
    );
    expect(
      subject.find("[data-test='health-roles-settings']").attributes("href"),
    ).toBe("#/f/maru/settings/roles");
  });

  it("leaves out checks that do not apply", async () => {
    const subject = await mount();

    [
      "emptyRoles",
      "unverified",
      "inviteUrls",
      "discord",
      "emptySquadrons",
      "noSquadron",
    ].forEach((key) => {
      expect(check(subject, key).exists()).toBe(false);
    });
  });

  it("puts an empty squadron above members in none", async () => {
    health = healthWith({
      emptySquadrons: {
        totalCount: 1,
        items: [
          {
            id: "s",
            name: "Salvage Wing",
            slug: "salvage",
            team: false,
            createdAt: "2026-08-01T00:00:00Z",
          },
        ],
      },
      membersWithoutSquadron: section([member("ward")]),
    });

    const subject = await mount();
    const keys = subject
      .findAll("section[data-test^='health-']")
      .map((node) => node.attributes("data-test"));

    expect(keys.indexOf("health-emptySquadrons")).toBeLessThan(
      keys.indexOf("health-noSquadron"),
    );
  });
});
