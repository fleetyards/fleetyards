import { computed, watch } from "vue";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { useImportsStore } from "@/admin/stores/imports";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Import,
  ImportStatusEnum,
  useImports,
} from "@/services/fyAdminApi";

const formatImportLabel = (importData: Import): string => {
  return importData.type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();
};

export const useImportUpdates = () => {
  const importsStore = useImportsStore();
  const { displayInfo, displaySuccess, displayAlert } = useAppNotifications();
  const { t } = useI18n();

  const handleImportUpdate = (data: string) => {
    const importData: Import = JSON.parse(data);

    const previousImport = importsStore.imports[importData.id];
    const previousStatus = previousImport?.status;

    importsStore.upsertImport(importData);

    if (importData.status === previousStatus) {
      return;
    }

    const label = formatImportLabel(importData);

    switch (importData.status) {
      case ImportStatusEnum.started:
        displayInfo({
          text: t("messages.import.started", { type: label }),
        });
        break;
      case ImportStatusEnum.finished:
        displaySuccess({
          text: t("messages.import.finished", { type: label }),
        });
        break;
      case ImportStatusEnum.failed:
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
    channelName: ChannelsEnum.IMPORTS,
    received: handleImportUpdate,
  });

  // Seed store with currently active imports on page load
  const activeImportsParams = computed(() => ({
    perPage: "50",
  }));

  const { data: existingImports } = useImports(activeImportsParams, {
    query: {
      staleTime: 30_000,
    },
  });

  watch(
    () => existingImports.value,
    (data) => {
      if (data?.items) {
        const active = data.items.filter(
          (imp) =>
            imp.status === ImportStatusEnum.created ||
            imp.status === ImportStatusEnum.started,
        );
        importsStore.seedImports(active);
      }
    },
    { immediate: true },
  );
};
