import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { MyFleetSummary } from "@/services/fyApi";
import Component from "./index.vue";

let items: MyFleetSummary[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useMyFleetSummaries: () => ({
      data: computed(() => ({ items })),
      isLoading: ref(false),
      isFetching: ref(false),
      isLoadingError: ref(false),
    }),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleets", name: "fleets", component: Stub },
      { path: "/fleets/directory", name: "fleet-directory", component: Stub },
      { path: "/fleets/:slug", name: "fleet", component: Stub },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const summary = (overrides: Partial<MyFleetSummary> = {}): MyFleetSummary => ({
  id: "f1",
  name: "Black Sun Logistics",
  slug: "black-sun",
  primary: true,
  memberCount: 84,
  ...overrides,
});

const mount = async () =>
  mountWithDefaults<typeof Component>(Component, {
    plugins: [await router()],
  });

describe("HomeDashboardMyFleetsPanel", () => {
  beforeEach(() => {
    items = [];
  });

  it("shows what is waiting on the reader as badges", async () => {
    items = [
      summary({ pendingJoinRequestsCount: 2, pendingTransfersCount: 1 }),
    ];

    const subject = await mount();

    expect(subject.text()).toContain("Join requests");
    expect(subject.text()).toContain("Transfers");
  });

  it("shows no badges for counts the reader's role was not given", async () => {
    items = [summary()];

    const subject = await mount();

    expect(subject.text()).not.toContain("Join requests");
    expect(subject.text()).not.toContain("Transfers");
    expect(subject.text()).toContain("84 members");
  });

  it("shows the latest announcement under the fleet", async () => {
    items = [
      summary({
        latestAnnouncement: {
          id: "a",
          excerpt: "Hauling rates change on Friday.",
          createdAt: new Date().toISOString(),
        },
      }),
    ];

    const subject = await mount();

    expect(subject.find(".home-my-fleets__announcement").text()).toContain(
      "Hauling rates change on Friday.",
    );
  });
});
