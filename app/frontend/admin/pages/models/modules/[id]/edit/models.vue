<script lang="ts">
export default {
  name: "AdminModelModuleEditModelsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelModule,
  type Model,
  useLinkModelModule as useLinkModelModuleMutation,
  useUnlinkModelModule as useUnlinkModelModuleMutation,
  getListModelModulesQueryKey,
  getModelModuleQueryKey,
} from "@/services/fyAdminApi";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useQueryClient } from "@tanstack/vue-query";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();
const { displayConfirm } = useAppNotifications();

const editableList = ref<{
  creating: boolean;
  startCreate: () => void;
  finishCreate: () => void;
} | null>(null);

const invalidateModule = () =>
  void Promise.all([
    queryClient.invalidateQueries({
      queryKey: getListModelModulesQueryKey(),
    }),
    queryClient.invalidateQueries({
      queryKey: getModelModuleQueryKey(props.modelModule.id),
    }),
  ]);

const linkMutation = useLinkModelModuleMutation({
  mutation: { onSettled: invalidateModule },
});

const unlinkMutation = useUnlinkModelModuleMutation({
  mutation: { onSettled: invalidateModule },
});

const linkModelId = ref<string | undefined>(undefined);

const onStartCreate = () => {
  linkModelId.value = undefined;
};

const onSaveCreate = async () => {
  if (!linkModelId.value) return;

  await linkMutation.mutateAsync({
    id: props.modelModule.id,
    data: { modelId: linkModelId.value },
  });

  editableList.value?.finishCreate();
};

const onUnlinkModel = (item: Model) => {
  displayConfirm({
    text: t("messages.confirm.modelModule.unlink"),
    onConfirm: async () => {
      await unlinkMutation.mutateAsync({
        id: props.modelModule.id,
        data: { modelId: item.id },
      });
    },
  });
};
</script>

<template>
  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.modelModules.models") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    ref="editableList"
    empty-name="Models"
    :items="(modelModule.models as Model[]) || []"
    hide-edit
    hide-destroy
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
  >
    <template #create>
      <ModelFilterGroup
        v-model="linkModelId"
        :no-label="false"
        value-attr="id"
        :multiple="false"
        name="linkModel"
      />
    </template>

    <template #display="{ item }">
      <router-link :to="{ name: 'admin-model-edit', params: { id: item.id } }">
        {{ item.name }}
      </router-link>
    </template>

    <template #actions="{ item, mobile }">
      <BtnGroup inline>
        <Btn
          v-tooltip="t('actions.unlink')"
          :size="BtnSizesEnum.SMALL"
          :variant="BtnVariantsEnum.TRANSPARENT"
          @click="onUnlinkModel(item)"
        >
          <i class="fa-duotone fa-unlink text-muted" />
          <span v-if="mobile">{{ t("actions.unlink") }}</span>
        </Btn>
      </BtnGroup>
    </template>
  </InlineEditableList>
</template>
