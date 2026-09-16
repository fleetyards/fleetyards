import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { UserPublic } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const user = (attributes: Partial<UserPublic>) =>
  ({
    username: "alice",
    publicHangarLoaners: true,
    publicHangarStats: true,
    publicWishlist: true,
    supporter: false,
    ...attributes,
  }) as UserPublic;

const mountWith = (attributes: Partial<UserPublic>) =>
  mount(Component, {
    props: { user: user(attributes) },
    global: {
      stubs: { Avatar: true, Heading: { template: "<div><slot /></div>" } },
      directives: { tooltip: () => {} },
    },
  });

describe("HangarPublicHeading", () => {
  it("badges a supporter", () => {
    const wrapper = mountWith({ supporter: true });

    expect(wrapper.get('[data-test="pill"]').text()).toContain(
      "labels.supporter.badge",
    );
  });

  it("leaves a non-supporter unbadged", () => {
    const wrapper = mountWith({ supporter: false });

    expect(wrapper.find('[data-test="pill"]').exists()).toBe(false);
  });

  // The insignia stands in for the heart rather than sitting beside it: the
  // pill already says "supporter", and which band is the only thing left for a
  // mark to add.
  it("puts the tier insignia in place of the heart", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 2 });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(true);
    expect(pill.find(".fa-heart").exists()).toBe(false);
  });

  // Below the first band there is no insignia to stand in, so the heart it
  // replaces has to come back rather than leaving the pill wordless.
  it("falls back to the heart below the first band", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 0 });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(false);
    expect(pill.find(".fa-heart").exists()).toBe(true);
  });

  // A standing pledge that converted below a euro still has something to say,
  // so the mark shows even with no insignia to hang it on.
  it("marks a sub-band standing pledge", () => {
    const wrapper = mountWith({
      supporter: true,
      supporterTier: 0,
      supporterRecurring: true,
    });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge-recurring"]').exists()).toBe(
      true,
    );
  });
});
