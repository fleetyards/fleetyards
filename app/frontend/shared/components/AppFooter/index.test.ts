import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("AppFooter", () => {
  it("renders", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);
    expect(wrapper.exists()).toBe(true);
  });

  // Was `findAll("a")).toHaveLength(4)` - a bare count over the whole footer,
  // which broke on any change to the anchor set and would have passed just as
  // happily with four wrong ones.
  it("renders the social links", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);

    const social = wrapper.find("[data-test='app-footer-social']");

    expect(social.exists()).toBe(true);
    expect(social.findAll("a")).toHaveLength(4);
  });

  it("renders the version props it is given", async () => {
    // Every call site has always passed these; until they were declared they
    // fell through onto the root element as DOM attributes and were ignored.
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        version: "1.2.3",
        codename: "Bengal",
        gitRevision: "abc1234",
      },
    });

    const version = wrapper.find("[data-test='app-footer-version']");

    expect(version.text()).toContain("Bengal");
    expect(version.text()).toContain("1.2.3");
    expect(version.text()).toContain("abc1234");
  });

  it("renders the current year in the copyright line", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);

    expect(wrapper.text()).toContain(`${new Date().getFullYear()}`);
  });

  it("collapses the links row when nothing is slotted", async () => {
    // Admin and docs pass no links; the row still took its gap.
    const wrapper = await mountWithDefaults<typeof Component>(Component);

    expect(wrapper.find(".app-footer__links").exists()).toBe(false);
  });
});
