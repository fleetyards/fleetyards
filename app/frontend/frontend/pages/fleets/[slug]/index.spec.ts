import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  computed,
  defineComponent,
  h,
  nextTick,
  ref,
  watchEffect,
  type Ref,
} from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import {
  FleetMembershipStatusEnum,
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  type PublicFleetSquadron,
} from "@/services/fyApi";
import { useFleetStore } from "@/frontend/stores/fleet";
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

// Starts the way the real tour does -- once it is opened -- without the
// overlay, which has its own spec.
vi.mock("@/frontend/components/Fleets/Tour/index.vue", async () => {
  const { defineComponent, h, watch } = await import("vue");

  return {
    default: defineComponent({
      props: { open: Boolean },
      emits: ["start", "update:open"],
      setup(props, { emit }) {
        watch(
          () => props.open,
          (open) => open && emit("start"),
        );

        return () =>
          h("div", { "data-test": "fleet-tour", "data-open": props.open });
      },
    }),
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
      {
        path: "/fleets/:slug/settings/rsi",
        name: "fleet-settings-rsi",
        component: Stub,
      },
    ],
  });

  await router.push("/");
  await router.isReady();

  return router;
};

const fleet = (squadronsEnabled = true) =>
  ({
    slug: "maru",
    name: "Maru",
    fid: "MARU",
    features: [],
    squadronsEnabled,
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

const mount = async (
  props: { fleet: Fleet; membership?: FleetMember },
  initialState?: Record<string, unknown>,
) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
    initialState,
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

    await subject.setProps({ fleet: fleet(false) });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
  });

  it("asks for nothing when the fleet has squadrons switched off", async () => {
    const subject = await mount({ fleet: fleet(false) });

    expect(tests(subject, "fleet-public-squadron-")).toEqual([]);
    expect(publicAsked.every((enabled) => !enabled)).toBe(true);
  });
});

describe("FleetShow header", () => {
  it("badges the RSI logo of a verified fleet, not its FID", async () => {
    const subject = await mount({
      fleet: { ...fleet(), rsiVerified: true, rsiSid: "MARU" } as Fleet,
    });

    expect(
      subject.find('[data-test="rsi-profile-link-verified"]').exists(),
    ).toBe(true);
    expect(subject.find(".title").text()).toBe("Maru (MARU)");
  });

  it("shows the RSI logo of an unverified fleet without the badge", async () => {
    const subject = await mount({
      fleet: { ...fleet(), rsiVerified: false, rsiSid: "MARU" } as Fleet,
    });

    expect(subject.find(".rsi-profile-link").exists()).toBe(true);
    expect(
      subject.find('[data-test="rsi-profile-link-verified"]').exists(),
    ).toBe(false);
  });
});

describe("FleetShow description", () => {
  it("renders the description as markdown and never as html", async () => {
    const subject = await mount({
      fleet: {
        ...fleet(),
        description: "**Crew**\n<img src=x onerror=alert(1)>",
      } as Fleet,
    });

    const description = subject.find(".description");
    expect(description.find("strong").text()).toBe("Crew");
    expect(description.find("img").exists()).toBe(false);
    expect(description.text()).toContain("<img src=x onerror=alert(1)>");
  });
});

describe("FleetShow setup tour", () => {
  const TOUR_AUTOSTART_DELAY = 800;

  const manager = () =>
    ({
      status: FleetMembershipStatusEnum.ACCEPTED,
      capabilities: { readSquadrons: true, manageFleet: true },
    }) as unknown as FleetMember;

  const signedIn = (pendingTours: string[] = []) => ({
    session: { currentUser: { id: "user-a" } },
    fleet: {
      pendingTours: Object.fromEntries(
        pendingTours.map((key) => [key, Date.now()]),
      ),
    },
  });

  const tourOpen = () =>
    wrapper?.find("[data-test='fleet-tour']").attributes("data-open");

  beforeEach(() => {
    document.body.innerHTML = '<div id="header-right"></div>';
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const fleetWithId = () => ({ ...fleet(), id: "fleet-1" }) as Fleet;

  it("offers the guide to a manager", async () => {
    await mount({ fleet: fleetWithId(), membership: manager() }, signedIn());

    expect(
      document.querySelector("[data-test='fleet-show-guide']"),
    ).not.toBeNull();
  });

  it("offers nothing to a member who cannot manage the fleet", async () => {
    await mount(
      { fleet: fleetWithId(), membership: member() },
      signedIn(["user-a:fleet-1"]),
    );
    vi.advanceTimersByTime(TOUR_AUTOSTART_DELAY);
    await nextTick();

    expect(document.querySelector("[data-test='fleet-show-guide']")).toBeNull();
    expect(wrapper?.find("[data-test='fleet-tour']").exists()).toBe(false);
  });

  it("starts on its own for the fleet this account just created", async () => {
    await mount(
      { fleet: fleetWithId(), membership: manager() },
      signedIn(["user-a:fleet-1"]),
    );
    const fleetStore = useFleetStore();

    vi.advanceTimersByTime(TOUR_AUTOSTART_DELAY);
    await nextTick();
    await nextTick();

    expect(tourOpen()).toBe("true");
    expect(vi.mocked(fleetStore).clearTour.mock.calls).toEqual([
      ["user-a", "fleet-1"],
    ]);
  });

  it("waits for the guide button on any other fleet", async () => {
    await mount(
      { fleet: fleetWithId(), membership: manager() },
      signedIn(["user-a:fleet-2", "user-b:fleet-1"]),
    );

    vi.advanceTimersByTime(TOUR_AUTOSTART_DELAY);
    await nextTick();
    expect(tourOpen()).toBe("false");

    document
      .querySelector<HTMLElement>("[data-test='fleet-show-guide']")
      ?.click();
    await nextTick();
    await nextTick();

    expect(tourOpen()).toBe("true");
  });
});
