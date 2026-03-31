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
import ListGroup from "@/shared/components/ListGroup/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  items: T[];
  loading?: boolean;
  confirmDestroyText?: string;
  emptyName?: string;
  hideDestroy?: boolean;
  hideEdit?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  confirmDestroyText: undefined,
  emptyName: "entries",
  hideDestroy: false,
  hideEdit: false,
});

const { displayConfirm } = useAppNotifications();

const emit = defineEmits<{
  "start-edit": [item: T];
  "save-edit": [];
  "start-create": [];
  "save-create": [];
  destroy: [item: T];
}>();

const editingId = ref<string | null>(null);
const creating = ref(false);

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
  startCreate,
  finishEdit,
  finishCreate,
});
</script>

<template>
  <ListGroup :items="items" :loading="loading" :empty-name="emptyName">
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
        <slot v-if="hideEdit && hideDestroy" name="actions" :item="item" />
        <BtnGroup v-else inline>
          <slot name="actions" :item="item" />
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
</style>
