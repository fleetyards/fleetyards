import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { invites } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const vue = require("vue");

  return { invites: vue.ref([]) };
});

const kraken = {
  slug: "kraken",
  name: "Kraken Haulers",
  logo: { smallUrl: "/kraken.png" },
};
const drake = { slug: "drake-den", name: "Drake Den", logo: null };

vi.mock("@/services/fyApi", async () => ({
  ...(await vi.importActual<Record<string, unknown>>("@/services/fyApi")),
  useFleet: (slug: { value: string }) => ({
    data: computed(() =>
      [kraken, drake].find((fleet) => fleet.slug === slug.value),
    ),
  }),
  usePublicFleet: () => ({ data: computed(() => undefined) }),
  useMyFleets: () => ({ data: computed(() => [kraken, drake]) }),
  useFleetInvites: () => ({ data: invites }),
}));

import ContextSwitcher from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  invites.value = [];
});

const Stub = { render: () => null };

const mountSwitcher = async (path: string) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/hangar", name: "hangar", component: Stub },
      { path: "/fleets/:slug", name: "fleet", component: Stub },
      { path: "/fleets/invites", name: "fleet-invites", component: Stub },
      { path: "/fleets/directory", name: "fleet-directory", component: Stub },
      { path: "/fleets/add", name: "fleet-add", component: Stub },
    ],
  });

  await router.push(path);

  wrapper = await mountWithDefaults(ContextSwitcher, {
    props: { logo: "/logo.png", title: "Fleetyards" },
    plugins: [router],
    initialState: { nav: { slim: false } },
  });

  return wrapper;
};

const trigger = (switcher: VueWrapper) =>
  switcher.get('[data-test="nav-switcher"]');

const current = (switcher: VueWrapper) =>
  switcher.get('[data-test="nav-switcher-current"]').text();

const row = (switcher: VueWrapper, id: string) =>
  switcher.find(`[data-test="${id}"]`);

const openSwitcher = async (switcher: VueWrapper) => {
  await trigger(switcher).trigger("click");
};

describe("ContextSwitcher", () => {
  it("shows the personal hangar outside a fleet", async () => {
    const switcher = await mountSwitcher("/hangar");

    expect(current(switcher)).toContain("Personal");
  });

  it("shows the fleet that is open", async () => {
    const switcher = await mountSwitcher("/fleets/kraken");

    expect(current(switcher)).toContain("Kraken Haulers");
  });

  it("carries the open fleet's logo instead of the site's", async () => {
    const switcher = await mountSwitcher("/fleets/kraken");

    expect(
      switcher.get('[data-test="nav-switcher-logo"]').attributes("src"),
    ).toBe("/kraken.png");
  });

  it("falls back to the fleet's initials without a logo", async () => {
    const switcher = await mountSwitcher("/fleets/drake-den");

    expect(switcher.get('[data-test="nav-switcher-logo"]').text()).toBe("DD");
  });

  it("carries the site's logo in the personal hangar", async () => {
    const switcher = await mountSwitcher("/hangar");

    expect(
      switcher.get('[data-test="nav-switcher-logo"]').attributes("src"),
    ).toBe("/logo.png");
  });

  it("lists every fleet the reader is in and ticks the open one", async () => {
    const switcher = await mountSwitcher("/fleets/kraken");

    await openSwitcher(switcher);

    expect(
      row(switcher, "nav-switcher-fleet-kraken").attributes("aria-current"),
    ).toBe("page");
    expect(
      row(switcher, "nav-switcher-fleet-drake-den").attributes("aria-current"),
    ).toBeUndefined();
    expect(
      row(switcher, "nav-switcher-personal").attributes("aria-current"),
    ).toBeUndefined();
  });

  // The invites page also lists the requests the reader sent, so it stays
  // reachable with no invitation waiting; only the count depends on them.
  it("always offers invites and counts them when there are some", async () => {
    const switcher = await mountSwitcher("/hangar");

    await openSwitcher(switcher);

    expect(row(switcher, "nav-fleet-invites").exists()).toBe(true);
    expect(row(switcher, "nav-fleet-invites").text()).not.toMatch(/\d/);
    expect(row(switcher, "nav-fleet-directory").exists()).toBe(true);
    expect(row(switcher, "nav-fleet-add").exists()).toBe(true);

    invites.value = [{ id: "invite-1" }];
    await switcher.vm.$nextTick();

    expect(row(switcher, "nav-fleet-invites").text()).toContain("1");
  });
});
