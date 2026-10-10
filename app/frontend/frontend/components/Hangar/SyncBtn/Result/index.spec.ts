import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import HangarSyncResult from "./index.vue";
import type { SyncProcessStep } from "./types";
import {
  type HangarSyncResult as Result,
  RsiHangarItemKindEnum,
} from "@/services/fyApi";

const mount = (processSteps: SyncProcessStep[]) =>
  mountWithDefaults(HangarSyncResult, {
    props: {
      processSteps,
      currentPage: 1,
      pledges: [],
      finished: false,
      finishedWithErrors: false,
    },
  });

describe("HangarSyncResult", () => {
  it("runs the dots on the step in progress, and announces it by name", async () => {
    const wrapper = await mount([
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "processing" },
    ]);

    const dots = wrapper.findAll("[data-test='loading-dots']");
    expect(dots).toHaveLength(2);
    expect(dots[0].find(".loading-dots__dots").exists()).toBe(false);
    expect(dots[1].find(".loading-dots__dots").exists()).toBe(true);
    await vi.waitFor(() =>
      expect(dots[1].find("[role='status']").text()).toContain("…"),
    );
  });

  it("counts paints and hangar flair among the pledge items, as the sync stores them", async () => {
    const wrapper = await mountWithDefaults(HangarSyncResult, {
      props: {
        processSteps: [{ name: "fetchHangar", status: "success" }],
        currentPage: 2,
        pledges: [
          { id: "1", name: "Cutter", type: RsiHangarItemKindEnum.SHIP },
          {
            id: "2",
            name: "Cutlass - Akuma Paint",
            type: RsiHangarItemKindEnum.SKIN,
          },
          {
            id: "3",
            name: "Space Globe - Terra",
            type: RsiHangarItemKindEnum.FLAIR,
          },
          {
            id: "3",
            name: "Poster - Banu Merchantman",
            type: RsiHangarItemKindEnum.FLAIR,
          },
          {
            id: "3",
            name: "Poster - Banu Merchantman",
            type: RsiHangarItemKindEnum.FLAIR,
          },
        ],
        finished: false,
        finishedWithErrors: false,
      },
    });

    const rows = Object.fromEntries(
      wrapper
        .findAll("dt")
        .map((dt) => [
          dt.text(),
          dt.element.nextElementSibling?.textContent?.trim(),
        ]),
    );

    expect(rows["All Pledge Items:"]).toBe("5");
    expect(rows["Paints:"]).toBe("1");
    expect(rows["Hangar Flair:"]).toBe("2");
  });

  it("marks paints and hangar flair the sync leaves out as not synced", async () => {
    const pledges = [
      {
        id: "1",
        name: "Cutlass - Akuma Paint",
        type: RsiHangarItemKindEnum.SKIN,
      },
      {
        id: "2",
        name: "Space Globe - Terra",
        type: RsiHangarItemKindEnum.FLAIR,
      },
    ];
    const mountWith = (syncPaints: boolean, syncHangarFlair: boolean) =>
      mountWithDefaults(HangarSyncResult, {
        props: {
          processSteps: [{ name: "fetchHangar", status: "success" }],
          currentPage: 2,
          pledges,
          finished: false,
          finishedWithErrors: false,
          syncPaints,
          syncHangarFlair,
        },
      });

    const paintsOff = await mountWith(false, true);
    expect(paintsOff.find("[data-test='paints-not-synced']").exists()).toBe(
      true,
    );
    expect(
      paintsOff.find("[data-test='hangar-flair-not-synced']").exists(),
    ).toBe(false);

    expect(paintsOff.find("[data-test='paints-not-synced']").text()).toBe(
      "Paints (not synced):",
    );

    const flairOff = await mountWith(true, false);
    expect(flairOff.find("[data-test='paints-not-synced']").exists()).toBe(
      false,
    );
    expect(
      flairOff.find("[data-test='hangar-flair-not-synced']").exists(),
    ).toBe(true);
  });

  it("says when the sync could not read every item and left unmatched ships alone", async () => {
    const result: Result = {
      importedVehicles: [],
      foundVehicles: [],
      movedVehiclesToWanted: [],
      deletedVehicles: [],
      groupedVehicles: [],
      unchangedVehicles: [],
      missingModels: [],
      importedComponents: [],
      foundComponents: [],
      missingComponents: [],
      missingComponentVehicles: [],
      importedUpgrades: [],
      foundUpgrades: [],
      missingUpgrades: [],
      missingUpgradeVehicles: [],
    };
    const mountWith = (extra: Partial<Result>) =>
      mountWithDefaults(HangarSyncResult, {
        props: {
          processSteps: [{ name: "submitData", status: "success" }],
          currentPage: 1,
          pledges: [],
          finished: true,
          finishedWithErrors: false,
          result: { ...result, ...extra },
        },
      });

    const incomplete = await mountWith({ incomplete: true });
    const complete = await mountWith({});

    expect(incomplete.find("[data-test='sync-incomplete']").text()).toContain(
      "could not be read",
    );
    expect(complete.find("[data-test='sync-incomplete']").exists()).toBe(false);
  });
});
