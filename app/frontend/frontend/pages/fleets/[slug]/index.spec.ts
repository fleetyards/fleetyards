import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { computed, defineComponent, h, ref, watchEffect, type Ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import {
  FeatureFlagName,
  FleetMembershipStatusEnum,
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  type PublicFleetSquadron,
} from "@/services/fyApi";
import Component from "./index.vue";

const memberSquadrons = [
  { id: "a", name: "Combat Wing", slug: "combat-wing", team: false },
  { id: "b", name: "Rescue Team", slug: "rescue-team", team: true },
] as FleetSquadron[];

let publicSquadrons: PublicFleetSquadron[] = [];
let memberAsked: (boolean | undefined)[] = [];
let publicAsked: (boolean | undefined)[] = [];
let cachedMember = false;

type QueryOptions = { query?: { enabled?: Ref<boolean> } };

// Tracks `enabled` as it changes, and keeps what it fetched once it is turned
// off again, the way vue-query holds a result in its cache.
const queryMock = (
  options: QueryOptions | undefined,
  asked: (boolean | undefined)[],
  items: () => unknown[],
  cached = false,
) => {
  const fetched = ref(cached);

  watchEffect(() => {
    const enabled = options?.query?.enabled?.value;
    asked.push(enabled);
    if (enabled) fetched.value = true;
  });

  return {
    data: computed(() => (fetched.value ? { items: items() } : undefined)),
  };
};

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadrons: (
      _slug: unknown,
      _params: unknown,
      options?: QueryOptions,
    ) => queryMock(options, memberAsked, () => memberSquadrons, cachedMember),
    usePublicFleetSquadrons: (
      _slug: unknown,
      _params: unknown,
      options?: QueryOptions,
    ) => queryMock(options, publicAsked, () => publicSquadrons),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const routerWithSquadron = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      {
        path: "/fleets/:slug/squadrons/:squadron",
        name: "fleet-squadron",
        component: Stub,
      },
    ],
  });

  await router.push("/");
  await router.isReady();

  return router;
};

const fleet = (features: string[] = [FeatureFlagName.FLEET_SQUADRONS]) =>
  ({
    slug: "maru",
    name: "Maru",
    fid: "MARU",
    features,
  }) as unknown as Fleet;

const member = (readSquadrons = true) =>
  ({
    status: FleetMembershipStatusEnum.ACCEPTED,
    capabilities: { readSquadrons },
  }) as unknown as FleetMember;

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  publicSquadrons = [
    { id: "a", name: "Combat Wing", slug: "combat-wing", memberCount: 12 },
    { id: "b", name: "Rescue Team", slug: "rescue-team", memberCount: null },
  ];
  memberAsked = [];
  publicAsked = [];
  cachedMember = false;
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: { fleet: Fleet; membership?: FleetMember }) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
    plugins: [await routerWithSquadron()],
  });

  return wrapper;
};

const tests = (subject: VueWrapper, prefix: string) =>
  subject
    .findAll("[data-test]")
    .map((el) => el.attributes("data-test"))
    .filter((name) => name?.startsWith(prefix));

describe("FleetShow squadrons", () => {
  it("shows a signed-out visitor the public squadron list", async () => {
    const subject = await mount({ fleet: fleet() });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([
      "fleet-public-squadron-combat-wing",
      "fleet-public-squadron-count",
      "fleet-public-squadron-rescue-team",
    ]);
    expect(memberAsked.every((enabled) => !enabled)).toBe(true);
  });

  it("does not link a public squadron to the members-only page", async () => {
    const subject = await mount({ fleet: fleet() });

    expect(subject.find("a.squadron").exists()).toBe(false);
  });

  it("shows a size only where the fleet shares it", async () => {
    const subject = await mount({ fleet: fleet() });

    const counts = subject.findAll('[data-test="fleet-public-squadron-count"]');

    expect(counts).toHaveLength(1);
    expect(counts[0].text()).toContain("12");
  });

  it("treats someone with an unanswered invitation as a visitor", async () => {
    const subject = await mount({
      fleet: fleet(),
      membership: {
        ...member(),
        status: FleetMembershipStatusEnum.INVITED,
      } as FleetMember,
    });

    expect(tests(subject, "fleet-public-squadron-")).toContain(
      "fleet-public-squadron-combat-wing",
    );
  });

  it("shows a member the full strip from the member endpoint", async () => {
    const subject = await mount({ fleet: fleet(), membership: member() });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
    expect(tests(subject, "fleet-squadron-")).toEqual([
      "fleet-squadron-combat-wing",
      "fleet-squadron-rescue-team",
    ]);
    expect(publicAsked.every((enabled) => !enabled)).toBe(true);
  });

  it("shows a member whose role cannot read squadrons neither list", async () => {
    const subject = await mount({ fleet: fleet(), membership: member(false) });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
    expect(tests(subject, "fleet-squadron-")).toEqual([]);
  });

  it("ignores a cached member list once the viewer is no member", async () => {
    cachedMember = true;

    const subject = await mount({ fleet: fleet() });

    expect(tests(subject, "fleet-squadron-")).toEqual([]);
  });

  it("swaps the public list for the member strip when the viewer joins", async () => {
    const subject = await mount({ fleet: fleet() });

    await subject.setProps({ membership: member() });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
    expect(tests(subject, "fleet-squadron-")).toEqual([
      "fleet-squadron-combat-wing",
      "fleet-squadron-rescue-team",
    ]);
  });

  it("falls back to the public list when the viewer leaves", async () => {
    const subject = await mount({ fleet: fleet(), membership: member() });

    await subject.setProps({ membership: undefined });

    expect(tests(subject, "fleet-squadron-")).toEqual([]);
    expect(tests(subject, "fleet-public-squadron-")).toContain(
      "fleet-public-squadron-combat-wing",
    );
  });

  it("hides both lists when the fleet switches squadrons off", async () => {
    const subject = await mount({ fleet: fleet() });

    await subject.setProps({ fleet: fleet([]) });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
  });

  it("asks for nothing when the fleet has squadrons switched off", async () => {
    const subject = await mount({ fleet: fleet([]) });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
    expect(publicAsked.every((enabled) => !enabled)).toBe(true);
  });
});
