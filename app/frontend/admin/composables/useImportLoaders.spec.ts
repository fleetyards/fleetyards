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
});
