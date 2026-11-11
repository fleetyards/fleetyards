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
      { path: "/fleets/:slug/members", name: "fleet-members", component: Stub },
      {
        path: "/fleets/:slug/logistics/transfers",
        name: "fleet-logistics-transfers",
        component: Stub,
      },
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

describe("HomeDashboardFleetPanel", () => {
  beforeEach(() => {
    items = [];
  });

  it("shows what is waiting on the reader", async () => {
    items = [
      summary({ pendingJoinRequestsCount: 2, pendingTransfersCount: 1 }),
    ];

    const subject = await mount();

    expect(subject.text()).toContain("Join requests");
    expect(subject.text()).toContain("Transfers");
  });

  it("leaves out counts the reader's role was not given", async () => {
    items = [summary()];

    const subject = await mount();

    expect(subject.text()).not.toContain("Join requests");
    expect(subject.text()).not.toContain("Transfers");
    expect(subject.text()).toContain("84 members");
  });

  it("shows the latest announcement", async () => {
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

    expect(
      subject.find('[data-test="home-fleet-announcement"]').text(),
    ).toContain("Hauling rates change on Friday.");
  });

  it("shows the primary fleet and links the others", async () => {
    items = [
      summary({
        id: "f2",
        name: "Outer Rim",
        slug: "outer-rim",
        primary: false,
      }),
      summary(),
    ];

    const subject = await mount();

    expect(subject.find(".home-fleet__name").text()).toBe(
      "Black Sun Logistics",
    );
    expect(subject.find(".home-fleet__others").text()).toContain("Outer Rim");
  });

  it("shows what waits in a second fleet, named", async () => {
    items = [
      summary(),
      summary({
        id: "f2",
        name: "Outer Rim",
        slug: "outer-rim",
        primary: false,
        pendingJoinRequestsCount: 5,
      }),
    ];

    const subject = await mount();

    const [row] = subject.findAll(".home-fleet__pending");
    expect(row.text()).toContain("Join requests");
    expect(row.text()).toContain("Outer Rim");
    expect(row.attributes("href")).toContain("/fleets/outer-rim/members");
  });

  it("sends transfers to the transfers page", async () => {
    items = [summary({ pendingTransfersCount: 2 })];

    const subject = await mount();

    expect(subject.find(".home-fleet__pending").attributes("href")).toContain(
      "/fleets/black-sun/logistics/transfers",
    );
  });

  it("points a pilot without a fleet to the directory", async () => {
    const subject = await mount();

    expect(subject.find('[data-test="dashboard-empty"]').exists()).toBe(true);
  });
});
