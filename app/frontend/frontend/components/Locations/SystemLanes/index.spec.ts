import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  LocationKindEnum,
  type Location,
  type LocationJumpPoint,
} from "@/services/fyApi";
import Component from "./index.vue";

vi.mock(
  "@/services/fyApi/services/locations/locations",
  async (importOriginal) => {
    const { ref } = await import("vue");

    return {
      ...(await importOriginal<object>()),
      useLocationTree: () => ({
        data: ref(null),
        isError: ref(false),
        refetch: vi.fn(),
      }),
    };
  },
);

const system = (id: string, name: string) =>
  ({ id, name, slug: id, kind: LocationKindEnum.SYSTEM }) as Location;

const jumpPoint = (
  systemId: string,
  destinationName: string,
  destinationSystemId: string | null,
): LocationJumpPoint => ({
  location: {
    id: `${systemId}-${destinationName}`,
    name: `${systemId} - ${destinationName} Jump Point`,
    slug: `${systemId}-${destinationName}`.toLowerCase(),
    kind: LocationKindEnum.JUMP_POINT,
    parentName: null,
  },
  systemId,
  destinationName,
  destinationSystemId,
});

const systems = [
  system("nyx", "Nyx System"),
  system("pyro", "Pyro System"),
  system("stanton", "Stanton System"),
];

const jumpPoints = [
  jumpPoint("nyx", "Pyro", "pyro"),
  jumpPoint("pyro", "Nyx", "nyx"),
  jumpPoint("pyro", "Stanton", "stanton"),
  jumpPoint("stanton", "Pyro", "pyro"),
  jumpPoint("stanton", "Terra", null),
];

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "locations", component: { template: "<div />" } },
    {
      path: "/locations/:slug",
      name: "location",
      component: { template: "<div />" },
    },
  ],
});

const mountLanes = (props: Partial<{ jumpPoints: LocationJumpPoint[] }> = {}) =>
  mountWithDefaults(Component, {
    props: { systems, jumpPoints, ...props },
    plugins: [router],
  });

const cardOf = (
  wrapper: Awaited<ReturnType<typeof mountLanes>>,
  name: string,
) =>
  wrapper
    .findAll(".location-system-card")
    .find((card) => card.text().includes(name));

const chipsOf = (
  wrapper: Awaited<ReturnType<typeof mountLanes>>,
  name: string,
  selector = ".location-system-card__jump-point",
) =>
  cardOf(wrapper, name)
    ?.findAll(selector)
    .map((chip) => chip.text());

describe("LocationSystemLanes", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("lists every jump point on its card when there is no room for lines", async () => {
    const wrapper = await mountLanes();

    expect(wrapper.find("[data-test='jump-lanes']").exists()).toBe(false);
    expect(chipsOf(wrapper, "Pyro System")).toEqual(["Nyx", "Stanton"]);
    expect(
      chipsOf(
        wrapper,
        "Stanton System",
        ".location-system-card__jump-point--listed",
      ),
    ).toEqual(["Pyro", "Terra"]);
  });

  it("joins the systems with lines, labelled at both ends, once there is room", async () => {
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockReturnValue(
      new DOMRect(0, 0, 1200, 120),
    );

    const wrapper = await mountLanes();
    await flushPromises();

    const labels = wrapper.findAll("[data-test='jump-lane-label']");

    expect(wrapper.findAll("[data-test='jump-lanes'] line")).toHaveLength(5);
    expect(labels.map((label) => label.attributes("aria-label"))).toEqual(
      expect.arrayContaining([
        "nyx - Pyro Jump Point",
        "pyro - Nyx Jump Point",
        "pyro - Stanton Jump Point",
        "stanton - Pyro Jump Point",
      ]),
    );
    expect(labels).toHaveLength(5);
  });

  it("keeps only the jump points that lead off the page on the cards", async () => {
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockReturnValue(
      new DOMRect(0, 0, 1200, 120),
    );

    const wrapper = await mountLanes({
      jumpPoints: [...jumpPoints, jumpPoint("nyx", "Odin", null)],
    });
    await flushPromises();

    expect(chipsOf(wrapper, "Nyx System")).toEqual(["Odin"]);
  });

  it("draws a placeholder for a system not in the game yet and joins it up", async () => {
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockReturnValue(
      new DOMRect(0, 0, 1200, 120),
    );

    const wrapper = await mountLanes();
    await flushPromises();

    const placeholders = wrapper.findAll("[data-test='placeholder-system']");

    expect(placeholders.map((card) => card.text())).toEqual(
      expect.arrayContaining([expect.stringContaining("Terra System")]),
    );
    expect(chipsOf(wrapper, "Stanton System")).toEqual([]);
    expect(
      wrapper
        .findAll("[data-test='jump-lane-label']")
        .map((label) => label.attributes("aria-label")),
    ).toContain("stanton - Terra Jump Point");
  });

  it("drops a placeholder once the system is listed", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        systems: [...systems, system("terra", "Terra System")],
        jumpPoints,
      },
      plugins: [router],
    });

    expect(
      wrapper
        .findAll("[data-test='placeholder-system']")
        .map((card) => card.text()),
    ).not.toEqual(expect.arrayContaining([expect.stringContaining("Terra")]));
  });

  it("dashes every line into a placeholder and labels its unlinked end", async () => {
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockReturnValue(
      new DOMRect(0, 0, 1200, 120),
    );

    const wrapper = await mountLanes();
    await flushPromises();

    expect(wrapper.findAll(".location-lanes__line--dashed").length).toBe(3);
    expect(
      wrapper
        .findAll("[data-test='jump-lane-plain']")
        .map((label) => label.text()),
    ).toEqual(expect.arrayContaining(["Castra", "Nyx", "Pyro", "Stanton"]));
  });
});
