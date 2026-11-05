<script lang="ts">
export default {
  name: "DressingRoomStoredItemPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import CataloguePicker, {
  type CatalogueItem,
} from "@/frontend/components/CataloguePicker/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type StorageInventory,
  microScu,
  storeProblem,
} from "@/frontend/utils/dressingRoomStorage";
import { type Equipment, type OutfitHolderEnum } from "@/services/fyApi";

interface Props {
  holder: OutfitHolderEnum;
  inventory: StorageInventory;
  // A getter, since a modal's props are set once.
  used?: () => number;
}

const props = withDefaults(defineProps<Props>(), { used: () => 0 });

const emit = defineEmits<{
  select: [item: Equipment];
}>();

const { t, toNumber } = useI18n();

const comlink = useComlink();

const problem = (item: CatalogueItem) =>
  storeProblem(props.inventory, item as Equipment, props.used());

const pick = (item: CatalogueItem) => {
  emit("select", item as Equipment);
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal
    :title="
      t('dressingRoom.storage.pickerTitle', {
        piece: t(`dressingRoom.slots.${holder}`),
      })
    "
    flush
  >
    <CataloguePicker
      kind="Equipment"
      :is-disabled="(item) => !!problem(item)"
      card-test-prefix="dressing-room-stored-option"
      data-test="dressing-room-stored-picker"
      @toggle="pick"
    >
      <template #details="{ item }">
        <span
          v-if="microScu(item as Equipment)"
          class="stored-item-picker__volume"
        >
          {{ toNumber(microScu(item as Equipment), "microScu") }}
        </span>
        <span v-if="problem(item)" class="stored-item-picker__misfit">
          {{ t(`dressingRoom.storage.misfit.${problem(item)}`) }}
        </span>
      </template>
    </CataloguePicker>
  </Modal>
</template>

<style lang="scss" scoped>
.stored-item-picker__volume {
  color: $gray-lighter;
  font-size: 0.85em;
}

.stored-item-picker__misfit {
  color: $warning;
  font-size: 0.85em;
}
</style>
