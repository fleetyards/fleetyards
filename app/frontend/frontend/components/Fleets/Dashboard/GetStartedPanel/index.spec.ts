import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet } from "@/services/fyApi";
import Component from "./index.vue";

const createDraft = vi.fn();
const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

vi.mock("@/frontend/composables/useDraftCreate", () => ({
  useEventDraft: () => ({ create: createDraft, pending: ref(false) }),
}));

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleets/:slug/events", name: "fleet-events", component: Stub },
      {
        path: "/fleets/:slug/contracts",
        name: "fleet-contracts",
        component: Stub,
      },
      {
        path: "/fleets/:slug/contracts/new",
        name: "fleet-contract-new",
        component: Stub,
      },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const mount = async (props: Record<string, boolean>) => {
  const instance = await router();
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet, ...props },
    plugins: [instance],
  });

  return { wrapper, router: instance };
};

describe("FleetDashboardGetStartedPanel", () => {
  it("draws nothing while every module has something on", async () => {
    const { wrapper } = await mount({});

    expect(
      wrapper.find("[data-test='fleet-dashboard-get-started']").exists(),
    ).toBe(false);
  });

  it("lets somebody who may plan one start an event from here", async () => {
    const { wrapper } = await mount({ events: true, canCreateEvents: true });

    await wrapper
      .find("[data-test='fleet-dashboard-plan-event']")
      .trigger("click");

    expect(createDraft).toHaveBeenCalledWith("maru");
  });

  // The API copies a mission's teams only while it writes the event, so a
  // reader of missions picks one first, as on the events page.
  it("asks a reader of missions for a template before writing", async () => {
    createDraft.mockClear();
    const { wrapper } = await mount({
      events: true,
      canCreateEvents: true,
      canReadMissions: true,
    });

    await wrapper
      .find("[data-test='fleet-dashboard-plan-event']")
      .trigger("click");

    expect(createDraft).not.toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: expect.objectContaining({ fleet: { slug: "maru" } }),
      }),
    );

    const [, payload] = emit.mock.calls.at(-1)!;
    payload.props.onPick({ slug: "salvage-op" });

    expect(createDraft).toHaveBeenCalledWith("maru", {
      missionSlug: "salvage-op",
    });
  });

  it("takes somebody who may post one to a new contract", async () => {
    const { wrapper, router: instance } = await mount({
      contracts: true,
      canCreateContracts: true,
    });

    await wrapper
      .find("[data-test='fleet-dashboard-post-contract']")
      .trigger("click");
    await instance.isReady();
    await new Promise((resolve) => setTimeout(resolve));

    expect(instance.currentRoute.value.name).toBe("fleet-contract-new");
  });

  it("points everybody else at the module instead", async () => {
    const { wrapper } = await mount({ events: true, contracts: true });

    expect(
      wrapper.find("[data-test='fleet-dashboard-plan-event']").exists(),
    ).toBe(false);
    expect(
      wrapper.find("[data-test='fleet-dashboard-post-contract']").exists(),
    ).toBe(false);
    expect(
      wrapper
        .findAll("a.get-started__link")
        .map((link) => link.attributes("href")),
    ).toEqual(["#/fleets/maru/events", "#/fleets/maru/contracts"]);
  });
});
