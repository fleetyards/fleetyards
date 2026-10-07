import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("HangarSyncSessionStatus", () => {
  it("names the signed-in account", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { status: "connected", handle: "TestPilot" },
    });

    expect(
      wrapper.find('[data-test="sync-extension-signed-in-as"]').text(),
    ).toContain("TestPilot");
    expect(wrapper.find('[data-test="sync-session-sign-in"]').exists()).toBe(
      false,
    );
  });

  it("offers RSI's sign-in and a recheck without a session", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { status: "notFound" },
    });

    expect(
      wrapper.find('[data-test="sync-session-sign-in"]').attributes("href"),
    ).toBe("https://robertsspaceindustries.com/connect");

    await wrapper.find('[data-test="sync-session-recheck"]').trigger("click");

    expect(wrapper.emitted("recheck")).toHaveLength(1);
  });
});
