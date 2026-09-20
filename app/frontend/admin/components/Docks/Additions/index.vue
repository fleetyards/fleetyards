<script lang="ts">
export default {
  name: "AdminDocksAdditions",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ModelSelect from "@/admin/components/base/ModelSelect/index.vue";
import {
  type DockAddition,
  useDockAdditions as useDockAdditionsQuery,
  useCreateDockAddition as useCreateDockAdditionMutation,
  useDestroyDockAddition as useDestroyDockAdditionMutation,
  getDockAdditionsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

interface Props {
  dockId: string;
}

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

const queryParams = computed(() => ({ q: { dockIdEq: props.dockId } }));

const { data, isLoading } = useDockAdditionsQuery(queryParams);

const invalidate = () =>
  queryClient.invalidateQueries({ queryKey: getDockAdditionsQueryKey() });

const selectedModelId = ref<string | undefined>(undefined);

const createMutation = useCreateDockAdditionMutation({
  mutation: { onSettled: invalidate },
});

// The select carries the id rather than the slug, since that is what the berth
// stores -- a slug moves when a ship is renamed.
const onAdd = async () => {
  if (!selectedModelId.value) return;

  try {
    await createMutation.mutateAsync({
      data: { dockId: props.dockId, modelId: selectedModelId.value },
    });
  } catch {
    displayAlert({ text: t("messages.dockAddition.create.failure") });
    return;
  }

  selectedModelId.value = undefined;
};

const destroyMutation = useDestroyDockAdditionMutation({
  mutation: { onSettled: invalidate },
});

const onDestroy = async (addition: DockAddition) => {
  try {
    await destroyMutation.mutateAsync({ id: addition.id });
  } catch {
    displayAlert({ text: t("messages.dockAddition.destroy.failure") });
  }
};
</script>

<template>
  <div class="dock-additions">
    <span class="dock-additions__hint">
      {{ t("labels.dockAddition.hint") }}
    </span>

    <div class="dock-additions__add">
      <ModelSelect
        v-model="selectedModelId"
        name="dock-addition-model"
        value-attr="id"
        :label="t('labels.dockAddition.model')"
        :no-label="false"
      />
      <Btn :disabled="!selectedModelId" @click="onAdd">
        <i class="fa-duotone fa-plus" />
        {{ t("actions.add") }}
      </Btn>
    </div>

    <ListGroup
      :items="(data?.items as DockAddition[]) || []"
      :loading="isLoading"
      :empty-name="t('labels.dockAddition.empty')"
    >
      <template #display="{ item }">
        {{ item.modelName }}
      </template>

      <template #actions="{ item }">
        <Btn
          :title="t('actions.delete')"
          @click="onDestroy(item as DockAddition)"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </template>
    </ListGroup>
  </div>
</template>

<style lang="scss" scoped>
.dock-additions {
  // Sits under the capacity entries in the same expanded row, indented with
  // them rather than framed apart.
  padding: 8px 0 8px 16px;
}

.dock-additions__hint {
  color: var(--color-text-dim);
  font-size: 0.875rem;
}

.dock-additions__add {
  display: flex;
  align-items: flex-end;
  gap: 8px;
  margin: 8px 0;
}
</style>
