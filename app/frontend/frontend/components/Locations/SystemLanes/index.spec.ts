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
    ).toEqual(["Pyro"]);
  });

  it("joins the systems with lines, labelled at both ends, once there is room", async () => {
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockReturnValue(
      new DOMRect(0, 0, 1200, 120),
    );

    const wrapper = await mountLanes();
    await flushPromises();

    const labels = wrapper.findAll("[data-test='jump-lane-label']");

    expect(wrapper.findAll("[data-test='jump-lanes'] line")).toHaveLength(2);
    expect(labels.map((label) => label.attributes("aria-label"))).toEqual(
      expect.arrayContaining([
        "nyx - Pyro Jump Point",
        "pyro - Nyx Jump Point",
        "pyro - Stanton Jump Point",
        "stanton - Pyro Jump Point",
      ]),
    );
    expect(labels).toHaveLength(4);
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
});
