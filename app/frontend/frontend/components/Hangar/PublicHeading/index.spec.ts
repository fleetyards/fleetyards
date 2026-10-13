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

  // Same insignia as the top supporter band, but its own label: a maintainer
  // is not shown as a supporter.
  it("badges a maintainer with the top insignia under their own label", () => {
    const wrapper = mountWith({
      supporter: true,
      maintainer: true,
      supporterTier: 3,
    });
    const pills = wrapper.findAll('[data-test="pill"]');
    const pill = pills[0];

    expect(pills).toHaveLength(1);

    expect(pill.text()).toContain("labels.maintainer.badge");
    expect(pill.text()).not.toContain("labels.supporter.badge");
    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(true);
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

  // Below the first band there is no insignia, recurring or not: the pill
  // carries the heart, as for any supporter without one.
  it("shows the heart for a supporter below the first band", () => {
    const wrapper = mountWith({
      supporter: true,
      supporterTier: 0,
      supporterRecurring: true,
    });
    const pill = wrapper.get('[data-test="pill"]');

    expect(pill.find('[data-test="supporter-badge"]').exists()).toBe(false);
    expect(pill.find(".fa-heart").exists()).toBe(true);
  });
});
