<script lang="ts">
export default {
  name: "AdminModelEditHardpointsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type ModelHardpoint,
  type ModelHardpointInput,
  useListModelHardpoints as useListModelHardpointsQuery,
  useCreateModelHardpoint as useCreateModelHardpointMutation,
  useUpdateModelHardpoint as useUpdateModelHardpointMutation,
  useDestroyModelHardpoint as useDestroyModelHardpointMutation,
  getListModelHardpointsQueryKey,
  ModelHardpointGroupEnum,
  ModelHardpointTypeEnum,
  ModelHardpointSizeEnum,
  ModelHardpointCategoryEnum,
  ModelHardpointSubCategoryEnum,
  HardpointSourceEnum,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HardpointLoadouts from "@/admin/components/ModelHardpoints/Loadouts/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const expandedId = ref<string | null>(null);
const sourceFilter = ref<string>(HardpointSourceEnum.game_files);

const toggleExpand = (id: string) => {
  expandedId.value = expandedId.value === id ? null : id;
};

const hardpointsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
    sourceEq: sourceFilter.value,
  },
}));

const hardpointsQueryKey = computed(() =>
  getListModelHardpointsQueryKey(hardpointsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(hardpointsQueryKey);

const { data, isLoading } = useListModelHardpointsQuery(hardpointsQueryParams);

const invalidateHardpoints = async () => {
  await queryClient.invalidateQueries({
    queryKey: getListModelHardpointsQueryKey(),
  });
};

const toOptions = (enumObj: Record<string, string>): FilterOption[] =>
  Object.keys(enumObj).map((key) => ({
    label: key.replace(/_/g, " "),
    value: key,
  }));

const groupOptions = toOptions(ModelHardpointGroupEnum);
const typeOptions = toOptions(ModelHardpointTypeEnum);
const sizeOptions = toOptions(ModelHardpointSizeEnum);
const categoryOptions = toOptions(ModelHardpointCategoryEnum);
const subCategoryOptions = toOptions(ModelHardpointSubCategoryEnum);
const sourceOptions = toOptions(HardpointSourceEnum);

// Edit
const editForm = ref<ModelHardpointInput>({});

const onStartEdit = (record: ModelHardpoint) => {
  editForm.value = {
    name: record.name,
    source: record.source,
    key: record.key,
    hardpointType: record.type,
    group: record.group,
    category: record.category,
    subCategory: record.subCategory,
    size: record.size,
    details: record.details,
    mount: record.mount,
    itemSlots: record.itemSlots,
    loadoutIdentifier: record.loadoutIdentifier,
  };
};

const updateMutation = useUpdateModelHardpointMutation({
  mutation: {
    onSettled: invalidateHardpoints,
  },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyModelHardpointMutation({
  mutation: {
    onSettled: invalidateHardpoints,
  },
});

const onDestroy = async (record: ModelHardpoint) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelHardpointInput>({
  modelId: props.model.id,
  source: "game_files",
  group: "weapon",
  hardpointType: "weapons",
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
    source: "game_files",
    group: "weapon",
    hardpointType: "weapons",
  };
};

const createMutation = useCreateModelHardpointMutation({
  mutation: {
    onSettled: invalidateHardpoints,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};
</script>

<template>
  <div class="d-flex align-items-center justify-content-between">
    <Heading>{{ t("headlines.admin.models.edit.hardpoints") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fad fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>
  <div class="hardpoint-filters">
    <BtnGroup>
      <Btn
        v-for="option in sourceOptions"
        :key="String(option.value)"
        :size="BtnSizesEnum.SMALL"
        :active="sourceFilter === option.value"
        @click="sourceFilter = String(option.value)"
      >
        {{ option.label }}
      </Btn>
    </BtnGroup>
  </div>

  <InlineEditableList
    empty-name="Hardpoints"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelHardpoint[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelHardpoint.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <div class="hardpoint-display">
        <div class="hardpoint-display__main">
          <BasePill uppercase margin-right>{{ item.group }}</BasePill>
          <BasePill margin-right>{{ item.type }}</BasePill>
          <BasePill v-if="item.sizeLabel" margin-right>{{
            item.sizeLabel
          }}</BasePill>
          <span v-if="item.name" class="hardpoint-display__name">{{
            item.name
          }}</span>
          <span v-else class="hardpoint-display__name text-muted">{{
            item.key
          }}</span>
          <span
            v-if="item.component"
            class="hardpoint-display__component text-muted"
          >
            {{ item.component.name }}
            <template v-if="item.component.itemClass">
              · {{ item.component.itemClassLabel }} Grade
              {{ item.component.gradeLabel }}
            </template>
            <template v-if="item.component.size">
              · S{{ item.component.size }}
            </template>
          </span>
        </div>
        <div class="hardpoint-display__meta">
          <BasePill v-if="item.categoryLabel" margin-right>{{
            item.categoryLabel
          }}</BasePill>
          <BasePill v-if="item.subCategoryLabel" margin-right>{{
            item.subCategoryLabel
          }}</BasePill>
        </div>
      </div>
    </template>

    <template #actions="{ item }">
      <Btn
        v-if="item.loadouts?.length"
        v-tooltip="'Loadouts'"
        :size="BtnSizesEnum.SMALL"
        @click.stop="toggleExpand(item.id)"
      >
        <i
          class="fad fa-layer-group"
          :class="expandedId === item.id ? 'text-primary' : ''"
        />
      </Btn>
    </template>

    <template #edit>
      <div class="hardpoint-form">
        <div class="hardpoint-form__row">
          <FormInput
            v-model="editForm.name"
            name="edit-name"
            translation-key="modelHardpoint.name"
          />
          <FormInput
            v-model="editForm.key"
            name="edit-key"
            translation-key="modelHardpoint.key"
          />
        </div>
        <div class="hardpoint-form__row">
          <FilterGroup
            v-model="editForm.source"
            name="edit-source"
            :options="sourceOptions"
            :nullable="false"
            translation-key="modelHardpoint.source"
          />
          <FilterGroup
            v-model="editForm.group"
            name="edit-group"
            :options="groupOptions"
            :nullable="false"
            translation-key="modelHardpoint.group"
          />
          <FilterGroup
            v-model="editForm.hardpointType"
            name="edit-type"
            :options="typeOptions"
            :nullable="false"
            translation-key="modelHardpoint.hardpointType"
          />
        </div>
        <div class="hardpoint-form__row">
          <FilterGroup
            v-model="editForm.size"
            name="edit-size"
            :options="sizeOptions"
            translation-key="modelHardpoint.size"
          />
          <FilterGroup
            v-model="editForm.category"
            name="edit-category"
            :options="categoryOptions"
            translation-key="modelHardpoint.category"
          />
          <FilterGroup
            v-model="editForm.subCategory"
            name="edit-sub-category"
            :options="subCategoryOptions"
            translation-key="modelHardpoint.subCategory"
          />
        </div>
        <div class="hardpoint-form__row">
          <FormInput
            v-model="editForm.details"
            name="edit-details"
            translation-key="modelHardpoint.details"
          />
          <FormInput
            v-model="editForm.mount"
            name="edit-mount"
            translation-key="modelHardpoint.mount"
          />
          <FormInput
            v-model.number="editForm.itemSlots"
            name="edit-item-slots"
            translation-key="modelHardpoint.itemSlots"
            type="number"
          />
          <FormInput
            v-model="editForm.loadoutIdentifier"
            name="edit-loadout-identifier"
            translation-key="modelHardpoint.loadoutIdentifier"
          />
        </div>
      </div>
    </template>

    <template #create>
      <div class="hardpoint-form">
        <div class="hardpoint-form__row">
          <FormInput
            v-model="createForm.name"
            name="create-name"
            translation-key="modelHardpoint.name"
          />
          <FormInput
            v-model="createForm.key"
            name="create-key"
            translation-key="modelHardpoint.key"
          />
        </div>
        <div class="hardpoint-form__row">
          <FilterGroup
            v-model="createForm.source"
            name="create-source"
            :options="sourceOptions"
            :nullable="false"
            translation-key="modelHardpoint.source"
          />
          <FilterGroup
            v-model="createForm.group"
            name="create-group"
            :options="groupOptions"
            :nullable="false"
            translation-key="modelHardpoint.group"
          />
          <FilterGroup
            v-model="createForm.hardpointType"
            name="create-type"
            :options="typeOptions"
            :nullable="false"
            translation-key="modelHardpoint.hardpointType"
          />
        </div>
        <div class="hardpoint-form__row">
          <FilterGroup
            v-model="createForm.size"
            name="create-size"
            :options="sizeOptions"
            translation-key="modelHardpoint.size"
          />
          <FilterGroup
            v-model="createForm.category"
            name="create-category"
            :options="categoryOptions"
            translation-key="modelHardpoint.category"
          />
          <FilterGroup
            v-model="createForm.subCategory"
            name="create-sub-category"
            :options="subCategoryOptions"
            translation-key="modelHardpoint.subCategory"
          />
        </div>
        <div class="hardpoint-form__row">
          <FormInput
            v-model="createForm.details"
            name="create-details"
            translation-key="modelHardpoint.details"
          />
          <FormInput
            v-model="createForm.mount"
            name="create-mount"
            translation-key="modelHardpoint.mount"
          />
          <FormInput
            v-model.number="createForm.itemSlots"
            name="create-item-slots"
            translation-key="modelHardpoint.itemSlots"
            type="number"
          />
          <FormInput
            v-model="createForm.loadoutIdentifier"
            name="create-loadout-identifier"
            translation-key="modelHardpoint.loadoutIdentifier"
          />
        </div>
      </div>
    </template>
    <template #expanded="{ item }">
      <HardpointLoadouts
        v-if="expandedId === item.id"
        :hardpoint="item as ModelHardpoint"
      />
    </template>
  </InlineEditableList>

  <Paginator
    v-if="data"
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>

<style lang="scss" scoped>
.hardpoint-filters {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.hardpoint-display {
  display: flex;
  flex-direction: column;
  gap: 4px;

  &__main {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 4px;
  }

  &__meta {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 4px;
  }

  &__name {
    font-weight: 500;
  }

  &__component {
    font-size: 0.85em;
  }
}

.hardpoint-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;

  &__row {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;

    > * {
      flex: 1;
      min-width: 150px;
    }
  }
}
</style>
