import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { AnnouncementStatusEnum } from "@/services/fyAdminApi";
import Component from "./index.vue";

describe("AnnouncementStatusPill", () => {
  it("labels the status rather than printing the raw value", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { status: AnnouncementStatusEnum.PUBLISHED },
    });

    expect(wrapper.find("[data-test='pill']").text()).toBe("Sent");
  });

  // A status with no variant would fall back to the primary blue, which reads
  // as "happening" for a draft and as fine for a failure.
  it("gives every status a variant of its own", async () => {
    const variants = await Promise.all(
      Object.values(AnnouncementStatusEnum).map(async (status) => {
        const wrapper = await mountWithDefaults(Component, {
          props: { status },
        });

        return wrapper.find("[data-test='pill']").classes().join();
      }),
    );

    expect(new Set(variants).size).toBe(variants.length);
  });
});
