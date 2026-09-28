import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AnnouncementChannelEnum,
  AnnouncementDeliveryStatusEnum,
  type AnnouncementDelivery,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

const delivery = (
  channel: AnnouncementChannelEnum,
  status: AnnouncementDeliveryStatusEnum,
): AnnouncementDelivery => ({
  channel,
  status,
  attempts: 1,
  engagementTrackable: false,
});

describe("AnnouncementDeliverySummary", () => {
  it("counts the channels that went out", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        deliveries: [
          delivery(
            AnnouncementChannelEnum.IN_APP,
            AnnouncementDeliveryStatusEnum.SUCCEEDED,
          ),
          delivery(
            AnnouncementChannelEnum.DISCORD,
            AnnouncementDeliveryStatusEnum.SUCCEEDED,
          ),
          delivery(
            AnnouncementChannelEnum.X,
            AnnouncementDeliveryStatusEnum.SUCCEEDED,
          ),
        ],
      },
    });

    expect(wrapper.text()).toBe("3/3 sent");
    expect(wrapper.find(".base-pill--success").exists()).toBe(true);
  });

  it("calls out failures and channels still in flight", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        deliveries: [
          delivery(
            AnnouncementChannelEnum.DISCORD,
            AnnouncementDeliveryStatusEnum.SUCCEEDED,
          ),
          delivery(
            AnnouncementChannelEnum.BLUESKY,
            AnnouncementDeliveryStatusEnum.FAILED,
          ),
          delivery(
            AnnouncementChannelEnum.X,
            AnnouncementDeliveryStatusEnum.PENDING,
          ),
        ],
      },
    });

    expect(wrapper.text()).toBe("1/3 sent · 1 failed · 1 pending");
    expect(wrapper.find(".base-pill--danger").exists()).toBe(true);
  });
});
