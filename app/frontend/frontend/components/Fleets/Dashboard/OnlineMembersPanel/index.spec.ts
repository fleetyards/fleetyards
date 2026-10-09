import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, nextTick } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetOnlineMembersList } from "@/services/fyApi";
import { usePresence } from "@/shared/composables/usePresence";
import Component from "./index.vue";

let online: FleetOnlineMembersList | undefined;
const refetch = vi.fn();
let queryOptions: { query?: Record<string, unknown> } | undefined;
let wrapper: { unmount: () => void } | undefined;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetOnlineMembers: (
      _slug: unknown,
      options: { query?: Record<string, unknown> },
    ) => {
      queryOptions = options;

      return { data: computed(() => online), refetch };
    },
  };
});

const Stub = defineComponent({ render: () => h("div") });

const mount = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/m/:slug", name: "fleet-members-index", component: Stub },
    ],
  });
  await router.push("/");
  await router.isReady();

  const mounted = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet },
    plugins: [router],
  });
  wrapper = mounted;

  return mounted;
};

const names = (subject: Awaited<ReturnType<typeof mount>>) =>
  subject.findAll(".online-members__name").map((name) => name.text());

describe("FleetDashboardOnlineMembersPanel", () => {
  const { applyPresence, resetPresence } = usePresence();

  beforeEach(() => {
    vi.useFakeTimers();
    online = undefined;
    refetch.mockClear();
    resetPresence();
  });

  // The presence map is shared by every mounted panel, so one left over from
  // an earlier test would answer this one's pushes too.
  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    vi.useRealTimers();
  });

  it("draws nothing while nobody else is online", async () => {
    online = { totalCount: 0, items: [] };

    const subject = await mount();

    expect(subject.find("[data-test='fleet-dashboard-online']").exists()).toBe(
      false,
    );
  });

  it("marks friends and says how many more there are", async () => {
    online = {
      totalCount: 3,
      items: [
        { userId: "z", username: "zulu", friend: true },
        { userId: "a", username: "alpha", friend: false },
      ],
    };

    const subject = await mount();

    expect(
      subject.findAll("[data-test='fleet-dashboard-online-friend']"),
    ).toHaveLength(1);
    expect(subject.find(".online-members__more").text()).toContain("1");
  });

  // Pushes carry presence, so the panel follows them rather than polling.
  it("asks once and polls nothing", async () => {
    online = { totalCount: 0, items: [] };

    await mount();

    expect(queryOptions?.query?.refetchInterval).toBeUndefined();
  });

  it("drops somebody the moment they go offline", async () => {
    online = {
      totalCount: 2,
      items: [
        { userId: "z", username: "zulu", friend: false },
        { userId: "a", username: "alpha", friend: false },
      ],
    };

    const subject = await mount();

    applyPresence({ userId: "a", online: false });
    await nextTick();

    expect(names(subject)).toEqual(["zulu"]);
    expect(refetch).not.toHaveBeenCalled();
  });

  // A push names an id, not a member: only the server knows whether they are
  // in this fleet, and it is asked once per newcomer.
  it("asks again once for somebody it does not list yet", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    await mount();

    applyPresence({ userId: "new", online: true });
    await nextTick();
    vi.advanceTimersByTime(2_000);

    expect(refetch).toHaveBeenCalledTimes(1);

    applyPresence({ userId: "new", online: false });
    applyPresence({ userId: "new", online: true });
    await nextTick();
    vi.advanceTimersByTime(2_000);

    expect(refetch).toHaveBeenCalledTimes(1);
  });
});
