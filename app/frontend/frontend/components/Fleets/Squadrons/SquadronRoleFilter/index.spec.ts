import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import type { FleetSquadron } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useModelClassificationsFilters: () => ({
      data: ref([{ value: "combat", label: "Combat" }]),
    }),
  };
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const squadron = (overrides: Partial<FleetSquadron>) =>
  ({
    slug: "alpha",
    classifications: [],
    foci: [],
    fociLabels: [],
    ...overrides,
  }) as FleetSquadron;

const mount = async (overrides: Partial<FleetSquadron>) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleetSlug: "maru", squadron: squadron(overrides) },
  });

  return wrapper;
};

describe("SquadronRoleFilter", () => {
  it("says every ship counts while there is no filter", async () => {
    const subject = await mount({});

    expect(subject.findAll(".base-pill")).toHaveLength(0);
    expect(subject.find(".squadron-role-filter__none").exists()).toBe(true);
  });

  it("names the classifications and foci the filter allows", async () => {
    const subject = await mount({
      classifications: ["combat"],
      foci: ["light_fighter"],
      fociLabels: ["Light Fighter"],
    });

    expect(subject.findAll(".base-pill").map((pill) => pill.text())).toEqual([
      "Combat",
      "Light Fighter",
    ]);
  });

  it("offers the edit only to somebody who may change the filter", async () => {
    const readOnly = await mount({});
    expect(
      readOnly.find('[data-test="squadron-role-filter-edit"]').exists(),
    ).toBe(false);
    readOnly.unmount();

    const editable = await mount({
      capabilities: {
        manageMembers: false,
        manageRanks: false,
        manageRoleFilter: true,
      },
    });
    expect(
      editable.find('[data-test="squadron-role-filter-edit"]').exists(),
    ).toBe(true);
  });
});
