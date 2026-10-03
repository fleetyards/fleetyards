import { describe, expect, it, vi } from "vitest";
import { defineComponent } from "vue";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { useImportsStore } from "@/admin/stores/imports";
import {
  type Import,
  ImportLoaderEnum,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { IMPORT_LOADERS, LOAD_ALL, useImportLoaders } from "./useImportLoaders";

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyAdminApi")>()),
  useStartImportLoad: () => ({ mutateAsync: vi.fn(async () => ({})) }),
}));

const mountLoaders = async () => {
  let loaders!: ReturnType<typeof useImportLoaders>;

  const Host = defineComponent({
    setup() {
      loaders = useImportLoaders();
      return () => null;
    },
  });

  await mountWithDefaults(Host);

  return { loaders, store: useImportsStore() };
};

const paints = IMPORT_LOADERS.find((option) => option.id === "paints")!;

const paintsImport = (status: ImportStatusEnum) =>
  ({
    id: "paints-1",
    type: ImportTypeEnum.IMPORTS_PAINTS_IMPORT,
    status,
    createdAt: "2026-10-03T00:00:00Z",
    updatedAt: "2026-10-03T00:00:00Z",
  }) as Import;

const matrixImport = (id: string, status: ImportStatusEnum) =>
  ({
    id,
    type: ImportTypeEnum.IMPORTS_MODELS_IMPORT,
    status,
    createdAt: "2026-10-03T00:00:00Z",
    updatedAt: "2026-10-03T00:00:00Z",
  }) as Import;

describe("useImportLoaders", () => {
  // The API's list is the generated enum. A loader it gains has to land in a
  // modal, or it can be started by nobody.
  it("offers every loader the API knows", () => {
    const offered = new Set([
      ...IMPORT_LOADERS.map((option) => option.loader),
      ...Object.values(LOAD_ALL).map((option) => option!.loader),
    ]);

    expect([...offered].sort()).toEqual(Object.values(ImportLoaderEnum).sort());
  });

  it("keeps a second run waiting in the queue after the first one's timer", async () => {
    vi.useFakeTimers();
    const { loaders, store } = await mountLoaders();

    await loaders.start(paints);
    store.imports = { "paints-1": paintsImport(ImportStatusEnum.STARTED) };
    await flushPromises();
    store.imports = { "paints-1": paintsImport(ImportStatusEnum.FINISHED) };
    await flushPromises();

    await vi.advanceTimersByTimeAsync(20_000);
    await loaders.start(paints);

    await vi.advanceTimersByTimeAsync(45_000);

    expect(loaders.isRunning(paints)).toBe(true);

    vi.useRealTimers();
  });

  it("holds the follow-up rows until the load-all matrix run is done", async () => {
    vi.useFakeTimers();
    const { loaders, store } = await mountLoaders();
    const loadAll = LOAD_ALL.shipMatrix!;
    // Not paints: the test above leaves a paints request in the shared state.
    const modules = IMPORT_LOADERS.find((option) => option.id === "modules")!;
    const scDataModels = IMPORT_LOADERS.find(
      (option) => option.id === "sc_data_models",
    )!;

    await loaders.start(loadAll);

    expect(loaders.isRunning(modules)).toBe(true);
    expect(loaders.isRunning(scDataModels)).toBe(false);

    store.imports = {
      "models-1": matrixImport("models-1", ImportStatusEnum.STARTED),
    };
    await flushPromises();
    await vi.advanceTimersByTimeAsync(120_000);

    expect(loaders.isRunning(modules)).toBe(true);

    store.imports = {
      "models-1": matrixImport("models-1", ImportStatusEnum.FINISHED),
    };
    await flushPromises();

    expect(loaders.isRunning(modules)).toBe(false);

    vi.useRealTimers();
  });

  it("keeps the follow-up rows held when an earlier matrix run finishes", async () => {
    vi.useFakeTimers();
    const { loaders, store } = await mountLoaders();
    const loaners = IMPORT_LOADERS.find((option) => option.id === "loaners")!;

    store.imports = {
      "models-0": matrixImport("models-0", ImportStatusEnum.STARTED),
    };
    await flushPromises();

    await loaders.start(LOAD_ALL.shipMatrix!);

    store.imports = {
      "models-0": matrixImport("models-0", ImportStatusEnum.STARTED),
      "paints-1": paintsImport(ImportStatusEnum.STARTED),
    };
    await flushPromises();
    store.imports = {
      "models-0": matrixImport("models-0", ImportStatusEnum.FINISHED),
    };
    await flushPromises();

    expect(loaders.isRunning(loaners)).toBe(true);

    store.imports = {
      "models-2": matrixImport("models-2", ImportStatusEnum.STARTED),
    };
    await flushPromises();
    store.imports = {
      "models-2": matrixImport("models-2", ImportStatusEnum.FINISHED),
    };
    await flushPromises();

    expect(loaders.isRunning(loaners)).toBe(false);

    vi.useRealTimers();
  });

  it("holds the follow-up rows through a matrix run longer than the wait limit", async () => {
    vi.useFakeTimers();
    const { loaders, store } = await mountLoaders();
    const uexPrices = IMPORT_LOADERS.find(
      (option) => option.id === "uex_vehicle_prices",
    )!;

    await loaders.start(LOAD_ALL.shipMatrix!);

    store.imports = {
      "models-3": matrixImport("models-3", ImportStatusEnum.STARTED),
    };
    await flushPromises();
    await vi.advanceTimersByTimeAsync(45 * 60_000);

    expect(loaders.isRunning(uexPrices)).toBe(true);

    store.imports = {
      "models-3": matrixImport("models-3", ImportStatusEnum.FINISHED),
    };
    await flushPromises();

    expect(loaders.isRunning(uexPrices)).toBe(false);

    vi.useRealTimers();
  });
});
