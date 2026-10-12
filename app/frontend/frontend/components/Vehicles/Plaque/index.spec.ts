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
    expect(credits.findAll("h4")[4].text()).toBe("Civilian Operations");
    expect(credits.text()).toContain("Chris Roberts");
  });
});

describe("VehiclePlaque operations crew", () => {
  it("follows the captain's side of the law", async () => {
    const wrapper = await mount({ vehicle: vehicle({ alignment: "outlaw" }) });

    expect(
      wrapper.findAll('[data-test="vehicle-plaque-credits"] h4')[4].text(),
    ).toBe("Outlaw Operations");
  });

  it("falls back to the maker's name without a short name", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.find('[data-test="vehicle-plaque-credits"] h4').text()).toBe(
      "RSI Founders",
    );
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
