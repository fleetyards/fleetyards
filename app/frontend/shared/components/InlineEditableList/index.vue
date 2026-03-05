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
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  items: T[];
  loading?: boolean;
  confirmDestroyText?: string;
  addLabel?: string;
  emptyText?: string;
  emptyName?: string;
  hideAddButton?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  confirmDestroyText: undefined,
  addLabel: undefined,
  emptyText: undefined,
  emptyName: "entries",
  hideAddButton: false,
});

const { t } = useI18n();
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

const innerAddLabel = computed(() => {
  return props.addLabel || t("actions.add");
});

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
      <div v-if="creating" key="__create__" class="inline-editable-list-row">
        <div class="inline-form">
          <slot name="create" />
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

      <div
        v-for="item in items"
        :key="item.id"
        class="inline-editable-list-row"
      >
        <template v-if="editingId === item.id">
          <div class="inline-form">
            <slot name="edit" :item="item" />
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
          <div class="row align-items-center">
            <div class="col inline-editable-list-display">
              <slot name="display" :item="item" />
            </div>
            <div class="col-auto">
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
          </div>
        </template>
      </div>
    </TransitionGroup>

    <Loader :loading="loading" />

    <Empty
      v-if="!items.length && !creating && !loading"
      variant="box"
      hide-actions
      :name="emptyName"
    >
      <template v-if="emptyText" #headline>
        {{ emptyText }}
      </template>
      <template #info>
        <!-- no info text needed -->
      </template>
    </Empty>

    <div v-if="!creating && !hideAddButton" class="mt-2">
      <Btn :size="BtnSizesEnum.SMALL" @click="startCreate">
        <i class="fad fa-plus" />
        {{ innerAddLabel }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
