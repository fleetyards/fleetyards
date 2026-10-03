import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type FleetDirectoryEntry } from "@/services/fyApi";
import Component from "./index.vue";

const routerOnDirectory = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/fleets/directory",
        name: "fleet-directory",
        component: { template: "<div />" },
      },
      {
        path: "/fleets/:slug",
        name: "fleet",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "fleet-directory" });
  await router.isReady();

  return router;
};

const entry = (attrs: Partial<FleetDirectoryEntry> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    fid: "NIGHT",
    slug: "night",
    name: "Night Pirates",
    rsiSid: "PIRATES",
    memberCount: 12,
    alignment: "outlaw",
    primaryActivity: "piracy",
    secondaryActivity: "smuggling",
    commitment: "hardcore",
    language: "de",
    roleplay: true,
    recruiting: false,
    defaultTimezone: "UTC",
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as FleetDirectoryEntry;

const mount = async (attrs: Partial<FleetDirectoryEntry> = {}) =>
  mountWithDefaults(Component, {
    props: { fleet: entry(attrs) },
    plugins: [await routerOnDirectory()],
  });

describe("Fleets/Directory/Card", () => {
  it("links the name to the fleet page", async () => {
    const wrapper = await mount();

    expect(wrapper.find('a[href="#/fleets/night"]').exists()).toBe(true);
  });

  it("narrows the directory by either activity", async () => {
    const wrapper = await mount();
    const hrefs = wrapper.findAll("a").map((link) => link.attributes("href"));

    expect(hrefs).toContain("#/fleets/directory?activityIn=piracy");
    expect(hrefs).toContain("#/fleets/directory?activityIn=smuggling");
    expect(hrefs).toContain("#/fleets/directory?languageIn=de");
  });

  it("names the SID, the language and whether the fleet recruits", async () => {
    const wrapper = await mount();
    const text = wrapper.text();

    expect(text).toContain("PIRATES");
    expect(text).toContain("German");
    expect(text).toContain("Not recruiting");
  });

  it("leaves out an SID the FID already shows", async () => {
    const wrapper = await mount({ rsiSid: "night" });

    expect(wrapper.text()).toContain("NIGHT");
    expect(wrapper.text()).not.toContain("SID");
  });

  it("leaves out what RSI has not told us", async () => {
    const wrapper = await mount({
      primaryActivity: null,
      secondaryActivity: null,
      language: null,
      recruiting: null,
      alignment: null,
      commitment: null,
      roleplay: null,
    });

    expect(wrapper.text()).not.toContain("recruiting");
    expect(wrapper.findAll("a")).toHaveLength(1);
  });
});
