import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const matchBlueprintLogNames = vi.fn();
const importBlueprintsFromLogs = vi.fn();
const invalidateQueries = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", () => ({
  matchBlueprintLogNames: (...args: unknown[]) =>
    matchBlueprintLogNames(...args),
  importBlueprintsFromLogs: (...args: unknown[]) =>
    importBlueprintsFromLogs(...args),
}));

vi.mock("@tanstack/vue-query", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@tanstack/vue-query")>();

  return { ...actual, useQueryClient: () => ({ invalidateQueries }) };
});

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn() }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

const Component = (await import("./index.vue")).default;

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    {
      path: "/hangar/imports/:id",
      name: "hangar-import",
      component: { template: "<div />" },
    },
  ],
});

const mount = () => mountWithDefaults(Component, { plugins: [router] });

const receipt = (name: string) =>
  `<2026-11-02T18:04:11.512Z> [Notice] <SHUDEvent_OnNotification> Added notification "Received Blueprint: ${name}: " [12] to queue.`;

const log = (environment: string, names: string[], fileName = "Game.log") =>
  new File(
    [
      [
        `Executable: C:\\StarCitizen\\${environment}\\Bin64\\StarCitizen.exe`,
        ...names.map(receipt),
      ].join("\n"),
    ],
    fileName,
  );

const option = (slug: string, attrs: { owned?: boolean } = {}) => ({
  slug,
  name: slug,
  owned: false,
  wanted: false,
  ...attrs,
});

const pick = async (
  wrapper: Awaited<ReturnType<typeof mount>>,
  files: File[],
) => {
  const input = wrapper.find("[data-test='blueprint-log-import-files-input']");

  Object.defineProperty(input.element, "files", {
    value: files,
    configurable: true,
  });
  await input.trigger("change");
  await flushPromises();
};

const read = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper
    .find("[data-test='blueprint-log-import-read']")
    .trigger("click");
  await flushPromises();
};

describe("BlueprintLogImportModal", () => {
  beforeEach(() => {
    matchBlueprintLogNames.mockReset();
    importBlueprintsFromLogs.mockReset();
    invalidateQueries.mockReset();
    displayAlert.mockReset();
  });

  it("matches the names from LIVE logs only and imports the new ones", async () => {
    matchBlueprintLogNames.mockResolvedValue([
      { name: "Aspis", blueprints: [option("aspis")] },
      { name: "Held", blueprints: [option("held", { owned: true })] },
      { name: "Helmet", blueprints: [option("helmet-a"), option("helmet-b")] },
      { name: "Nothing", blueprints: [] },
    ]);
    importBlueprintsFromLogs.mockResolvedValue({
      imported: 1,
      unchanged: 0,
      importId: "import-id",
    });

    const wrapper = await mount();

    await pick(wrapper, [
      log("LIVE", ["Aspis", "Held", "Helmet", "Nothing", "Aspis"]),
      log("PTU", ["Ptu Only"], "Game Build(1) 01 Nov 26.log"),
    ]);
    await read(wrapper);

    expect(matchBlueprintLogNames).toHaveBeenCalledWith({
      names: ["Aspis", "Held", "Helmet", "Nothing"],
    });
    expect(
      wrapper.find("[data-test='blueprint-log-import-fresh']").text(),
    ).toContain("aspis");
    expect(
      wrapper.find("[data-test='blueprint-log-import-ambiguous']").exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='blueprint-log-import-unmatched']").text(),
    ).toContain("Nothing");

    await wrapper
      .find("[data-test='blueprint-log-import-submit']")
      .trigger("click");
    await flushPromises();

    expect(importBlueprintsFromLogs).toHaveBeenCalledWith({
      slugs: ["aspis"],
      unmatchedNames: ["Nothing"],
    });
    expect(invalidateQueries).toHaveBeenCalledWith({
      queryKey: ["blueprints"],
    });
    expect(
      wrapper.find("[data-test='blueprint-log-import-done']").exists(),
    ).toBe(true);
  });

  it("lists the recognised logs before reading them", async () => {
    const wrapper = await mount();

    await pick(wrapper, [
      log("PTU", ["Ptu Only"], "Game Build(1) 01 Nov 26.log"),
      new File(["x"], "notes.txt"),
      log("LIVE", ["Aspis"]),
    ]);

    const files = wrapper.findAll("[data-test='blueprint-log-import-file']");

    expect(files.map((file) => file.text())).toEqual([
      expect.stringContaining("Game Build(1) 01 Nov 26.log"),
      expect.stringContaining("Game.log"),
    ]);
    expect(files[0].text()).toContain("PTU");
    expect(files[0].classes()).toContain("blueprint-log-import__file--skipped");
    expect(files[1].text()).toContain("LIVE");
    expect(matchBlueprintLogNames).not.toHaveBeenCalled();

    matchBlueprintLogNames.mockResolvedValue([]);
    await read(wrapper);

    expect(matchBlueprintLogNames).toHaveBeenCalledWith({ names: ["Aspis"] });
  });

  it("cannot read a pick of PTU logs only", async () => {
    const wrapper = await mount();

    await pick(wrapper, [log("PTU", ["Ptu Only"])]);

    expect(
      wrapper
        .find("[data-test='blueprint-log-import-read']")
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("refuses a pick without log files", async () => {
    const wrapper = await mount();

    await pick(wrapper, [new File(["x"], "notes.txt")]);

    expect(displayAlert).toHaveBeenCalled();
    expect(matchBlueprintLogNames).not.toHaveBeenCalled();
  });

  it("skips the match when the logs hold no receipts", async () => {
    const wrapper = await mount();

    await pick(wrapper, [log("LIVE", [])]);
    await read(wrapper);

    expect(matchBlueprintLogNames).not.toHaveBeenCalled();
    expect(
      wrapper.find("[data-test='blueprint-log-import-review']").exists(),
    ).toBe(true);
  });
});
