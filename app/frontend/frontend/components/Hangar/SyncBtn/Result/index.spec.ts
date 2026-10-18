import { describe, expect, it } from "vitest";
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
  it("runs a bar on the step in progress, named by the step", async () => {
    const wrapper = await mount([
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "processing" },
    ]);

    expect(
      wrapper
        .find("[data-test='sync-step-fetchHangar'] [role='progressbar']")
        .exists(),
    ).toBe(false);

    const bar = wrapper.get(
      "[data-test='sync-step-submitData'] [role='progressbar']",
    );
    expect(bar.attributes("aria-label")).toBe("Saving to Fleetyards");
    // Saving is one request: it knows no fraction to report.
    expect(bar.attributes("aria-valuenow")).toBeUndefined();
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

    expect(wrapper.text()).toContain("Pledge items: 5");
    expect(rows["Paints"]).toBe("1");
    expect(rows["Hangar Flair"]).toBe("2");
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
      "Paints (not synced)",
    );

    const flairOff = await mountWith(true, false);
    expect(flairOff.find("[data-test='paints-not-synced']").exists()).toBe(
      false,
    );
    expect(
      flairOff.find("[data-test='hangar-flair-not-synced']").exists(),
    ).toBe(true);
  });

  it("counts CCU rows separately and marks them when sync is disabled", async () => {
    const ccu = {
      id: "1",
      name: "Upgrade - Aurora To Cutter",
      type: RsiHangarItemKindEnum.CCU,
    };
    const wrapper = await mountWithDefaults(HangarSyncResult, {
      props: {
        processSteps: [{ name: "fetchHangar", status: "success" }],
        currentPage: 1,
        pledges: [ccu, ccu],
        finished: false,
        finishedWithErrors: false,
        syncCcus: false,
      },
    });
    expect(wrapper.find("[data-test='ccus-not-synced'] + dd").text()).toBe("1");
  });

  it("counts FPS equipment, and the extras the server sorts on storing", async () => {
    const wrapper = await mountWithDefaults(HangarSyncResult, {
      props: {
        processSteps: [{ name: "fetchHangar", status: "success" }],
        currentPage: 1,
        pledges: [
          {
            id: "1",
            name: "Arrowhead Sniper Rifle",
            type: RsiHangarItemKindEnum.EQUIPMENT,
          },
          {
            id: "2",
            name: "Self-Land Hangar",
            type: RsiHangarItemKindEnum.EXTRA,
          },
          {
            id: "2",
            name: "Gallant ‘Redline’ Rifle",
            type: RsiHangarItemKindEnum.EXTRA,
          },
        ],
        finished: false,
        finishedWithErrors: false,
        syncEquipment: false,
      },
    });

    const text = wrapper.text();
    expect(text).toContain("FPS Gear (not synced)");
    expect(text).toContain("Other Items (sorted into flair and FPS gear)");
    expect(wrapper.find("[data-test='equipment-not-synced'] + dd").text()).toBe(
      "1",
    );
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

  describe("once it has finished", () => {
    const emptyResult: Result = {
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
    const mountFinished = (extra: Partial<Result>) =>
      mountWithDefaults(HangarSyncResult, {
        props: {
          processSteps: [
            { name: "fetchHangar", status: "success" },
            { name: "submitData", status: "success" },
          ],
          currentPage: 1,
          pledges: [],
          finished: true,
          finishedWithErrors: false,
          result: { ...emptyResult, ...extra },
        },
      });

    it("leads with the outcome and counts what changed", async () => {
      const wrapper = await mountFinished({
        importedVehicles: ["v-1", "v-2"],
        foundVehicles: ["v-3"],
      });

      expect(
        wrapper
          .find("[data-test='sync-result-status'] .base-alert--success")
          .exists(),
      ).toBe(true);
      expect(
        wrapper
          .get("[data-test='sync-result-tile-importedVehicles'] dd")
          .text(),
      ).toBe("2");
      // Nothing to show is not a tile reading zero.
      expect(
        wrapper.find("[data-test='sync-result-tile-deletedVehicles']").exists(),
      ).toBe(false);
    });

    it("lists what it could not match, the first group open", async () => {
      const wrapper = await mountFinished({
        missingModels: ["Mystery Ship", "Unknown Variant"],
        missingUpgrades: ["Upgrade X"],
      });

      expect(
        wrapper
          .get("[data-test='sync-result-status'] .base-alert--warning")
          .text(),
      ).toContain("3 items could not be matched");

      const ships = wrapper.get("[data-test='sync-unmatched-missingModels']");
      expect(ships.attributes("open")).toBeDefined();
      expect(ships.findAll("li").map((item) => item.text())).toEqual([
        "Mystery Ship",
        "Unknown Variant",
      ]);
      expect(
        wrapper
          .get("[data-test='sync-unmatched-missingUpgrades']")
          .attributes("open"),
      ).toBeUndefined();
    });
  });

  // The job writes ship by ship without a transaction, so a failed save may
  // have changed some already; retrying matches them again.
  it("names the step that failed, and says a failed save may be partly in", async () => {
    const wrapper = await mount([
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "backendFailure" },
    ]);
    await wrapper.setProps({ finishedWithErrors: true });

    const status = wrapper.get("[data-test='sync-result-status']");
    expect(status.find(".base-alert--danger").exists()).toBe(true);
    expect(status.text()).toContain("Saving to Fleetyards failed");
    expect(status.text()).toContain("Retrying is safe");
    expect(
      wrapper
        .get("[data-test='sync-step-submitData']")
        .attributes("data-status"),
    ).toBe("failed");
  });

  it("tells a cancelled run apart from a failed one", async () => {
    const wrapper = await mountWithDefaults(HangarSyncResult, {
      props: {
        processSteps: [
          { name: "fetchHangar", status: "success" },
          { name: "submitData", status: "failure" },
        ],
        currentPage: 1,
        pledges: [],
        finished: false,
        finishedWithErrors: true,
        cancelled: true,
      },
    });

    const status = wrapper.find("[data-test='sync-result-status']");
    expect(status.text()).toBe("Import Cancelled");
    expect(status.classes()).not.toContain("text-danger");
  });
});
