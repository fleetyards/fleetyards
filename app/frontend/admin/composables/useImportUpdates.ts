import { computed, watch, type Ref } from "vue";
import { type QueryClient, useQueryClient } from "@tanstack/vue-query";
import { useSubscription } from "@/shared/composables/useSubscription";
import {
  ImportsChannel,
  type ImportsData,
} from "@/services/fyCableAdmin/channels/ImportsChannel";
import { useImportsStore } from "@/admin/stores/imports";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
  getModelsQueryKey,
  useImports,
} from "@/services/fyAdminApi";

// A reload is queued, not run, so the page that started it has already
// refetched by the time the job writes anything.
const MODEL_IMPORT_TYPES: string[] = [
  ImportTypeEnum.IMPORTS_MODEL_IMPORT,
  ImportTypeEnum.IMPORTS_MODELS_IMPORT,
  ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT,
  ImportTypeEnum.IMPORTS_SC_DATA_MODELS_IMPORT,
];

export const refreshImportedRecords = (
  queryClient: QueryClient,
  importData: Import,
) => {
  if (importData.status !== ImportStatusEnum.FINISHED) return;

  if (MODEL_IMPORT_TYPES.includes(importData.type)) {
    void queryClient.invalidateQueries({ queryKey: getModelsQueryKey() });
  }
};

const formatImportLabel = (importData: Import): string => {
  return importData.type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();
};

export const useImportUpdates = (enabled: Ref<boolean>) => {
  const importsStore = useImportsStore();
  const { displayInfo, displaySuccess, displayAlert } = useAppNotifications();
  const { t } = useI18n();
  const queryClient = useQueryClient();

  const handleImportUpdate = (importData: ImportsData) => {
    const previousImport = importsStore.imports[importData.id];
    const previousStatus = previousImport?.status;

    importsStore.upsertImport(importData);

    if (importData.status === previousStatus) {
      return;
    }

    void queryClient.invalidateQueries({ queryKey: ["imports"] });
    refreshImportedRecords(queryClient, importData);

    const label = formatImportLabel(importData);

    switch (importData.status) {
      case ImportStatusEnum.STARTED:
        displayInfo({
          text: t("messages.import.started", { type: label }),
        });
        break;
      case ImportStatusEnum.FINISHED:
        displaySuccess({
          text: t("messages.import.finished", { type: label }),
        });
        break;
      case ImportStatusEnum.FAILED:
        displayAlert({
          text: t("messages.import.failed", {
            type: label,
            info: importData.info || "",
          }),
        });
        break;
    }
  };

  useSubscription({
    channel: ImportsChannel,
    received: handleImportUpdate,
  });

  // Seed store with currently active imports on page load
  const activeImportsParams = computed(() => ({
    perPage: "50",
  }));

  const { data: existingImports } = useImports(activeImportsParams, {
    query: {
      enabled,
      staleTime: 30_000,
    },
  });

  watch(
    () => existingImports.value,
    (data) => {
      if (data?.items) {
        const active = data.items.filter(
          (imp) =>
            imp.status === ImportStatusEnum.CREATED ||
            imp.status === ImportStatusEnum.STARTED,
        );
        importsStore.seedImports(active);
      }
    },
    { immediate: true },
  );
};
