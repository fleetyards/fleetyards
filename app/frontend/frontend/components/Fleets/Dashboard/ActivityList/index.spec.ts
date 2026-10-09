import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import {
  FleetActivityCategoryEnum,
  FleetActivityKindEnum,
  FleetActivitySubjectTypeEnum,
  type Fleet,
  type FleetActivity,
} from "@/services/fyApi";
import Component from "./index.vue";

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      {
        path: "/fleets/:slug/events/:event",
        name: "fleet-event",
        component: Stub,
      },
      {
        path: "/fleets/:slug/members",
        name: "fleet-members-index",
        component: Stub,
      },
      {
        path: "/fleets/:slug/logistics/inventories/:inventory",
        name: "fleet-logistics-inventory",
        component: Stub,
      },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const fleet = { slug: "maru" } as Fleet;

const entry = (overrides: Partial<FleetActivity>): FleetActivity => ({
  id: "entry",
  kind: FleetActivityKindEnum.EVENT_PUBLISHED,
  category: FleetActivityCategoryEnum.EVENTS,
  occurredAt: new Date().toISOString(),
  involvesViewer: false,
  actor: { id: "u", username: "mortik", avatar: null },
  subject: {
    type: FleetActivitySubjectTypeEnum.EVENT,
    id: "e",
    slug: "mining-op",
    title: "Mining op",
  },
  inventory: null,
  ...overrides,
});

const mount = async (entries: FleetActivity[], props = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { fleet, entries, ...props },
    plugins: [await router()],
  });

describe("FleetDashboardActivityList", () => {
  it("links an event to its page and says who did what", async () => {
    const subject = await mount([entry({})]);

    const link = subject.find("a.activity-list__title");
    expect(link.attributes("href")).toBe("#/fleets/maru/events/mining-op");
    expect(link.text()).toBe("Mining op");
    expect(subject.find(".activity-list__meta").text()).toContain("mortik");
  });

  // A transfer is only named by a note, which most do not carry; the store it
  // went through is the next best name, and where the link goes.
  it("names a transfer by its inventory and links there", async () => {
    const subject = await mount([
      entry({
        kind: FleetActivityKindEnum.INVENTORY_TRANSFER_COMPLETED,
        category: FleetActivityCategoryEnum.INVENTORY,
        subject: {
          type: FleetActivitySubjectTypeEnum.INVENTORY_TRANSFER,
          id: "t",
          slug: null,
          title: null,
        },
        inventory: { id: "i", slug: "main-store", name: "Main store" },
      }),
    ]);

    const link = subject.find("a.activity-list__title");
    expect(link.text()).toBe("Main store");
    expect(link.attributes("href")).toBe(
      "#/fleets/maru/logistics/inventories/main-store",
    );
  });

  it("marks what involves the reader", async () => {
    const subject = await mount([
      entry({ id: "a", involvesViewer: true }),
      entry({ id: "b" }),
    ]);

    expect(subject.findAll("[data-test='fleet-activity-mine']")).toHaveLength(
      1,
    );
  });

  it("shows the person, not the kind, in a list of people", async () => {
    const subject = await mount(
      [
        entry({
          kind: FleetActivityKindEnum.MEMBER_JOINED,
          subject: {
            type: FleetActivitySubjectTypeEnum.MEMBER,
            id: "m",
            slug: "mortik",
            title: "mortik",
          },
        }),
      ],
      { showActor: false, showKind: false },
    );

    expect(subject.find(".avatar").exists()).toBe(true);
    expect(subject.find(".activity-list__icon").exists()).toBe(false);
    expect(subject.find(".activity-list__meta").text()).not.toContain("Joined");
  });
});
