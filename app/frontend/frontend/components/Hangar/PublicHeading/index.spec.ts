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

  // The insignia is full-colour art and the pill is one flat tone, so inside it
  // the two fought. It sits on its own line under the username instead.
  it("keeps the tier insignia out of the wordmark", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 2 });

    // `get` throws when it is missing, so reaching the next line is the
    // assertion that it rendered at all.
    wrapper.get('[data-test="supporter-badge"]');

    expect(
      wrapper
        .get('[data-test="pill"]')
        .find('[data-test="supporter-badge"]')
        .exists(),
    ).toBe(false);
  });

  it("shows no insignia for a supporter below the first band", () => {
    const wrapper = mountWith({ supporter: true, supporterTier: 0 });

    expect(wrapper.find('[data-test="supporter-badge"]').exists()).toBe(false);
  });
});
