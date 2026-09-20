<script lang="ts">
export default {
  name: "AdminDocksCapacities",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
// Registered globally as `Select`, so `<BaseSelect>` resolves to nothing
// without this and the dropdowns render as empty comments.
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import {
  type DockCapacity,
  type DockCapacityInput,
  type FilterOption,
  useDockCapacities as useDockCapacitiesQuery,
  useCreateDockCapacity as useCreateDockCapacityMutation,
  useUpdateDockCapacity as useUpdateDockCapacityMutation,
  useDestroyDockCapacity as useDestroyDockCapacityMutation,
  getDockCapacitiesQueryKey,
  getDocksQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";

interface Props {
  dockId: string;
}

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const queryParams = computed(() => ({ q: { dockIdEq: props.dockId } }));

const { data, isLoading } = useDockCapacitiesQuery(queryParams);

// The dock's own payload carries its entries, so the row above has to be
// refetched too or it keeps showing the pills it was rendered with.
const invalidate = async () => {
  await queryClient.invalidateQueries({
    queryKey: getDockCapacitiesQueryKey(),
  });
  await queryClient.invalidateQueries({ queryKey: getDocksQueryKey() });
};

// Ladders, so the order is the point: alphabetical would put Capital first.
const SHIP_CLASSES = [
  "extra_extra_small",
  "extra_small",
  "small",
  "medium",
  "large",
  "extra_large",
  "capital",
];

const VEHICLE_CLASSES = [
  "extra_extra_small",
  "extra_small",
  "small",
  "medium",
  "large",
  "extra_large",
  "extra_extra_large",
];

const ladderOptions = computed<FilterOption[]>(() =>
  ["ship", "vehicle"].map((value) => ({
    label: t(`labels.dockCapacityLadders.${value}`),
    value,
  })),
);

// The two ladders share wording and not membership: `capital` is a pad class,
// `extra_extra_large` a vehicle one, and the API refuses each on the other.
const classOptionsFor = (ladder?: string | null): FilterOption[] =>
  (ladder === "vehicle" ? VEHICLE_CLASSES : SHIP_CLASSES).map((value) => ({
    label:
      ladder === "vehicle"
        ? t(`labels.vehicleSizes.${value}`)
        : t(`labels.shipSizes.${value}`),
    value,
  }));

const editForm = ref<DockCapacityInput>({});
const createForm = ref<DockCapacityInput>({});

const editClassOptions = computed(() => classOptionsFor(editForm.value.ladder));
const createClassOptions = computed(() =>
  classOptionsFor(createForm.value.ladder),
);

// BaseSelect keeps its value when the options change, so switching ladders
// would leave `capital` selected on the vehicle side and the save would come
// back 400. The class falls back to the nearest thing the new ladder has.
const classOnLadder = (
  ladder: string | null | undefined,
  size?: string | null,
): string => {
  const options = classOptionsFor(ladder);
  const kept = options.find((option) => option.value === size);

  return String(kept?.value ?? options[0]?.value ?? "");
};

watch(
  () => editForm.value.ladder,
  (ladder) => {
    editForm.value.size = classOnLadder(ladder, editForm.value.size);
  },
);

watch(
  () => createForm.value.ladder,
  (ladder) => {
    createForm.value.size = classOnLadder(ladder, createForm.value.size);
  },
);

const onStartEdit = (record: DockCapacity) => {
  editForm.value = {
    ladder: record.ladder,
    size: record.size,
    quantity: record.quantity,
    display: record.display,
  };
};

const updateMutation = useUpdateDockCapacityMutation({
  mutation: { onSettled: invalidate },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  try {
    await updateMutation.mutateAsync({ id, data: editForm.value });
  } catch {
    displayAlert({ text: t("messages.dockCapacity.update.failure") });
    return;
  }

  editableList.value?.finishEdit();
};

const destroyMutation = useDestroyDockCapacityMutation({
  mutation: { onSettled: invalidate },
});

const onDestroy = async (record: DockCapacity) => {
  try {
    await destroyMutation.mutateAsync({ id: record.id });
  } catch {
    displayAlert({ text: t("messages.dockCapacity.destroy.failure") });
  }
};

const onStartCreate = () => {
  createForm.value = {
    dockId: props.dockId,
    ladder: "ship",
    size: "small",
    quantity: 1,
    display: false,
  };
};

const createMutation = useCreateDockCapacityMutation({
  mutation: { onSettled: invalidate },
});

const onSaveCreate = async () => {
  try {
    await createMutation.mutateAsync({ data: createForm.value });
  } catch {
    displayAlert({ text: t("messages.dockCapacity.create.failure") });
    return;
  }

  editableList.value?.finishCreate();
};
</script>

<template>
  <div class="dock-capacities">
    <div class="flex items-center justify-between mb-4">
      <span class="dock-capacities__hint">
        {{ t("labels.dockCapacity.hint") }}
      </span>
      <Btn
        :disabled="editableList?.creating"
        @click="editableList?.startCreate()"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.add") }}
      </Btn>
    </div>

    <InlineEditableList
      ref="editableList"
      :loading="isLoading"
      :empty-name="t('labels.dockCapacity.empty')"
      :items="(data?.items as DockCapacity[]) || []"
      :confirm-destroy-text="t('messages.confirm.dockCapacity.destroy')"
      @start-edit="onStartEdit"
      @save-edit="onSaveEdit"
      @start-create="onStartCreate"
      @save-create="onSaveCreate"
      @destroy="onDestroy"
    >
      <template #display="{ item }">
        <BasePill margin-right>
          {{ item.quantity }} × {{ item.sizeLabel }}
        </BasePill>
        <BasePill uppercase margin-right>
          {{ t(`labels.dockCapacityLadders.${item.ladder}`) }}
        </BasePill>
        <!-- The entry the berth's label is rendered from. At most one. -->
        <BasePill v-if="item.display">
          {{ t("labels.dockCapacity.display") }}
        </BasePill>
      </template>

      <template #edit>
        <BaseSelect
          v-model="editForm.ladder"
          name="edit-ladder"
          :options="ladderOptions"
          unsorted
          :label="t('labels.dockCapacity.ladder')"
        />
        <BaseSelect
          v-model="editForm.size"
          name="edit-size"
          :options="editClassOptions"
          unsorted
          :label="t('labels.dockCapacity.size')"
        />
        <FormInput
          v-model="editForm.quantity"
          :type="InputTypesEnum.NUMBER"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="edit-quantity"
          translation-key="dockCapacity.quantity"
        />
        <FormToggle
          v-model="editForm.display"
          name="edit-display"
          translation-key="dockCapacity.display"
          no-placeholder
        />
      </template>

      <template #create>
        <BaseSelect
          v-model="createForm.ladder"
          name="create-ladder"
          :options="ladderOptions"
          unsorted
          :label="t('labels.dockCapacity.ladder')"
        />
        <BaseSelect
          v-model="createForm.size"
          name="create-size"
          :options="createClassOptions"
          unsorted
          :label="t('labels.dockCapacity.size')"
        />
        <FormInput
          v-model="createForm.quantity"
          :type="InputTypesEnum.NUMBER"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="create-quantity"
          translation-key="dockCapacity.quantity"
        />
        <FormToggle
          v-model="createForm.display"
          name="create-display"
          translation-key="dockCapacity.display"
          no-placeholder
        />
      </template>
    </InlineEditableList>
  </div>
</template>

<style lang="scss" scoped>
.dock-capacities {
  // Indented from the dock it belongs to, so the nesting reads without a frame
  // of its own.
  padding: 8px 0 8px 16px;
}

.dock-capacities__hint {
  color: var(--color-text-dim);
  font-size: 0.875rem;
}
</style>
