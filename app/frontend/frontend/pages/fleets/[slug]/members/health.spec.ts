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
    useFleetSquadrons: () => ({
      data: computed(() => ({
        items: [{ id: "s", name: "Alpha Wing", slug: "alpha", team: false }],
      })),
    }),
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
  admin: false,
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
  inactiveSince: "2026-09-12",
  requestedBefore: "2026-10-05",
  invitedBefore: "2026-09-28",
  fleetRsiVerified: true,
  rsiMemberCount: null,
  memberCount: 10,
  hiddenShipsCount: 0,
  admins: { ...section([member("aria", { leader: true })], 2), candidates: [] },
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
      {
        path: "/f/:slug/squadrons/:squadron/members",
        name: "fleet-squadron-members",
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
          manageSquadronMembers: true,
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
      admins: {
        ...section([member("aria", { leader: true })]),
        candidates: [],
      },
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
    health = healthWith({
      admins: {
        ...section([member("aria")]),
        candidates: [
          member("nyx", {
            fleetRole: { id: "o", name: "Officer", slug: "officer" },
          }),
        ],
      },
    });

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
    expect(href).toContain("inactiveSince=2026-09-12");
    expect(href).toContain("lastActiveAt+asc");
  });

  it("links waiting requests and invitations to just those", async () => {
    health = healthWith({
      waitingJoinRequests: section([member("asker")], 8),
      unansweredInvitations: section([member("invitee")], 6),
    });

    const subject = await mount();

    const requests = subject
      .find("[data-test='health-joinRequests-all']")
      .attributes("href");
    expect(requests).toContain("stateIn=requested");
    expect(requests).toContain("requestedAtLteq=2026-10-05");

    const invitations = subject
      .find("[data-test='health-invitations-all']")
      .attributes("href");
    expect(invitations).toContain("stateIn=invited");
    expect(invitations).toContain("invitedAtLteq=2026-09-28");
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

  it("leaves out checks that do not apply", async () => {
    const subject = await mount();

    [
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

  it("offers to add a member in no squadron to one", async () => {
    health = healthWith({ membersWithoutSquadron: section([member("ward")]) });

    const subject = await mount();
    const row = subject.find("[data-test='health-noSquadron-ward']");

    expect(row.find("[data-test='health-add-to-squadron']").exists()).toBe(
      true,
    );
    expect(row.find("[data-test='health-remove']").exists()).toBe(false);
  });

  it("offers removal only where the org list does not name the fleet", async () => {
    health = healthWith({
      membersWithoutRsiHandle: null,
      unverifiedMembers: section([
        member("vesna", { verificationGap: "org_not_listed" }),
        member("grimsby", { verificationGap: "no_handle" }),
      ]),
    });

    const subject = await mount();

    expect(
      subject
        .find(
          "[data-test='health-unverified-vesna'] [data-test='health-remove']",
        )
        .exists(),
    ).toBe(true);
    expect(
      subject
        .find(
          "[data-test='health-unverified-grimsby'] [data-test='health-remove']",
        )
        .exists(),
    ).toBe(false);
  });

  it("offers demotion only to an inactive officer", async () => {
    health = healthWith({
      inactiveMembers: section([
        member("kestrel", { leader: true }),
        member("gone"),
      ]),
    });

    const subject = await mount();

    expect(
      subject
        .find(
          "[data-test='health-inactive-kestrel'] [data-test='health-demote']",
        )
        .exists(),
    ).toBe(true);
    expect(
      subject
        .find("[data-test='health-inactive-gone'] [data-test='health-demote']")
        .exists(),
    ).toBe(false);
  });

  // The permanent role cannot be removed, and its last holder not demoted.
  it("offers an inactive admin neither removal nor a last-admin demotion", async () => {
    health = healthWith({
      admins: {
        ...section([member("aria", { leader: true, admin: true })]),
        candidates: [],
      },
      inactiveMembers: section([member("aria", { leader: true, admin: true })]),
    });

    const subject = await mount();
    const row = subject.find("[data-test='health-inactive-aria']");

    expect(row.find("[data-test='health-remove']").exists()).toBe(false);
    expect(row.find("[data-test='health-demote']").exists()).toBe(false);
  });

  it("offers no removal to an admin missing from the RSI org", async () => {
    health = healthWith({
      membersWithoutRsiHandle: null,
      unverifiedMembers: section([
        member("aria", { admin: true, verificationGap: "org_not_listed" }),
      ]),
    });

    const subject = await mount();
    const row = subject.find("[data-test='health-unverified-aria']");

    expect(row.find("[data-test='health-remind']").exists()).toBe(true);
    expect(row.find("[data-test='health-remove']").exists()).toBe(false);
  });

  it("offers an inactive admin demotion while another admin is left", async () => {
    health = healthWith({
      inactiveMembers: section([member("aria", { leader: true, admin: true })]),
    });

    const subject = await mount();
    const row = subject.find("[data-test='health-inactive-aria']");

    expect(row.find("[data-test='health-remove']").exists()).toBe(false);
    expect(row.find("[data-test='health-demote']").exists()).toBe(true);
  });

  it("asks an unverified member to verify, once a week", async () => {
    health = healthWith({
      membersWithoutRsiHandle: null,
      unverifiedMembers: section([
        member("tal", {
          verificationGap: "handle_unverified",
          rsiHandle: "Tal",
        }),
        member("vesna", {
          verificationGap: "handle_unverified",
          verificationRemindedAt: new Date().toISOString(),
        }),
      ]),
    });

    const subject = await mount();
    const remind = (username: string) =>
      subject.find(
        `[data-test='health-unverified-${username}'] [data-test='health-remind']`,
      );

    expect(remind("tal").attributes("disabled")).toBeUndefined();
    expect(remind("vesna").attributes("disabled")).toBeDefined();
    expect(
      subject
        .find(
          "[data-test='health-unverified-tal'] [data-test='health-contact']",
        )
        .exists(),
    ).toBe(true);
    // The icon-only trigger names itself, on the button that takes focus.
    expect(
      subject
        .find(
          "[data-test='health-unverified-tal'] [data-test='health-contact'] button",
        )
        .attributes("aria-label"),
    ).toBe("Contact");
  });

  it("withdraws an unanswered invitation rather than removing a member", async () => {
    health = healthWith({
      unansweredInvitations: section([
        member("mira", { invitedAt: "2026-09-01T00:00:00Z" }),
      ]),
    });

    const subject = await mount();
    const row = subject.find("[data-test='health-invitations-mira']");

    expect(row.find("[data-test='health-revoke']").exists()).toBe(true);
    expect(row.find("[data-test='health-remove']").exists()).toBe(false);
  });
});
