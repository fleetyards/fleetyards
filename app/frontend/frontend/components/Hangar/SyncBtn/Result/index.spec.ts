import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import HangarSyncResult from "./index.vue";
import type { SyncProcessStep } from "./types";
import { RsiHangarItemKindEnum } from "@/services/fyApi";

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

  it("counts paints and hangar flair among the pledge items", async () => {
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

    expect(rows["All Pledge Items:"]).toBe("4");
    expect(rows["Paints:"]).toBe("1");
    expect(rows["Hangar Flair:"]).toBe("2");
  });
});
