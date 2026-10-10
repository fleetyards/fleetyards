import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, nextTick, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetOnlineMembersList } from "@/services/fyApi";
import { usePresence } from "@/shared/composables/usePresence";
import { focusManager } from "@tanstack/vue-query";
import Component from "./index.vue";

let online: FleetOnlineMembersList | undefined;
const isFetching = ref(false);
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

      return {
        data: computed(() => online),
        refetch,
        isLoading: computed(() => !online),
        isFetching,
        isError: ref(false),
      };
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
    isFetching.value = false;
    refetch.mockReset();
    resetPresence();
  });

  // The presence map is shared by every mounted panel, so one left over from
  // an earlier test would answer this one's pushes too.
  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    focusManager.setFocused(undefined);
    vi.useRealTimers();
  });

  // The wait is spread per dashboard, up to ten seconds.
  const settle = async () => {
    await nextTick();
    vi.advanceTimersByTime(10_000);
  };

  it("says so while nobody else is online", async () => {
    online = { totalCount: 0, items: [] };

    const subject = await mount();

    expect(
      subject.find("[data-test='fleet-dashboard-empty']").text(),
    ).toContain("Nobody else is online");
  });

  // A zero before the answer would read as nobody.
  it("gives no count until the first answer is in", async () => {
    const subject = await mount();

    expect(subject.find(".panel-heading").text()).toContain("Online now");
    expect(subject.find(".panel-heading").text()).not.toContain("(0)");
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });

  // Every login in the fleet sets one off; the bar would never rest.
  it("keeps the asks presence sets off out of the loading bar", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };
    refetch.mockImplementation(() => {
      isFetching.value = true;
      return new Promise(() => undefined);
    });

    const subject = await mount();

    applyPresence({ userId: "new", online: true });
    await settle();
    await nextTick();

    expect(refetch).toHaveBeenCalledTimes(1);
    expect(subject.find(".panel--loading").exists()).toBe(false);
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
  // in this fleet, and it is asked once while they stay online.
  it("asks again once for somebody it does not list yet", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    await mount();

    applyPresence({ userId: "new", online: true });
    await settle();
    applyPresence({ userId: "z", online: true });
    await settle();

    expect(refetch).toHaveBeenCalledTimes(1);
  });

  // Gone before the answer came back, they would otherwise never be asked
  // about again.
  it("asks again for somebody who went offline and came back", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    await mount();

    applyPresence({ userId: "new", online: true });
    await settle();
    applyPresence({ userId: "new", online: false });
    await settle();
    applyPresence({ userId: "new", online: true });
    await settle();

    expect(refetch).toHaveBeenCalledTimes(2);
  });

  it("asks nothing before the first answer is in", async () => {
    online = undefined;

    await mount();

    applyPresence({ userId: "new", online: true });
    await settle();

    expect(refetch).not.toHaveBeenCalled();
  });

  // The page holds the first rows only.
  it("asks again once everybody it lists has gone but more are online", async () => {
    online = {
      totalCount: 5,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    await mount();

    applyPresence({ userId: "z", online: false });
    await settle();

    expect(refetch).toHaveBeenCalledTimes(1);
  });

  // Nothing is replayed after a dropped socket.
  it("asks afresh after the cable reconnects", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    await mount();

    resetPresence();
    await nextTick();

    expect(refetch).toHaveBeenCalledTimes(1);
  });

  it("shows the bar for a refocus, which the reader asked for", async () => {
    online = {
      totalCount: 1,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };
    refetch.mockImplementation(() => {
      isFetching.value = true;
      return new Promise(() => undefined);
    });

    const subject = await mount();

    focusManager.setFocused(false);
    focusManager.setFocused(true);
    await nextTick();

    expect(refetch).toHaveBeenCalledTimes(1);
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });

  // Neither a list nor nobody: the rest are still being asked for.
  it("waits, loading, once everybody it lists has gone but more are online", async () => {
    online = {
      totalCount: 5,
      items: [{ userId: "z", username: "zulu", friend: false }],
    };

    const subject = await mount();

    applyPresence({ userId: "z", online: false });
    await nextTick();

    expect(subject.find(".panel--loading").exists()).toBe(true);
    expect(subject.find("[data-test='fleet-dashboard-empty']").exists()).toBe(
      false,
    );
    expect(subject.find(".online-members__more").exists()).toBe(false);
  });
});
