import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import HangarSyncResult from "./index.vue";
import type { SyncProcessStep } from "./types";

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
});
