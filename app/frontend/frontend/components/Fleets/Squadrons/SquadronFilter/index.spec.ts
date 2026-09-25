import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  FeatureFlagName,
  type Fleet,
  type FleetSquadron,
} from "@/services/fyApi";
import Component from "./index.vue";

const all = [
  { id: "a", name: "Combat", slug: "combat", team: false },
  { id: "b", name: "Rota", slug: "rota", team: true },
] as FleetSquadron[];

// What the mocked endpoint hands back, and whether it was asked at all: the
// query carries `enabled`, which is what keeps a fleet without the feature
// from issuing a request on every page the control is drawn on.
let items: FleetSquadron[] = all;
let askedWith: (boolean | undefined)[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadrons: (
      _slug: unknown,
      _params: unknown,
      options?: { query?: { enabled?: { value?: boolean } } },
    ) => {
      const enabled = options?.query?.enabled;
      askedWith.push(enabled?.value);

      return {
        data: ref(enabled?.value ? { items } : undefined),
        isLoading: ref(false),
      };
    },
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  items = all;
  askedWith = [];
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (features: string[]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", features, squadronsEnabled: true } as Fleet,
    },
  });

  return wrapper;
};

const segments = (subject: VueWrapper) =>
  subject
    .findAll("[data-test]")
    .map((el) => el.attributes("data-test"))
    .filter((name) => name?.startsWith("squadron-filter-"));

/*
 * The control is drawn on the roster, the ship list and the stats page, so a
 * fleet that has no squadrons -- or has not been given the feature -- would
 * otherwise meet an empty segmented control on three pages.
 */
describe("FleetSquadronFilter", () => {
  it("draws nothing without the feature, and does not ask", async () => {
    const subject = await mount([]);

    expect(subject.find("[data-test]").exists()).toBe(false);
    expect(askedWith).toEqual([false]);
  });

  it("draws nothing for a fleet that has no squadrons", async () => {
    items = [];

    const subject = await mount([FeatureFlagName.FLEET_SQUADRONS]);

    expect(subject.find("[data-test]").exists()).toBe(false);
  });

  it("offers All plus a segment per squadron and team", async () => {
    const subject = await mount([FeatureFlagName.FLEET_SQUADRONS]);

    expect(segments(subject)).toEqual([
      "squadron-filter-all",
      "squadron-filter-combat",
      "squadron-filter-rota",
    ]);
  });
});
