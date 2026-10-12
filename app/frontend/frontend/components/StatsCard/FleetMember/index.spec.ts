import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { FleetMember } from "@/services/fyApi";
import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "home", component: { template: "<div />" } }],
  });

const member = (overrides: Partial<FleetMember> = {}) =>
  ({
    id: "m",
    username: "kestrel",
    nickname: "Kes",
    rsiHandle: "KestrelVane",
    verified: false,
    fleetRole: { id: "r", name: "Officer", slug: "officer" },
    acceptedAt: "2025-03-01T00:00:00Z",
    lastActiveAt: null,
    currentSystem: "Stanton",
    squadrons: [{ id: "s", name: "Alpha Wing", slug: "alpha", team: false }],
    ...overrides,
  }) as unknown as FleetMember;

const mount = (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults(Component, { props, plugins: [router()] });

describe("FleetMemberStatsCard", () => {
  it("shows the member's fleet facts at a glance", async () => {
    const wrapper = await mount({ member: member(), fleetSid: "MARU" });
    const text = wrapper.text();

    expect(text).toContain("kestrel");
    expect(text).toContain("Officer");
    expect(text).toContain("Kes");
    // Drawn as its emblem; the name is the badge's title.
    expect(wrapper.find("[title='Alpha Wing']").exists()).toBe(true);
    expect(text).toContain("Stanton");
    expect(text).toContain("Not verified");
  });

  // Without the fleet's SID there is nothing to be verified against.
  it("says nothing about verification for a fleet without an RSI SID", async () => {
    const wrapper = await mount({ member: member() });

    expect(wrapper.text()).not.toContain("verified");
  });

  it("offers to contact a member with an RSI handle", async () => {
    const wrapper = await mount({ member: member() });

    expect(wrapper.find("a[href*='spectrum/messages']").exists()).toBe(true);
  });
});
