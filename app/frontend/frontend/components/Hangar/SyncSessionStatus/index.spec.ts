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

  it("says what the session is for, under the account", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        status: "connected",
        handle: "TestPilot",
        hint: "The sync reads your pledges through this session.",
      },
    });

    expect(wrapper.text()).toContain(
      "The sync reads your pledges through this session.",
    );
    expect(wrapper.find('[data-test="alert"]').exists()).toBe(false);
  });

  // Only a missing session is news; a connected or pending one stays a row.
  it("raises a notice only without a session", async () => {
    const pending = await mountWithDefaults(Component, {
      props: { status: "pending" },
    });
    const missing = await mountWithDefaults(Component, {
      props: { status: "notFound" },
    });

    expect(pending.find('[data-test="alert"]').exists()).toBe(false);
    expect(missing.find('[data-test="alert"]').exists()).toBe(true);
  });
});
