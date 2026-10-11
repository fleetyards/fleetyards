import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref, toValue } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type {
  Fleet,
  FleetMember,
  FleetMemberHealth,
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

// The roster table is the members page's own and tested there; here only which
// rows reach it matters.
vi.mock("@/frontend/components/Fleets/MembersList/index.vue", () => ({
  default: defineComponent({
    props: { members: { type: Array, default: () => [] } },
    setup(props) {
      return () =>
        h(
          "ul",
          { "data-test": "members-list" },
          (props.members as FleetMember[]).map((member) =>
            h("li", member.username),
          ),
        );
    },
  }),
}));

const Stub = defineComponent({ render: () => h("div") });

const member = (username: string) =>
  ({ id: username, username }) as FleetMember;

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
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      membership: {
        capabilities: { readMembers: true, updateMembers: true },
      } as FleetMember,
    },
    plugins: [router],
  });
};

const section = (subject: Awaited<ReturnType<typeof mount>>, name: string) =>
  subject.find(`[data-test='health-${name}']`);

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

  it("lists the inactive members and links to the rest", async () => {
    health = healthWith({
      inactiveMembers: {
        totalCount: 12,
        items: [member("gone"), member("away")],
      },
    });

    const subject = await mount();
    const inactive = section(subject, "inactive");

    expect(inactive.text()).toContain("12");
    expect(
      inactive.findAll("[data-test='members-list'] li").map((li) => li.text()),
    ).toEqual(["gone", "away"]);

    const href = inactive
      .find("[data-test='health-inactive-all']")
      .attributes("href");
    expect(href).toContain("#/f/maru/members?");
    expect(href).toContain("inactiveSince=");
    expect(href).toContain("lastActiveAt+asc");
  });

  it("offers no link to the rest when every member is shown", async () => {
    health = healthWith({
      inactiveMembers: { totalCount: 1, items: [member("gone")] },
    });

    const subject = await mount();

    expect(subject.find("[data-test='health-inactive-all']").exists()).toBe(
      false,
    );
  });

  it("leaves out the verification check for a fleet without an RSI SID", async () => {
    const subject = await mount();

    expect(section(subject, "unverified").exists()).toBe(false);
  });

  it("warns that nobody shows as verified while the fleet's SID is unproven", async () => {
    health = healthWith({
      fleetRsiVerified: false,
      unverifiedMembers: { totalCount: 1, items: [member("stranger")] },
    });

    const subject = await mount();

    expect(
      section(subject, "unverified")
        .find("[data-test='health-fleet-unverified']")
        .exists(),
    ).toBe(true);
  });

  it("links the empty roles to the role settings", async () => {
    health = healthWith({
      emptyRoles: [{ id: "r", name: "Officer", slug: "officer" }],
    });

    const subject = await mount();
    const roles = section(subject, "empty-roles");

    expect(roles.find("[data-test='health-empty-role-officer']").text()).toBe(
      "Officer",
    );
    expect(
      roles.find("[data-test='health-roles-settings']").attributes("href"),
    ).toBe("#/f/maru/settings/roles");
  });

  it("leaves out empty roles for a reader who cannot read roles", async () => {
    const subject = await mount();

    expect(section(subject, "empty-roles").exists()).toBe(false);
  });
});
