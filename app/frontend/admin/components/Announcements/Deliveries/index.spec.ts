import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AnnouncementChannelEnum,
  AnnouncementDeliveryStatusEnum,
  AnnouncementStatusEnum,
  type Announcement,
  type AnnouncementDelivery,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

const mount = (deliveries: AnnouncementDelivery[]) =>
  mountWithDefaults(Component, {
    props: {
      announcement: {
        id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
        title: "Trade routes",
        body: "Now ranked.",
        discordParts: [],
        socialParts: [],
        icon: "fa-duotone fa-bullhorn",
        status: AnnouncementStatusEnum.PUBLISHED,
        notifyUsers: true,
        postDiscord: true,
        postBluesky: true,
        postX: true,
        publishable: false,
        deliveries,
        createdAt: "2026-01-01",
        updatedAt: "2026-01-01",
      } satisfies Announcement,
    },
  });

describe("AnnouncementDeliveries", () => {
  it("links a sent post and shows its engagement", async () => {
    const wrapper = await mount([
      {
        channel: AnnouncementChannelEnum.BLUESKY,
        status: AnnouncementDeliveryStatusEnum.SUCCEEDED,
        attempts: 1,
        url: "https://bsky.app/profile/did:plc:abc/post/3k",
        engagementTrackable: true,
        engagement: { likes: 4, reposts: 1, replies: 0, quotes: 0 },
      },
    ]);

    expect(
      wrapper
        .find("[data-test='announcement-delivery-link']")
        .attributes("href"),
    ).toBe("https://bsky.app/profile/did:plc:abc/post/3k");
    expect(wrapper.find("[data-test='announcement-engagement']").exists()).toBe(
      true,
    );
  });

  it("offers a retry and no link for a failed post", async () => {
    const wrapper = await mount([
      {
        channel: AnnouncementChannelEnum.X,
        status: AnnouncementDeliveryStatusEnum.FAILED,
        attempts: 1,
        error: "X API error 429",
        engagementTrackable: false,
      },
    ]);

    expect(
      wrapper.find("[data-test='announcement-delivery-retry']").exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='announcement-delivery-link']").exists(),
    ).toBe(false);
    expect(wrapper.find("[data-test='announcement-engagement']").exists()).toBe(
      false,
    );
  });
});
