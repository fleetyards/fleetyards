<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ModelExtended,
  useReloadOneModelMatrix,
  useReloadOneModelScData,
  getModelsQueryKey,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "./edit/routes";
import { useModelsStore } from "@/admin/stores/models";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { useImportLoading } from "@/admin/composables/useImportLoading";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();
const queryClient = useQueryClient();

const mobile = useMobile();

const crumbs = [
  {
    to: { name: "admin-models", hash: `#${props.model.id}` },
    label: t("nav.admin.models.index"),
  },
  {
    to: { name: "admin-model-edit", params: { id: props.model.id } },
    label: props.model.name,
  },
];

const modelsStore = useModelsStore();

const matrixInputMatch = computed(() => ({
  modelId: props.model.id,
  rsiId: props.model.rsiId,
}));

const scDataInputMatch = computed(() => ({
  modelId: props.model.id,
}));

const { isImporting: isImportingMatrix } = useImportLoading(
  [ImportTypeEnum.IMPORTS_MODEL_IMPORT],
  matrixInputMatch,
);

const { isImporting: isImportingScData } = useImportLoading(
  [ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT],
  scDataInputMatch,
);

const invalidateModels = () =>
  queryClient.invalidateQueries({
    queryKey: getModelsQueryKey(),
  });

const reloadMatrixMutation = useReloadOneModelMatrix({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncMatrixStarted"),
      });
    },
    onSettled: invalidateModels,
  },
});

const reloadScDataMutation = useReloadOneModelScData({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncScDataStarted"),
      });
    },
    onSettled: invalidateModels,
  },
});

const isSyncingMatrix = computed(
  () => isImportingMatrix.value || reloadMatrixMutation.isPending.value,
);

const isSyncingScData = computed(
  () => isImportingScData.value || reloadScDataMutation.isPending.value,
);

const syncMatrix = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.syncMatrix"),
    onConfirm: async () => {
      await reloadMatrixMutation.mutateAsync({ id: props.model.id! });
    },
  });
};

const syncScData = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.syncScData"),
    onConfirm: async () => {
      await reloadScDataMutation.mutateAsync({ id: props.model.id! });
    },
  });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="crumbs"
    :stepper-list="modelsStore.list"
    :stepper-list-meta="modelsStore.listMeta"
    :current-id="model.id"
  >
    <template #actions v-if="!mobile">
      <Btn
        v-tooltip="t('actions.models.syncMatrix')"
        :size="BtnSizesEnum.SMALL"
        :loading="isSyncingMatrix"
        inline
        spinner
        @click="syncMatrix"
      >
        <i class="fa-duotone fa-rotate" />
        {{ t("actions.models.syncMatrix") }}
      </Btn>
      <Btn
        v-tooltip="t('actions.models.syncScData')"
        :size="BtnSizesEnum.SMALL"
        :loading="isSyncingScData"
        inline
        spinner
        @click="syncScData"
      >
        <i class="fa-duotone fa-database" />
        {{ t("actions.models.syncScData") }}
      </Btn>
    </template>
  </BreadCrumbs>

  <TabNavView>
    <template #nav>
      <TabNavViewItems :routes="editRoutes" :authenticated="true" />
    </template>
    <template #content>
      <router-view :model="model" />
    </template>
  </TabNavView>
</template>
