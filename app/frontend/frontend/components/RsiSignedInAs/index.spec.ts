import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("RsiSignedInAs", () => {
  it("links the handle to the RSI account inside the sentence", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { handle: "TestPilot" },
    });

    const link = wrapper.find('[data-test="rsi-signed-in-as-handle"]');
    expect(link.text()).toBe("TestPilot");
    expect(link.attributes("href")).toBe(
      "https://robertsspaceindustries.com/account/dashboard",
    );
    expect(wrapper.text()).toBe("Signed in to RSI as TestPilot");
  });
});
