<script lang="ts">
export default {
  name: "DressingRoomSlotPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import CataloguePicker, {
  type CatalogueItem,
} from "@/frontend/components/CataloguePicker/index.vue";
import ItemStats from "@/frontend/components/DressingRoom/ItemStats/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { INVENTORY_EQUIPMENT_TYPES } from "@/frontend/composables/useInventoryOptions";
import { WEAPON_SUB_TYPES, isWeaponSlot } from "@/frontend/utils/dressingRoom";
import {
  type SlotFit,
  fitsSlot,
  providerNames,
} from "@/frontend/utils/dressingRoomFit";
import {
  type Equipment,
  type EquipmentSlotEnum,
  OutfitSlotEnum,
} from "@/services/fyApi";

type Props = {
  slot: OutfitSlotEnum;
  selectedSlug?: string;
  // What the worn pieces leave room for: anything else is shown, but greyed
  // out with the reason.
  fit?: SlotFit;
};

const props = withDefaults(defineProps<Props>(), {
  selectedSlug: undefined,
  fit: () => ({ kind: "open" }),
});

const emit = defineEmits<{
  select: [item: Equipment];
}>();

const { t } = useI18n();

const comlink = useComlink();

const fits = (item: CatalogueItem) => fitsSlot(props.fit, item as Equipment);

const isDisabled = (item: CatalogueItem) => !fits(item);

const isSelected = (item: CatalogueItem) => item.slug === props.selectedSlug;

const withSize = computed(
  () => isWeaponSlot(props.slot) || props.slot === OutfitSlotEnum.BACKPACK,
);

const misfitReason = computed(() =>
  t("dressingRoom.fit.doesNotFit", { item: providerNames(props.fit) }),
);

// Nothing worn offers this slot at all: said once, above the grid.
const noPort = computed(() =>
  props.fit.kind === "none"
    ? t("dressingRoom.fit.noPort", { item: providerNames(props.fit) })
    : undefined,
);

// A weapon slot takes weapons of its size; an armour slot the armour and
// undersuits made for it.
const query = computed(() =>
  isWeaponSlot(props.slot)
    ? {
        equipmentTypeIn: ["weapon"],
        subTypeIn: WEAPON_SUB_TYPES[props.slot],
      }
    : {
        slotIn: [props.slot as EquipmentSlotEnum],
        equipmentTypeIn: INVENTORY_EQUIPMENT_TYPES.armor,
      },
);

const pick = (item: CatalogueItem) => {
  if (isDisabled(item)) return;

  emit("select", item as Equipment);
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal :title="t(`dressingRoom.slots.${slot}`)" flush>
    <CataloguePicker
      kind="Equipment"
      :query="query"
      :is-selected="isSelected"
      :is-disabled="isDisabled"
      card-test-prefix="dressing-room-option"
      data-test="dressing-room-slot-picker"
      @toggle="pick"
    >
      <template v-if="noPort" #notice>
        <p
          class="slot-picker-modal__no-port"
          data-test="dressing-room-slot-picker-no-port"
        >
          {{ noPort }}
        </p>
      </template>
      <template #details="{ item }">
        <ItemStats :equipment="item as Equipment" :with-size="withSize" />
        <span v-if="!fits(item)" class="slot-picker-modal__misfit">
          {{ misfitReason }}
        </span>
      </template>
    </CataloguePicker>
  </Modal>
</template>

<style lang="scss" scoped>
.slot-picker-modal__no-port {
  margin: 0;
  padding-bottom: 12px;
  color: $warning;
}

.slot-picker-modal__misfit {
  color: $warning;
  font-size: 0.85em;
}
</style>
