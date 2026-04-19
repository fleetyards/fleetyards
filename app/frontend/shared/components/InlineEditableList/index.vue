<script lang="ts">
export default {
  name: "InlineEditableList",
};
</script>

<script lang="ts" setup generic="T extends { id: string }">
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Collapsed from "@/shared/components/Collapsed.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { uniq as uniqArray } from "@/shared/utils/Array";

type Props = {
  items: T[];
  loading?: boolean;
  confirmDestroyText?: string;
  emptyName?: string;
  hideDestroy?: boolean;
  hideEdit?: boolean;
  selectable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  confirmDestroyText: undefined,
  emptyName: "entries",
  hideDestroy: false,
  hideEdit: false,
  selectable: false,
});

const { displayConfirm } = useAppNotifications();

const mobile = useMobile();
const { t } = useI18n();

const emit = defineEmits<{
  "start-edit": [item: T];
  "save-edit": [];
  "start-create": [];
  "save-create": [];
  destroy: [item: T];
}>();

const editingId = ref<string | null>(null);
const creating = ref(false);

const internalSelected = ref<string[]>([]);

const allSelected = computed(() => {
  if (!props.items.length) {
    return false;
  }

  return props.items
    .map((item) => item.id)
    .every((id) => internalSelected.value.includes(id));
});

const partialSelected = computed(() => {
  return internalSelected.value.length > 0 && !allSelected.value;
});

const onAllSelectedChange = (value?: boolean) => {
  if (value) {
    internalSelected.value = [
      ...internalSelected.value,
      ...props.items.map((item) => item.id),
    ].filter(uniqArray);
  } else {
    const currentIds = props.items.map((item) => item.id);
    internalSelected.value = internalSelected.value.filter(
      (id) => !currentIds.includes(id),
    );
  }
};

const resetSelected = () => {
  internalSelected.value = [];
};

const startEdit = (item: T) => {
  editingId.value = item.id;
  emit("start-edit", item);
};

const cancelEdit = () => {
  editingId.value = null;
};

const saveEdit = () => {
  emit("save-edit");
};

const startCreate = () => {
  creating.value = true;
  emit("start-create");
};

const cancelCreate = () => {
  creating.value = false;
};

const saveCreate = () => {
  emit("save-create");
};

const destroy = (item: T) => {
  const onConfirm = () => {
    emit("destroy", item);
  };

  if (props.confirmDestroyText) {
    displayConfirm({
      text: props.confirmDestroyText,
      onConfirm,
    });
  } else {
    onConfirm();
  }
};

const finishEdit = () => {
  editingId.value = null;
};

const finishCreate = () => {
  creating.value = false;
};

defineExpose({
  editingId,
  creating,
  selected: internalSelected,
  startCreate,
  finishEdit,
  finishCreate,
  resetSelected,
});
</script>

<template>
  <div
    v-if="props.selectable && items.length"
    class="inline-editable-list__toolbar"
  >
    <div class="inline-editable-list__toolbar-left">
      <FormCheckbox
        :model-value="allSelected"
        name="select-all"
        no-label
        inline
        :partial="partialSelected"
        @update:model-value="onAllSelectedChange"
      />
      <Collapsed
        :visible="!!internalSelected.length"
        as="span"
        class="inline-editable-list__toolbar-info"
      >
        <span>
          {{
            t("filteredTable.labels.selected", {
              count: internalSelected.length,
            })
          }}
        </span>
        <Btn
          v-tooltip="t('filteredTable.actions.unselect')"
          :size="BtnSizesEnum.SMALL"
          :variant="BtnVariantsEnum.LINK"
          inline
          @click="resetSelected"
        >
          <i class="fa fa-times" />
        </Btn>
      </Collapsed>
    </div>
    <Collapsed
      :visible="!!internalSelected.length"
      class="inline-editable-list__actions"
    >
      <slot name="selected-actions" :selected="internalSelected" />
    </Collapsed>
  </div>

  <ListGroup
    :items="items"
    :loading="loading"
    :empty-name="emptyName"
    :hide-empty="creating"
  >
    <template #prepend>
      <div v-if="creating" key="__create__" class="list-group__item">
        <div class="list-group__row">
          <div class="inline-editable-list__form">
            <slot name="create" />
          </div>
          <div class="list-group__actions">
            <BtnGroup inline>
              <Btn
                :size="BtnSizesEnum.SMALL"
                data-test="save-create"
                @click="saveCreate"
              >
                <i class="fa-duotone fa-check" />
              </Btn>
              <Btn
                :size="BtnSizesEnum.SMALL"
                data-test="cancel-create"
                @click="cancelCreate"
              >
                <i class="fa-duotone fa-times" />
              </Btn>
            </BtnGroup>
          </div>
        </div>
      </div>
    </template>

    <template #display="{ item }">
      <FormCheckbox
        v-if="props.selectable"
        v-model="internalSelected"
        name="item"
        no-label
        inline
        :checkbox-value="item.id"
        class="inline-editable-list__checkbox"
      />
      <template v-if="editingId === item.id">
        <div class="inline-editable-list__form">
          <slot name="edit" :item="item" />
        </div>
      </template>
      <template v-else>
        <slot name="display" :item="item" />
      </template>
    </template>

    <template #actions="{ item }">
      <template v-if="editingId === item.id">
        <BtnGroup inline>
          <Btn
            :size="BtnSizesEnum.SMALL"
            data-test="save-edit"
            @click="saveEdit"
          >
            <i class="fa-duotone fa-check" />
          </Btn>
          <Btn
            :size="BtnSizesEnum.SMALL"
            data-test="cancel-edit"
            @click="cancelEdit"
          >
            <i class="fa-duotone fa-times" />
          </Btn>
        </BtnGroup>
      </template>
      <template v-else>
        <slot
          v-if="hideEdit && hideDestroy"
          name="actions"
          :item="item"
          :mobile="mobile"
        />
        <BtnDropdown v-else-if="mobile" :size="BtnSizesEnum.SMALL" inline>
          <slot name="actions" :item="item" :mobile="mobile" />
          <Btn
            v-if="!hideEdit"
            :size="BtnSizesEnum.SMALL"
            data-test="start-edit"
            @click="startEdit(item)"
          >
            <i class="fa-duotone fa-pencil" />
            <span>{{ t("actions.edit") }}</span>
          </Btn>
          <Btn
            v-if="!hideDestroy"
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.DANGER"
            data-test="destroy"
            @click="destroy(item)"
          >
            <i class="fa-duotone fa-trash" />
            <span>{{ t("actions.delete") }}</span>
          </Btn>
        </BtnDropdown>
        <BtnGroup v-else inline>
          <slot name="actions" :item="item" :mobile="false" />
          <Btn
            v-if="!hideEdit"
            :size="BtnSizesEnum.SMALL"
            data-test="start-edit"
            @click="startEdit(item)"
          >
            <i class="fa-duotone fa-pencil" />
          </Btn>
          <Btn
            v-if="!hideDestroy"
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.DANGER"
            data-test="destroy"
            @click="destroy(item)"
          >
            <i class="fa-duotone fa-trash" />
          </Btn>
        </BtnGroup>
      </template>
    </template>

    <template #expanded="{ item }">
      <slot name="expanded" :item="item" />
    </template>
  </ListGroup>
</template>

<style lang="scss" scoped>
.inline-editable-list__form {
  display: flex;
  gap: 8px;
  flex: 1;

  & > * {
    flex: 1;
  }
}

.inline-editable-list__toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 8px 12px;
  width: 100%;
  min-height: 68px;
}

.inline-editable-list__toolbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  color: $primary;
  white-space: nowrap;
  font-size: 120%;

  :deep(.panel-btn-inner) {
    color: $primary;
  }
}

.inline-editable-list__toolbar-info {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.inline-editable-list__actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: flex-end;

  :deep(.panel-btn),
  :deep(.panel-btn-group) {
    margin-bottom: 0;
    margin-right: 0;
  }
}

.inline-editable-list__checkbox {
  flex-shrink: 0;
}
</style>
