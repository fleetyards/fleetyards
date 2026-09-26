import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref } from "vue";
import { RouterView, createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetMember } from "@/services/fyApi";
import Component from "./[slug].vue";

const fleetState = {
  fleet: ref<Fleet | undefined>(),
  publicFleet: ref<Fleet | undefined>(),
  membership: ref<FleetMember | undefined>(),
  membershipStatus: {
    error: ref<unknown>(null),
    isPending: ref(false),
    isFetching: ref(false),
    isLoading: ref(false),
  },
};

// The states vue-query reports: a disabled query stays pending without ever
// fetching, and a 404 settles with an error.
const setMembership = (state: "disabled" | "notFound" | "loading") => {
  const status = fleetState.membershipStatus;
  status.error.value = state === "notFound" ? { status: 404 } : null;
  status.isPending.value = state !== "notFound";
  status.isFetching.value = state === "loading";
  status.isLoading.value = state === "loading";
};

const settled = (data: unknown) => ({
  data,
  error: ref(null),
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  refetch: vi.fn(),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleet: () => settled(fleetState.fleet),
    usePublicFleet: () => settled(fleetState.publicFleet),
    useFleetMembership: () => ({
      data: fleetState.membership,
      ...fleetState.membershipStatus,
      isRefetching: ref(false),
    }),
  };
});

const Child = defineComponent({
  render: () => h("div", { "data-test": "fleet-child" }),
});

const mountFleetPage = async (authenticated: boolean) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/fleets/:slug",
        component: Component,
        children: [{ path: "", name: "fleet", component: Child }],
      },
    ],
  });

  await router.push("/fleets/evle");

  return mountWithDefaults(defineComponent({ render: () => h(RouterView) }), {
    plugins: [router],
    initialState: { session: { authenticated } },
  });
};

describe("FleetRouterView", () => {
  beforeEach(() => {
    fleetState.fleet.value = undefined;
    fleetState.publicFleet.value = { slug: "evle", name: "EVLE" } as Fleet;
    fleetState.membership.value = undefined;
  });

  it("renders a public fleet for a guest", async () => {
    setMembership("disabled");

    const wrapper = await mountFleetPage(false);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(true);
  });

  it("renders a public fleet for a signed-in non-member", async () => {
    setMembership("notFound");

    const wrapper = await mountFleetPage(true);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(true);
  });

  it("waits while the membership is still loading", async () => {
    setMembership("loading");

    const wrapper = await mountFleetPage(true);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
  });
});
