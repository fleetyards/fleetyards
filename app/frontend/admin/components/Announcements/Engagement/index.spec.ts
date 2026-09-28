import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AnnouncementChannelEnum,
  AnnouncementDeliveryStatusEnum,
  type AnnouncementDelivery,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

const mount = (attrs: Partial<AnnouncementDelivery>) =>
  mountWithDefaults(Component, {
    props: {
      delivery: {
        channel: AnnouncementChannelEnum.BLUESKY,
        status: AnnouncementDeliveryStatusEnum.SUCCEEDED,
        attempts: 1,
        engagementTrackable: true,
        ...attrs,
      },
    },
  });

describe("AnnouncementEngagement", () => {
  it("shows a Bluesky thread's four counts", async () => {
    const wrapper = await mount({
      engagement: { likes: 12, reposts: 3, replies: 2, quotes: 1 },
      engagementFetchedAt: "2026-09-28T10:00:00Z",
    });

    expect(
      wrapper.find("[data-test='announcement-engagement-likes']").text(),
    ).toContain("12");
    expect(
      wrapper.find("[data-test='announcement-engagement-quotes']").text(),
    ).toContain("1");
  });

  it("shows Discord reactions by emoji", async () => {
    const wrapper = await mount({
      channel: AnnouncementChannelEnum.DISCORD,
      engagement: {
        reactions: [
          { emoji: "🚀", count: 5 },
          { emoji: "fleetyards", id: "99", count: 1 },
        ],
      },
    });

    const reactions = wrapper.findAll(
      "[data-test='announcement-engagement-reaction']",
    );

    expect(reactions.map((reaction) => reaction.text())).toEqual([
      "🚀5",
      ":fleetyards:1",
    ]);
  });

  // X bills every read, so its delivery links out and never shows a number.
  it("explains why an X post has no counts", async () => {
    const wrapper = await mount({
      channel: AnnouncementChannelEnum.X,
      engagementTrackable: false,
    });

    expect(wrapper.text()).toContain("Open the post to see them");
  });

  it("says a Discord post predates reaction tracking", async () => {
    const wrapper = await mount({
      channel: AnnouncementChannelEnum.DISCORD,
      engagementTrackable: false,
    });

    expect(wrapper.text()).toContain("Posted before reactions were tracked");
  });

  it("stays out of the way for a delivery that did not go out", async () => {
    const wrapper = await mount({
      status: AnnouncementDeliveryStatusEnum.FAILED,
    });

    expect(wrapper.find("[data-test='announcement-engagement']").exists()).toBe(
      false,
    );
  });
});
