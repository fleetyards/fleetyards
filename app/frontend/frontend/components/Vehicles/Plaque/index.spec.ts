import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { inUniverseLaunchDate } from "./launchDate";
import { PLAQUE_CREDITS } from "./credits";
import { type Vehicle } from "@/services/fyApi";

const NOW = "2026-10-12T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    modelPaintIds: [],
    model: {
      id: "model-1",
      name: "Constellation Phoenix",
      slug: "constellation-phoenix",
      media: {},
      manufacturer: {
        name: "RSI",
        longName: "Roberts Space Industries",
        slug: "rsi",
        createdAt: NOW,
        updatedAt: NOW,
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

const mount = (props: { vehicle: Vehicle; captain?: string }) =>
  mountWithDefaults<typeof Component>(Component, { props });

const line = (
  wrapper: Awaited<ReturnType<typeof mount>>,
  key: string,
): string | undefined => {
  const element = wrapper.find(`[data-test="vehicle-plaque-${key}"]`);

  return element.exists() ? element.text() : undefined;
};

describe("inUniverseLaunchDate", () => {
  it("moves the year 930 years ahead and keeps the month", () => {
    expect(inUniverseLaunchDate("2026-10-12", "en")).toEqual({
      month: "October",
      year: 2956,
    });
  });

  it("keeps the month in the first days of a month west of UTC", () => {
    expect(inUniverseLaunchDate("2026-03-01", "en").month).toBe("March");
  });
});

describe("VehiclePlaque", () => {
  it("composes every line from the ship and its owner", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        name: "The Only Constant",
        serial: "CNST-0001",
        shipyard: "London Ship Yards, Earth (Sol III)",
        launchedOn: "2022-10-08",
        launchPort: "Manchester Star Port",
        affiliation: "United Empire of Earth",
        dedication: "The only constant in game development is change.",
      }),
      captain: "Jared",
    });

    expect(line(wrapper, "name")).toBe("The Only Constant");
    expect(line(wrapper, "class")).toBe(
      "Constellation Phoenix by Roberts Space Industries",
    );
    expect(line(wrapper, "registry")).toBe("Registry CNST-0001");
    expect(line(wrapper, "shipyard")).toBe(
      "Commissioned from London Ship Yards, Earth (Sol III)",
    );
    expect(line(wrapper, "launch")).toBe(
      "Launched October 2952, Manchester Star Port",
    );
    expect(line(wrapper, "captain")).toBe(
      "Captain Jared, United Empire of Earth",
    );
    expect(line(wrapper, "dedication")).toBe(
      "“The only constant in game development is change.”",
    );
  });

  it("names the captain saved with the plaque in the owner's place", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ dedication: "To boldly go", plaqueCaptain: "Maru" }),
      captain: "Jared",
    });

    expect(line(wrapper, "captain")).toBe("Captain Maru");
  });

  it("names the saved captain even without an owner to name", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ dedication: "To boldly go", plaqueCaptain: "Maru" }),
    });

    expect(line(wrapper, "captain")).toBe("Captain Maru");
  });

  it("names an unnamed ship after its model and leaves out lines with nothing to say", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ dedication: "To boldly go" }),
    });

    expect(line(wrapper, "name")).toBe("Constellation Phoenix");
    expect(line(wrapper, "registry")).toBeUndefined();
    expect(line(wrapper, "shipyard")).toBeUndefined();
    expect(line(wrapper, "launch")).toBeUndefined();
    expect(line(wrapper, "captain")).toBeUndefined();
  });

  it("names the launch port alone when there is no date", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ launchPort: "Port Olisar" }),
    });

    expect(line(wrapper, "launch")).toBe("Launched from Port Olisar");
  });

  it("credits the people who make the game", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ manufacturerShortName: "RSI" }),
    });
    const credits = wrapper.find('[data-test="vehicle-plaque-credits"]');

    expect(credits.findAll("section")).toHaveLength(5);
    expect(credits.find("h4").text()).toBe("RSI Founders");
    expect(credits.findAll("h4")[4].text()).toBe("UEE Operations");
    expect(credits.text()).toContain("Chris Roberts");
  });
});

describe("VehiclePlaque operations crew", () => {
  it("credits the lore group the captain picked", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ operationsGroup: "nine_tails" }),
    });

    expect(
      wrapper.findAll('[data-test="vehicle-plaque-credits"] h4')[4].text(),
    ).toBe("Nine Tails");
  });

  it("falls back to the maker's name without a short name", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.find('[data-test="vehicle-plaque-credits"] h4').text()).toBe(
      "RSI Founders",
    );
  });
});

describe("VehiclePlaque styles", () => {
  const plaque = async (overrides: Partial<Vehicle>) =>
    (await mount({ vehicle: vehicle({ dedication: "x", ...overrides }) })).find(
      '[data-test="vehicle-plaque"]',
    );

  it("draws a general style by its name", async () => {
    expect((await plaque({ plaqueStyle: "neon" })).classes()).toContain(
      "vehicle-plaque--neon",
    );
  });

  it("draws the manufacturer style of a maker that has one", async () => {
    const classes = (
      await plaque({ plaqueStyle: "manufacturer", manufacturerCode: "DRAK" })
    ).classes();

    expect(classes).toContain("vehicle-plaque--maker-drake");
  });

  it("falls back to brass for a maker without a style of its own", async () => {
    expect(
      (
        await plaque({ plaqueStyle: "manufacturer", manufacturerCode: "NOPE" })
      ).classes(),
    ).toContain("vehicle-plaque--brass");
  });

  it("draws brass when no style is sent", async () => {
    expect((await plaque({})).classes()).toContain("vehicle-plaque--brass");
  });

  it("keeps a multi-colour emblem as it is in its maker style", async () => {
    const emblem = (
      await plaque({ plaqueStyle: "manufacturer", manufacturerCode: "KRIG" })
    ).find('[data-test="vehicle-plaque-emblem"]');

    expect(emblem.element.tagName).toBe("IMG");
  });

  it("tints the single-colour cut of a filled emblem in a general style", async () => {
    const emblem = (
      await plaque({ plaqueStyle: "brass", manufacturerCode: "KRIG" })
    ).find('[data-test="vehicle-plaque-emblem"]');

    expect(emblem.classes()).toContain("vehicle-plaque__emblem");
    expect(emblem.attributes("style")).toContain("krig-mono");
  });
});

describe("PLAQUE_CREDITS", () => {
  it("fills five columns with the same number of distinct names", () => {
    const counts = PLAQUE_CREDITS.map((group) => group.names.length);
    const names = PLAQUE_CREDITS.flatMap((group) => group.names);

    expect(PLAQUE_CREDITS).toHaveLength(5);
    expect(new Set(counts).size).toBe(1);
    expect(new Set(names).size).toBe(names.length);
  });
});
