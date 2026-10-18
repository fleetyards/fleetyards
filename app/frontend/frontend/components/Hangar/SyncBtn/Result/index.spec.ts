import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import HangarSyncResult from "./index.vue";
import type { SyncProcessStep } from "./types";
import {
  type HangarSyncResult as Result,
  HangarSyncOutcomeEnum,
  RsiHangarItemKindEnum,
} from "@/services/fyApi";
import { createMemoryHistory, createRouter } from "vue-router";

// jsdom has no matchMedia; the disclosures ask it for reduced motion.
vi.stubGlobal(
  "matchMedia",
  vi.fn(() => ({
    matches: false,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  })),
);

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
          dt.element.nextElementSibling?.getAttribute("data-count") ??
            dt.element.nextElementSibling?.textContent?.trim(),
        ]),
    );

    // The total sums the rows, so the two never disagree.
    expect(wrapper.text()).toContain("Pledge items: 4");
    expect(rows["Paints"]).toBe("1");
    expect(rows["Hangar flair"]).toBe("2");
  });

  describe("saving", () => {
    // The link names the import's page, which the shared test router lacks.
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/", component: { template: "<div />" } },
        {
          path: "/hangar/imports/:id/",
          name: "hangar-import",
          component: { template: "<div />" },
        },
      ],
    });

    const mountSaving = (importId?: string) =>
      mountWithDefaults(HangarSyncResult, {
        plugins: [router],
        props: {
          processSteps: [
            { name: "fetchHangar", status: "success" },
            { name: "submitData", status: "processing" },
          ],
          currentPage: 2,
          importId,
          pledges: [
            { id: "1", name: "Cutter", type: RsiHangarItemKindEnum.SHIP },
          ],
          finished: false,
          finishedWithErrors: false,
        },
      });

    const detail = (wrapper: Awaited<ReturnType<typeof mountSaving>>) =>
      wrapper
        .get(
          "[data-test='sync-step-submitData'] .sync-steps__detail [data-text]",
        )
        .attributes("data-text");

    it("says what is on its way while the request is out", async () => {
      const wrapper = await mountSaving();

      expect(detail(wrapper)).toBe("Sending 1 item");
      expect(wrapper.find("[data-test='sync-import-link']").exists()).toBe(
        false,
      );
    });

    it("links the import the server took the items as", async () => {
      const wrapper = await mountSaving("import-1");

      expect(detail(wrapper)).toBe("Sent 1 item");
      expect(
        wrapper.get("[data-test='sync-import-link']").attributes("href"),
      ).toContain("/hangar/imports/import-1");
    });
  });

  describe("against the last sync", () => {
    const lastRead = {
      finishedAt: "2026-10-11T18:00:00Z",
      pages: 2,
      total: 4,
      counts: {
        ship: 2,
        component: 0,
        upgrade: 0,
        skin: 1,
        flair: 0,
        equipment: 1,
        ccu: 0,
        extra: 0,
      },
    };

    const pledges = [
      { id: "1", name: "Cutter", type: RsiHangarItemKindEnum.SHIP },
      { id: "2", name: "Space Globe", type: RsiHangarItemKindEnum.FLAIR },
    ];

    const mountAgainstLast = (status: "processing" | "success") =>
      mountWithDefaults(HangarSyncResult, {
        props: {
          processSteps: [{ name: "fetchHangar", status }],
          currentPage: 2,
          lastRead,
          pledges,
          finished: false,
          finishedWithErrors: false,
        },
      });

    it("lists every kind the last sync read from the start, with its figure", async () => {
      const wrapper = await mountAgainstLast("processing");

      expect(
        wrapper.get("[data-test='sync-count-ships-aside']").text(),
      ).toContain("of 2");
      // Not read yet this run, but the last sync had one.
      expect(
        wrapper
          .get("[data-test='sync-count-equipment'] dd")
          .attributes("data-count"),
      ).toBe("0");
      expect(
        wrapper
          .get("[data-test='sync-step-fetchHangar-caption'] [data-text]")
          .attributes("data-text"),
      ).toBe("2 of about 4 items");
    });

    it("says how far a run that read everything ended from the last sync", async () => {
      const wrapper = await mountAgainstLast("success");

      expect(
        wrapper.get("[data-test='sync-count-ships-aside']").text(),
      ).toContain("\u22121");
      expect(
        wrapper.get("[data-test='sync-count-hangarFlair-aside']").text(),
      ).toContain("+1");
      expect(
        wrapper
          .get("[data-test='sync-step-fetchHangar-caption'] [data-text]")
          .attributes("data-text"),
      ).toBe("2 fewer than the last sync");

      // Each kind measures itself against the last sync on its own bar.
      const ships = wrapper.get(
        "[data-test='sync-count-ships'] [role='progressbar']",
      );
      expect(ships.attributes("aria-valuenow")).toBe("1");
      expect(ships.find(".sync-progress-bar__gap").exists()).toBe(true);
    });

    it("measures nothing for a run that stopped reading", async () => {
      const wrapper = await mountWithDefaults(HangarSyncResult, {
        props: {
          processSteps: [{ name: "fetchHangar", status: "failure" }],
          currentPage: 2,
          lastRead,
          pledges,
          finished: false,
          finishedWithErrors: true,
        },
      });

      expect(wrapper.find("[role='progressbar']").exists()).toBe(false);
      expect(
        wrapper.find("[data-test='sync-count-ships-aside']").exists(),
      ).toBe(false);
      expect(
        wrapper.find("[data-test='sync-step-fetchHangar-caption']").exists(),
      ).toBe(false);
    });
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
    expect(
      wrapper
        .find("[data-test='ccus-not-synced'] + dd")
        .attributes("data-count"),
    ).toBe("1");
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
    expect(text).toContain("FPS gear (not synced)");
    expect(text).toContain("Other");
    expect(
      wrapper
        .find("[data-test='equipment-not-synced'] + dd")
        .attributes("data-count"),
    ).toBe("1");
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

    it("shows the result under the save, with what was read folded away", async () => {
      const wrapper = await mountFinished({ importedVehicles: ["v-1"] });

      expect(
        wrapper
          .get("[data-test='sync-step-fetchHangar-heading']")
          .attributes("aria-expanded"),
      ).toBe("false");
      const save = wrapper.get("[data-test='sync-step-submitData']");
      expect(save.find("[data-test='sync-count-ships']").exists()).toBe(true);
      expect(
        save.get(".sync-steps__detail [data-text]").attributes("data-text"),
      ).toBe("Sent 0 items");
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
      // A kind counts all of it, found and added; the new ones are a note.
      const ships = wrapper.get("[data-test='sync-count-ships']");
      expect(ships.get("dd").attributes("data-count")).toBe("3");
      expect(ships.get("dt").text()).toContain("+2 new");
      // Nothing to show is not a row reading zero.
      expect(
        wrapper.find("[data-test='sync-count-deletedVehicles']").exists(),
      ).toBe(false);
    });

    it("reports a run that found nothing to change as such", async () => {
      const wrapper = await mountFinished({
        outcome: HangarSyncOutcomeEnum.NOTHING_TO_SYNC,
      });
      const status = wrapper.get("[data-test='sync-result-status']");

      expect(status.find(".base-alert--success").exists()).toBe(false);
      expect(status.find(".base-alert--neutral").exists()).toBe(true);
      expect(status.text()).toContain("nothing was changed");
    });

    it("lists everything it could not match, by kind", async () => {
      const wrapper = await mountFinished({
        missingModels: ["Mystery Ship", "Unknown Variant"],
        missingUpgrades: ["Upgrade X"],
      });

      expect(
        wrapper
          .get("[data-test='sync-result-status'] .base-alert--warning")
          .text(),
      ).toContain("3 items could not be matched");

      // Finished, but not cleanly: the save says so on its step.
      expect(
        wrapper
          .get("[data-test='sync-step-submitData']")
          .attributes("data-status"),
      ).toBe("warning");
      expect(
        wrapper
          .get("[data-test='sync-step-fetchHangar']")
          .attributes("data-status"),
      ).toBe("done");

      // Every group is listed in full, none of them folded away.
      const ships = wrapper.get("[data-test='sync-unmatched-missingModels']");
      expect(ships.find("button").exists()).toBe(false);
      expect(ships.findAll("li").map((item) => item.text())).toEqual([
        "Mystery Ship",
        "Unknown Variant",
      ]);
      expect(
        wrapper
          .get("[data-test='sync-unmatched-missingUpgrades']")
          .findAll("li")
          .map((item) => item.text()),
      ).toEqual(["Upgrade X"]);
    });
  });

  // The job writes ship by ship without a transaction, so a failed save may
  // have changed some already; retrying matches them again.
  it("names the step that failed, and says a failed save may be partly in", async () => {
    const wrapper = await mount([
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "backendFailure" },
    ]);

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

  // The page past the end, which only tells the run it is over, is not read.
  it("counts the pages read without the one that ended the list", async () => {
    const wrapper = await mountWithDefaults(HangarSyncResult, {
      props: {
        processSteps: [
          { name: "fetchHangar", status: "success" },
          { name: "submitData", status: "processing" },
        ],
        currentPage: 59,
        totalPages: 58,
        pledges: [],
        finished: false,
        finishedWithErrors: false,
      },
    });

    expect(wrapper.get("[data-test='sync-step-fetchHangar']").text()).toContain(
      "Pages read: 58",
    );
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
