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
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  items: T[];
  loading?: boolean;
  confirmDestroyText?: string;
  emptyName?: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  confirmDestroyText: undefined,
  emptyName: "entries",
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
  <div class="inline-editable-list">
    <TransitionGroup name="list">
      <div v-if="creating" key="__create__" class="inline-editable-list__item">
        <div class="inline-editable-list__row">
          <div class="inline-editable-list__form">
            <slot name="create" />
          </div>
          <div class="inline-editable-list__actions">
            <BtnGroup inline>
              <Btn :size="BtnSizesEnum.SMALL" @click="saveCreate">
                <i class="fad fa-check" />
              </Btn>
              <Btn :size="BtnSizesEnum.SMALL" @click="cancelCreate">
                <i class="fad fa-times" />
              </Btn>
            </BtnGroup>
          </div>
        </div>
      </div>

      <div
        v-for="item in items"
        :key="item.id"
        class="inline-editable-list__item"
      >
        <div class="inline-editable-list__row">
          <template v-if="editingId === item.id">
            <div class="inline-editable-list__form">
              <slot name="edit" :item="item" />
            </div>
            <div class="inline-editable-list__actions">
              <BtnGroup inline>
                <Btn :size="BtnSizesEnum.SMALL" @click="saveEdit">
                  <i class="fad fa-check" />
                </Btn>
                <Btn :size="BtnSizesEnum.SMALL" @click="cancelEdit">
                  <i class="fad fa-times" />
                </Btn>
              </BtnGroup>
            </div>
          </template>
          <template v-else>
            <div class="inline-editable-list__display">
              <slot name="display" :item="item" />
            </div>
            <div class="inline-editable-list__actions">
              <BtnGroup inline>
                <slot name="actions" :item="item" />
                <Btn :size="BtnSizesEnum.SMALL" @click="startEdit(item)">
                  <i class="fad fa-pencil" />
                </Btn>
                <Btn
                  :size="BtnSizesEnum.SMALL"
                  :variant="BtnVariantsEnum.DANGER"
                  @click="destroy(item)"
                >
                  <i class="fad fa-trash" />
                </Btn>
              </BtnGroup>
            </div>
          </template>
        </div>
        <slot name="expanded" :item="item" />
      </div>
    </TransitionGroup>

    <Loader :loading="loading" />

    <Empty
      v-if="!items.length && !creating && !loading"
      variant="box"
      hide-actions
      :name="emptyName"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
