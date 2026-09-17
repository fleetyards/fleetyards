import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

// The block lives in shared/ and is rendered by AsyncData and FilteredList,
// which 46 admin surfaces use. The frontend app is the only one that defines a
// `support` route, and a named route the running app does not have throws
// while rendering -- the refusal would have become a blank page there.
describe("SubscriptionRequired", () => {
  const supportLink = (wrapper: {
    findAll: (s: string) => { attributes: () => Record<string, string> }[];
  }) => wrapper.findAll("a").map((link) => link.attributes().href);

  it("renders where the app has no support route", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);

    expect(wrapper.find(".subscription-required__actions").exists()).toBe(true);
    expect(supportLink(wrapper)).toContain("/support/");
  });

  it("names what supporters keep running rather than denying access", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);

    expect(wrapper.text()).not.toMatch(/denied|forbidden|clearance/i);
  });
});
