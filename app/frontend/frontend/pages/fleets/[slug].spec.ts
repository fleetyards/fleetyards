import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref, toValue, type MaybeRef } from "vue";
import { flushPromises } from "@vue/test-utils";
import { RouterView, createRouter, createWebHashHistory } from "vue-router";
import { AxiosError, type AxiosResponse } from "axios";
import {
  FleetMembershipStatusEnum,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";
import Component from "./[slug].vue";

const fleetState = {
  fleet: ref<Fleet | undefined>(),
  fleetError: ref<unknown>(null),
  fleetPending: ref(false),
  publicFleet: ref<Fleet | undefined>(),
  publicFleetEnabled: { value: false as MaybeRef<boolean> },
  membership: ref<FleetMember | undefined>(),
  membershipStatus: {
    error: ref<unknown>(null),
    isPending: ref(false),
    isFetching: ref(false),
    isLoading: ref(false),
  },
};

const httpError = (status: number) =>
  new AxiosError("request failed", undefined, undefined, undefined, {
    status,
  } as AxiosResponse);

// The states vue-query reports: a disabled query stays pending without ever
// fetching, and a 404 settles with an error.
const setMembership = (
  state: "disabled" | "notFound" | "failed" | "loading" | "member",
) => {
  const status = fleetState.membershipStatus;
  status.error.value =
    state === "notFound"
      ? httpError(404)
      : state === "failed"
        ? httpError(500)
        : null;
  status.isPending.value = state === "disabled" || state === "loading";
  // The members' copy of the fleet is refused exactly when the membership is,
  // but a non-member is told so with a 403, not the membership's 404.
  fleetState.fleetError.value =
    state === "notFound"
      ? httpError(403)
      : state === "failed"
        ? status.error.value
        : null;
  status.isFetching.value = state === "loading";
  status.isLoading.value = state === "loading";
};

const settled = (
  data: unknown,
  error = ref<unknown>(null),
  pending = ref(false),
) => ({
  data,
  error,
  isPending: pending,
  isFetching: pending,
  isLoading: pending,
  isRefetching: ref(false),
  refetch: vi.fn(),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleet: () =>
      settled(fleetState.fleet, fleetState.fleetError, fleetState.fleetPending),
    usePublicFleet: (
      _slug: unknown,
      options: { query: { enabled: MaybeRef<boolean> } },
    ) => {
      fleetState.publicFleetEnabled.value = options.query.enabled;

      return settled(fleetState.publicFleet);
    },
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

const mountFleetPage = async (
  authenticated: boolean,
  path = "/fleets/evle",
) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Child },
      {
        path: "/fleets/:slug",
        component: Component,
        children: [
          { path: "", name: "fleet", component: Child },
          {
            path: "settings/membership/",
            name: "fleet-settings-membership",
            component: Child,
            meta: { needsAuthentication: true },
          },
        ],
      },
    ],
  });

  await router.push(path);

  return mountWithDefaults(defineComponent({ render: () => h(RouterView) }), {
    plugins: [router],
    initialState: { session: { authenticated } },
  });
};

const accepted = {
  id: "m1",
  status: FleetMembershipStatusEnum.ACCEPTED,
} as FleetMember;

describe("FleetRouterView", () => {
  beforeEach(() => {
    fleetState.fleet.value = undefined;
    fleetState.fleetError.value = null;
    fleetState.fleetPending.value = false;
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

  it("shows not found without asking for the visitor payload", async () => {
    setMembership("notFound");
    fleetState.fleetError.value = httpError(404);

    const wrapper = await mountFleetPage(true);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
    expect(wrapper.findComponent({ name: "NotFound" }).exists()).toBe(true);
    expect(toValue(fleetState.publicFleetEnabled.value)).toBe(false);
  });

  it("waits while the membership is still loading", async () => {
    setMembership("loading");

    const wrapper = await mountFleetPage(true);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
  });

  it("denies a member-only route to a signed-in non-member", async () => {
    setMembership("notFound");

    const wrapper = await mountFleetPage(
      true,
      "/fleets/evle/settings/membership/",
    );

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
    expect(wrapper.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      true,
    );
  });

  it("denies a member-only route to an invited member", async () => {
    setMembership("member");
    fleetState.fleetError.value = httpError(403);
    fleetState.membership.value = {
      id: "m1",
      status: FleetMembershipStatusEnum.INVITED,
    } as FleetMember;

    const wrapper = await mountFleetPage(
      true,
      "/fleets/evle/settings/membership/",
    );

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
    expect(wrapper.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      true,
    );
  });

  it("shows an invited member the visitor view without the membership", async () => {
    setMembership("member");
    fleetState.fleetError.value = httpError(403);
    fleetState.membership.value = {
      id: "m1",
      status: FleetMembershipStatusEnum.INVITED,
    } as FleetMember;

    const wrapper = await mountFleetPage(true);

    const child = wrapper.findComponent(Child);
    expect(child.exists()).toBe(true);
    expect((child.vm.$attrs.fleet as Fleet).name).toBe("EVLE");
    expect(child.vm.$attrs.membership).toBeUndefined();
  });

  it("renders a member-only route for a member", async () => {
    setMembership("member");
    fleetState.membership.value = accepted;

    const wrapper = await mountFleetPage(
      true,
      "/fleets/evle/settings/membership/",
    );

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(true);
  });

  it("renders a member's page from the members' copy only", async () => {
    setMembership("member");
    fleetState.membership.value = accepted;
    fleetState.publicFleet.value = { slug: "evle", name: "Visitor" } as Fleet;
    fleetState.fleetPending.value = true;

    const wrapper = await mountFleetPage(
      true,
      "/fleets/evle/settings/membership/",
    );

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);

    fleetState.fleet.value = { slug: "evle", name: "Member" } as Fleet;
    fleetState.fleetPending.value = false;
    await flushPromises();

    const child = wrapper.findComponent(Child);
    expect(child.exists()).toBe(true);
    expect((child.vm.$attrs.fleet as Fleet).name).toBe("Member");
  });

  it("does not fall back to the visitor payload when the members' copy fails", async () => {
    setMembership("member");
    fleetState.membership.value = accepted;
    fleetState.fleetError.value = httpError(500);

    const wrapper = await mountFleetPage(
      true,
      "/fleets/evle/settings/membership/",
    );

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
  });

  it("drops a removed member's cached fleet for the visitor payload", async () => {
    setMembership("notFound");
    fleetState.fleet.value = { slug: "evle", name: "Member" } as Fleet;
    fleetState.publicFleet.value = { slug: "evle", name: "Visitor" } as Fleet;

    const wrapper = await mountFleetPage(true);

    const child = wrapper.findComponent(Child);
    expect(child.exists()).toBe(true);
    expect((child.vm.$attrs.fleet as Fleet).name).toBe("Visitor");
  });

  it("shows the error screen when the membership request fails", async () => {
    setMembership("failed");

    const wrapper = await mountFleetPage(true);

    expect(wrapper.find('[data-test="fleet-child"]').exists()).toBe(false);
    expect(wrapper.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      false,
    );
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(true);
  });
});
