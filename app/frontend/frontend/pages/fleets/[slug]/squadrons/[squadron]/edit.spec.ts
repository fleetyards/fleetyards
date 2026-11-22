import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetMember, FleetSquadron } from "@/services/fyApi";
import Component from "./edit.vue";

const Stub = defineComponent({ name: "PageStub", render: () => h("div") });

const record = ref<FleetSquadron | undefined>();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadron: () => ({ data: record, isLoading: ref(false) }),
  };
});

const routerWithRoutes = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleet", name: "fleet", component: Stub },
      { path: "/squadrons", name: "fleet-squadrons", component: Stub },
      { path: "/squadrons/:squadron", name: "fleet-squadron", component: Stub },
      {
        path: "/squadrons/:squadron/edit",
        name: "fleet-squadron-edit",
        component: Stub,
      },
    ],
  });

  await router.push("/squadrons/alpha/edit");
  await router.isReady();

  return router;
};

const squadron = (update: boolean): FleetSquadron =>
  ({
    id: "alpha",
    name: "Alpha",
    slug: "alpha",
    capabilities: { update, manageMembers: false, manageRanks: false },
  }) as FleetSquadron;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

// A Member-role membership: what a squadron's Leader without any fleet
// privilege holds. Only the squadron's own answer may let them in.
const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      membership: {
        fleetRole: { resourceAccess: ["fleet:squadrons:read"] },
        capabilities: { updateSquadrons: false },
      } as unknown as FleetMember,
    },
    plugins: [await routerWithRoutes()],
  });

  return wrapper;
};

describe("FleetSquadronEditLayout", () => {
  it("opens the form when the squadron says the reader may edit it", async () => {
    record.value = squadron(true);
    const subject = await mount();

    expect(
      subject.findComponent({ name: "FleetSquadronFormShell" }).exists(),
    ).toBe(true);
    expect(subject.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      false,
    );
  });

  it("refuses a reader the squadron does not let edit it", async () => {
    record.value = squadron(false);
    const subject = await mount();

    expect(
      subject.findComponent({ name: "FleetSquadronFormShell" }).exists(),
    ).toBe(false);
    expect(subject.findComponent({ name: "NotAuthorized" }).exists()).toBe(
      true,
    );
  });
});
