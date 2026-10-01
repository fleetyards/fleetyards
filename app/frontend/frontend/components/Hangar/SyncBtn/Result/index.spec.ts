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
  it("runs the loading line under the step in progress, named for it", async () => {
    const wrapper = await mount([
      { name: "fetchHangar", status: "success" },
      { name: "submitData", status: "processing" },
    ]);

    const lines = wrapper.findAll("[data-test='loading-line']");
    expect(lines).toHaveLength(2);
    expect(lines[0].classes()).not.toContain("loading-line--active");
    expect(lines[1].classes()).toContain("loading-line--active");
    await vi.waitFor(() =>
      expect(lines[1].find("[role='status']").text()).toContain("…"),
    );
  });
});
