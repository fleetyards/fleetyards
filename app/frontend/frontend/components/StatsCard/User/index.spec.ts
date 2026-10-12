import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { UserPublic } from "@/services/fyApi";
import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "home", component: { template: "<div />" } }],
  });

const user = (overrides: Partial<UserPublic> = {}) =>
  ({
    username: "TorlekMaru",
    rsiHandle: "TorlekMaru",
    supporter: false,
    supporterTier: 0,
    supporterRecurring: false,
    ...overrides,
  }) as unknown as UserPublic;

const mount = (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults(Component, { props, plugins: [router()] });

describe("UserStatsCard", () => {
  it("shows the presence dot only where the API answered", async () => {
    const friend = await mount({ user: user({ online: true }) });
    const stranger = await mount({ user: user() });

    expect(friend.find(".presence-dot").exists()).toBe(true);
    expect(stranger.find(".presence-dot").exists()).toBe(false);
  });

  it("marks a verified handle and a supporter", async () => {
    const wrapper = await mount({
      user: user({ rsiHandleVerified: true, supporter: true }),
    });

    expect(wrapper.find("[data-test='stats-card-status']").exists()).toBe(true);
    expect(wrapper.find(".user-card__supporter").exists()).toBe(true);
  });

  it("says neither for a user who is neither", async () => {
    const wrapper = await mount({ user: user() });

    expect(wrapper.find("[data-test='stats-card-status']").exists()).toBe(
      false,
    );
    expect(wrapper.find(".user-card__supporter").exists()).toBe(false);
  });
});
