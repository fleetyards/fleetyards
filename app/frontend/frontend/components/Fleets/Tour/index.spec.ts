import { flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import type { TourStep } from "@/shared/components/Tour/types";
import { useFleetStore } from "@/frontend/stores/fleet";
import FleetTour from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const TourStub = defineComponent({
  name: "AppTour",
  props: {
    steps: { type: Array, required: true },
    open: Boolean,
  },
  emits: ["start", "update:open"],
  render: () => null,
});

const Page = defineComponent({ render: () => h("div") });

let wrapper: VueWrapper | undefined;

const mountTour = async (path = "/fleets/evle/") => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Page },
      { path: "/fleets/:slug/", name: "fleet", component: Page },
    ],
  });
  await router.push(path);

  wrapper = mount(FleetTour, {
    global: {
      plugins: [
        router,
        createTestingPinia({
          initialState: {
            session: { currentUser: { id: "user-a" } },
            fleet: {
              tourFleet: { id: "fleet-1", slug: "evle" },
              tourOpen: true,
            },
          },
        }),
      ],
      stubs: { Tour: TourStub },
    },
  });
  await flushPromises();

  return { router, tour: wrapper.findComponent(TourStub) };
};

const routeName = (step: TourStep) =>
  (step.route as { name: string; params: { slug: string } }).name;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("FleetTour", () => {
  it("walks the overview, members, ships and the settings pages in order", async () => {
    const { tour } = await mountTour();
    const steps = tour.props("steps") as TourStep[];

    expect(steps.map((step) => [step.id, routeName(step)])).toEqual([
      ["welcome", "fleet"],
      ["events", "fleet"],
      ["contracts", "fleet"],
      ["members", "fleet-members"],
      ["ships", "fleet-ships"],
      ["membership", "fleet-settings-membership"],
      ["rsi", "fleet-settings-rsi"],
      ["roles", "fleet-settings-roles"],
      ["squadrons", "fleet-settings-squadrons"],
      ["discord", "fleet-settings-discord"],
      ["settings", "fleet-settings-fleet"],
    ]);
    steps.forEach((step) => {
      expect(step.route).toMatchObject({ params: { slug: "evle" } });
    });
  });

  // The flag-gated tabs disappear with their flag; every other page is there
  // for a manager, and a missing control only centres its card.
  it("requires the target only for the flag-gated tabs", async () => {
    const { tour } = await mountTour();

    expect(
      (tour.props("steps") as TourStep[])
        .filter((step) => step.requiresTarget)
        .map((step) => step.id),
    ).toEqual(["events", "contracts"]);
  });

  it("clears the pending tour once it has started", async () => {
    const { tour } = await mountTour();

    tour.vm.$emit("start");

    expect(vi.mocked(useFleetStore()).clearTour.mock.calls).toEqual([
      ["user-a", "fleet-1"],
    ]);
  });

  it("ends when the reader leaves the fleet", async () => {
    const { router } = await mountTour();

    await router.push("/");
    await flushPromises();

    expect(vi.mocked(useFleetStore()).closeTour.mock.calls).toHaveLength(1);
  });
});
