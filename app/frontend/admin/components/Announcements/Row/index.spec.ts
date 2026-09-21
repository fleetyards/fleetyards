import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AnnouncementChannelEnum,
  AnnouncementDeliveryStatusEnum,
  AnnouncementStatusEnum,
  type Announcement,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

// The title links to the edit form, and the actions carry a link of their own,
// so the default single-route test router resolves neither.
const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/announcements",
        name: "admin-announcements",
        component: { template: "<div />" },
      },
      {
        path: "/announcements/:id/edit",
        name: "admin-announcement-edit",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "admin-announcements" });
  await router.isReady();

  return router;
};

const announcement = (attrs: Partial<Announcement> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    title: "Commodities are live",
    body: "Something new just landed.",
    discordParts: [],
    socialParts: [],
    icon: "fa-duotone fa-bullhorn",
    status: AnnouncementStatusEnum.DRAFT,
    notifyUsers: true,
    postDiscord: false,
    postBluesky: false,
    postX: false,
    publishable: true,
    deliveries: [],
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Announcement;

const mount = async (attrs: Partial<Announcement> = {}) =>
  mountWithDefaults(Component, {
    props: { announcement: announcement(attrs) },
    plugins: [await routerOnList()],
  });

describe("AnnouncementRow", () => {
  it("links the title to the edit form while the announcement is still sendable", async () => {
    const wrapper = await mount();

    expect(wrapper.find("a.announcement-row__title").attributes("href")).toBe(
      "#/announcements/0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c/edit",
    );
  });

  // A published announcement has nothing left to edit, and a link to a form
  // that refuses the save is worse than no link.
  it("leaves the title unlinked once it has been sent", async () => {
    const wrapper = await mount({
      status: AnnouncementStatusEnum.PUBLISHED,
      publishable: false,
    });

    expect(wrapper.find("a.announcement-row__title").exists()).toBe(false);
    expect(wrapper.find(".announcement-row__title").text()).toBe(
      "Commodities are live",
    );
  });

  // The column this replaces was `mobile: false`, so the half of the row a send
  // moves was invisible on a phone exactly while it was moving.
  it("renders the deliveries in the row rather than in a column", async () => {
    const wrapper = await mount({
      deliveries: [
        {
          channel: AnnouncementChannelEnum.DISCORD,
          status: AnnouncementDeliveryStatusEnum.SUCCEEDED,
          attempts: 1,
        },
      ],
    });

    expect(wrapper.find("[data-test='announcement-deliveries']").exists()).toBe(
      true,
    );
  });

  it("says nothing about deliveries before there are any", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='announcement-deliveries']").exists()).toBe(
      false,
    );
  });

  it("counts the recipients once the fan-out has sized them", async () => {
    const wrapper = await mount({ recipientsCount: 57_000 });

    expect(wrapper.find(".announcement-row__sub").text()).toContain(
      "57000 recipients",
    );
  });
});
