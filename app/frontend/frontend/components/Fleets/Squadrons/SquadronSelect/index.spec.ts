import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  FeatureFlagName,
  type Fleet,
  type FleetSquadron,
} from "@/services/fyApi";
import Component from "./index.vue";

const items = [
  { id: "a", name: "Alpha", slug: "alpha", team: false, discordChannelId: "1" },
  {
    id: "b",
    name: "Bravo",
    slug: "bravo",
    team: false,
    discordChannelId: null,
  },
  { id: "c", name: "Rota", slug: "rota", team: true, discordChannelId: null },
] as FleetSquadron[];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadrons: () => ({
      data: ref({ items }),
      isLoading: ref(false),
    }),
  };
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: Record<string, unknown>) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: {
        slug: "maru",
        features: [FeatureFlagName.FLEET_SQUADRONS],
        squadronsEnabled: true,
      } as Fleet,
      ...props,
    },
  });

  return wrapper;
};

const options = (subject: VueWrapper) =>
  (
    subject.findComponent({ name: "BaseSelect" }).props("options") as {
      label: string;
    }[]
  ).map((option) => option.label);

const warning = (subject: VueWrapper) =>
  subject.find('[data-test="squadrons-not-announced"]');

describe("FleetSquadronSelect", () => {
  it("names the picked squadrons that have no Discord channel", async () => {
    const subject = await mount({
      modelValue: ["a", "b", "c"],
      warnWithoutDiscordChannel: true,
    });

    expect(warning(subject).text()).toContain("Bravo, Rota");
    expect(warning(subject).text()).not.toContain("Alpha");
  });

  it("says nothing when every picked squadron has a channel", async () => {
    const subject = await mount({
      modelValue: ["a"],
      warnWithoutDiscordChannel: true,
    });

    expect(warning(subject).exists()).toBe(false);
  });

  // Contracts and inventories are never announced on Discord.
  it("says nothing unless the form asks for it", async () => {
    const subject = await mount({ modelValue: ["b"] });

    expect(warning(subject).exists()).toBe(false);
  });

  it("offers the fleet's squadrons while squadrons are on", async () => {
    const subject = await mount({});

    expect(options(subject)).toEqual(["Alpha", "Bravo", "Rota"]);
  });

  // The fleet switched squadrons off after the record was restricted; the
  // restriction stands and the event is still announced to its squadrons, so
  // they stay listed and warned about rather than read from the cache.
  it("offers only the record's own squadrons once squadrons are off", async () => {
    const subject = await mount({
      fleet: {
        slug: "maru",
        features: [FeatureFlagName.FLEET_SQUADRONS],
        squadronsEnabled: false,
      } as Fleet,
      modelValue: ["b"],
      assigned: [
        {
          id: "b",
          name: "Bravo",
          slug: "bravo",
          team: false,
          discordChannelId: null,
        },
      ],
      warnWithoutDiscordChannel: true,
    });

    expect(options(subject)).toEqual(["Bravo"]);
    expect(warning(subject).text()).toContain("Bravo");
  });
});
