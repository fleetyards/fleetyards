<script lang="ts">
export default {
  name: "InlineEditableList",
};
</script>

<script lang="ts" setup generic="T extends { id: string }">
import {
  BtnVariantsEnum,
  BtnTonesEnum,
} from "@/shared/components/base/Btn/types";
import Collapsed from "@/shared/components/Collapsed.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { Comment, Fragment, Text, type VNode } from "vue";

type Props = {
  items: T[];
  loading?: boolean;
  confirmDestroyText?: string;
  emptyName?: string;
  hideDestroy?: boolean;
  hideEdit?: boolean;
  selectable?: boolean;
  // Passed straight down: the placeholder rows a list waiting for its first
  // records is held open with, which the ListGroup below draws to the recipe of
  // the row it stands in for.
  skeletonRows?: number;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  confirmDestroyText: undefined,
  emptyName: "entries",
  hideDestroy: false,
  hideEdit: false,
  selectable: false,
  skeletonRows: undefined,
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

// An open row hands its whole display over to the fields, and a column of
// offsets or prices says nothing about which record they belong to. A list
// whose item carries its name somewhere other than `name` - or carries one
// nothing is gained by printing - passes a `headline` slot instead.
const headlineFor = (item: T) => {
  const name = (item as { name?: unknown }).name;

  return typeof name === "string" && name.trim().length ? name : undefined;
};

const slots = useSlots();

// A slot that draws nothing for this record - a loaner whose model is gone -
// leaves a `v-if` comment and whitespace behind, which the row would otherwise
// keep a line's gap open above the fields for. So the vnodes are asked what
// they came to rather than the slot being asked whether it exists.
const rendersSomething = (nodes: VNode[]): boolean =>
  nodes.some((node) => {
    if (node.type === Comment) {
      return false;
    }

    if (node.type === Text) {
      return typeof node.children === "string"
        ? node.children.trim().length > 0
        : !!node.children;
    }

    if (node.type === Fragment) {
      return rendersSomething((node.children ?? []) as VNode[]);
    }

    return true;
  });

const headlineVisible = (item: T) =>
  slots.headline
    ? rendersSomething(slots.headline({ item }))
    : !!headlineFor(item);

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
          @click="resetSelected"
          :variant="BtnVariantsEnum.BARE"
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
    :expanded-id="editingId"
    :skeleton-rows="skeletonRows"
  >
    <template #prepend>
      <div v-if="creating" key="__create__" class="list-group__item">
        <div class="list-group__row list-group__row--expanded">
          <div class="inline-editable-list__form">
            <slot name="create" />
          </div>
          <div class="list-group__actions">
            <BtnGroup>
              <Btn data-test="save-create" @click="saveCreate">
                <i class="fa-duotone fa-check" />
              </Btn>
              <Btn data-test="cancel-create" @click="cancelCreate">
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
        <div class="inline-editable-list__edit">
          <div
            v-if="headlineVisible(item)"
            class="inline-editable-list__headline"
            data-test="edit-headline"
          >
            <slot name="headline" :item="item">{{ headlineFor(item) }}</slot>
          </div>
          <div class="inline-editable-list__form">
            <slot name="edit" :item="item" />
          </div>
        </div>
      </template>
      <template v-else>
        <slot name="display" :item="item" />
      </template>
    </template>

    <template #actions="{ item }">
      <template v-if="editingId === item.id">
        <BtnGroup>
          <Btn data-test="save-edit" @click="saveEdit">
            <i class="fa-duotone fa-check" />
          </Btn>
          <Btn data-test="cancel-edit" @click="cancelEdit">
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
        <BtnDropdown v-else-if="mobile">
          <slot name="actions" :item="item" :mobile="mobile" />
          <Btn v-if="!hideEdit" data-test="start-edit" @click="startEdit(item)">
            <i class="fa-duotone fa-pencil" />
            <span>{{ t("actions.edit") }}</span>
          </Btn>
          <Btn
            v-if="!hideDestroy"
            data-test="destroy"
            @click="destroy(item)"
            :tone="BtnTonesEnum.DANGER"
          >
            <i class="fa-duotone fa-trash" />
            <span>{{ t("actions.delete") }}</span>
          </Btn>
        </BtnDropdown>
        <BtnGroup v-else>
          <slot name="actions" :item="item" :mobile="false" />
          <Btn v-if="!hideEdit" data-test="start-edit" @click="startEdit(item)">
            <i class="fa-duotone fa-pencil" />
          </Btn>
          <Btn
            v-if="!hideDestroy"
            data-test="destroy"
            @click="destroy(item)"
            :tone="BtnTonesEnum.DANGER"
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
.inline-editable-list__edit {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.inline-editable-list__headline {
  color: var(--color-lifted, #eee);
  font-weight: 600;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

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
  color: var(--color-primary, #428bca);
  white-space: nowrap;
  font-size: 120%;

  :deep(.btn__content) {
    color: var(--color-primary, #428bca);
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
}

.inline-editable-list__checkbox {
  flex-shrink: 0;
}
</style>
