import { describe, expect, it } from "vitest";
import { QueryClient } from "@tanstack/vue-query";
import {
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
  getModelQueryKey,
  getModelsQueryKey,
} from "@/services/fyAdminApi";
import { isProgressReport, refreshImportedRecords } from "./useImportUpdates";

const MODEL_ID = "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c";

const anImport = (type: ImportTypeEnum, status: ImportStatusEnum) =>
  ({
    id: "import-1",
    type,
    status,
    createdAt: "2026-11-21T00:00:00Z",
    updatedAt: "2026-11-21T00:00:00Z",
  }) as Import;

const seeded = () => {
  const queryClient = new QueryClient();

  queryClient.setQueryData(getModelQueryKey(MODEL_ID), { id: MODEL_ID });
  queryClient.setQueryData(getModelsQueryKey({ page: "1" }), { items: [] });

  const isStale = (key: readonly unknown[]) =>
    queryClient.getQueryState(key)?.isInvalidated;

  return { queryClient, isStale };
};

describe("refreshImportedRecords", () => {
  it("refetches the model once a single ship matrix reload finishes", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_MODEL_IMPORT, ImportStatusEnum.FINISHED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(true);
    expect(isStale(getModelsQueryKey({ page: "1" }))).toBe(true);
  });

  it("refetches models after an sc data reload", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(
        ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT,
        ImportStatusEnum.FINISHED,
      ),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(true);
  });

  it("waits until the run has finished", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_MODEL_IMPORT, ImportStatusEnum.STARTED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(false);
  });

  it("leaves models alone for unrelated imports", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_PAINTS_IMPORT, ImportStatusEnum.FINISHED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(false);
  });
});

describe("isProgressReport", () => {
  const progress = {
    step: "items",
    stepNumber: 3,
    steps: 11,
    done: 1,
    progressedAt: "2026-11-25T10:00:00Z",
  } as const;

  const run = (status: ImportStatusEnum) =>
    anImport(ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT, status);

  it("tells a run under way from one that just started", () => {
    expect(isProgressReport(run(ImportStatusEnum.STARTED))).toBe(false);
    expect(
      isProgressReport({ ...run(ImportStatusEnum.STARTED), progress }),
    ).toBe(true);
  });

  it("leaves the end of a run to be announced", () => {
    expect(
      isProgressReport({ ...run(ImportStatusEnum.FINISHED), progress }),
    ).toBe(false);
  });
});
