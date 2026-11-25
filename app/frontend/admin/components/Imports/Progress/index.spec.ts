import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Import,
  type ImportProgress,
  ImportProgressStepEnum,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import Component from "./index.vue";

const progress = (overrides: Partial<ImportProgress> = {}): ImportProgress => ({
  step: ImportProgressStepEnum.ITEMS,
  stepNumber: 3,
  steps: 11,
  done: 25,
  total: 100,
  progressedAt: "2026-11-25T10:00:00Z",
  ...overrides,
});

const anImport = (overrides: Partial<Import> = {}): Import => ({
  id: "import-1",
  type: ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT,
  status: ImportStatusEnum.STARTED,
  createdAt: "2026-11-25T09:00:00Z",
  updatedAt: "2026-11-25T10:00:00Z",
  progress: progress(),
  ...overrides,
});

const mount = (record: Import, imports: Record<string, Import> = {}) =>
  mountWithDefaults(Component, {
    props: { record },
    initialState: { adminImports: { imports } },
  });

const bar = "[role='progressbar']";

describe("ImportsProgress", () => {
  it("shows how far the current step is", async () => {
    const wrapper = await mount(anImport());

    expect(wrapper.text()).toContain("Items, step 3 of 11");
    expect(wrapper.text()).toContain("25 / 100");
    expect(wrapper.find(bar).attributes("aria-valuenow")).toBe("25");
  });

  it("names the step alone where there is only one", async () => {
    const wrapper = await mount(
      anImport({
        progress: progress({
          step: ImportProgressStepEnum.SHIP_VIEWS,
          stepNumber: 1,
          steps: 1,
        }),
      }),
    );

    expect(wrapper.text()).toContain("Ship views");
    expect(wrapper.text()).not.toContain("step 1");
  });

  it("follows the broadcast rather than the record the page fetched", async () => {
    const live = anImport({
      updatedAt: "2026-11-25T10:00:03Z",
      progress: progress({ done: 80 }),
    });
    const wrapper = await mount(anImport(), { "import-1": live });

    expect(wrapper.text()).toContain("80 / 100");
  });

  it("drops a run that was cleared without a broadcast", async () => {
    const cleared = anImport({
      status: ImportStatusEnum.FAILED,
      updatedAt: "2026-11-25T10:05:00Z",
    });
    const wrapper = await mount(cleared, { "import-1": anImport() });

    expect(wrapper.classes()).toContain("import-progress--failed");
  });

  it("shows no count for a step without a total", async () => {
    const wrapper = await mount(
      anImport({ progress: progress({ total: undefined, done: 0 }) }),
    );

    expect(wrapper.find("[data-test='import-progress-count']").exists()).toBe(
      false,
    );
    expect(wrapper.find(bar).attributes("aria-valuenow")).toBeUndefined();
  });

  it("keeps where a failed run stopped", async () => {
    const wrapper = await mount(anImport({ status: ImportStatusEnum.FAILED }));

    expect(wrapper.text()).toContain("Items, step 3 of 11");
    expect(wrapper.classes()).toContain("import-progress--failed");
  });

  it("shows nothing for a finished run or one that reports no progress", async () => {
    const finished = await mount(
      anImport({ status: ImportStatusEnum.FINISHED }),
    );
    const silent = await mount(anImport({ progress: undefined }));

    expect(finished.find("[data-test='import-progress']").exists()).toBe(false);
    expect(silent.find("[data-test='import-progress']").exists()).toBe(false);
  });
});
