<script lang="ts">
export default {
  name: "DressingRoomSlotRow",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment, type OutfitSlotEnum } from "@/services/fyApi";

type Props = {
  slot: OutfitSlotEnum;
  label: string;
  // The full name, where `label` leans on a heading above it.
  fullLabel?: string;
  item?: Equipment;
  selected?: boolean;
  loading?: boolean;
  missing?: boolean;
  disabled?: boolean;
  warning?: string;
  positionPending?: boolean;
  noHolo?: boolean;
  holdable?: boolean;
  held?: boolean;
  // For a narrow column: a number for a label, names that wrap, and no link out.
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  fullLabel: undefined,
  item: undefined,
  selected: false,
  loading: false,
  missing: false,
  disabled: false,
  warning: undefined,
  positionPending: false,
  noHolo: false,
  holdable: false,
  held: false,
  compact: false,
});

const emit = defineEmits<{
  pick: [];
  hold: [];
  clear: [];
}>();

const { t } = useI18n();

const accessibleName = computed(() =>
  props.fullLabel
    ? `${props.fullLabel}: ${props.item?.name ?? t("dressingRoom.choose")}`
    : undefined,
);
</script>

<template>
  <li
    class="dressing-room__slot"
    :class="{ 'dressing-room__slot--compact': compact }"
    :data-test="`dressing-room-slot-${slot}`"
  >
    <button
      type="button"
      class="dressing-room__slot-pick"
      :aria-label="accessibleName"
      :data-test="`dressing-room-pick-${slot}`"
      :disabled="disabled"
      @click="emit('pick')"
    >
      <span class="dressing-room__slot-label">{{ label }}</span>
      <span v-if="item" class="dressing-room__slot-item">{{ item.name }}</span>
      <span v-else-if="loading" class="dressing-room__slot-item">…</span>
      <span
        v-else-if="missing"
        class="dressing-room__slot-item dressing-room__slot-item--missing"
      >
        {{ t("dressingRoom.notFound") }}
      </span>
      <span
        v-else
        class="dressing-room__slot-item dressing-room__slot-item--empty"
      >
        {{ t("dressingRoom.choose") }}
      </span>
      <span
        v-if="warning"
        class="dressing-room__slot-note dressing-room__slot-note--warning"
        :data-test="`dressing-room-fit-${slot}`"
      >
        {{ warning }}
      </span>
      <span
        v-else-if="item && positionPending"
        class="dressing-room__slot-note"
        :data-test="`dressing-room-position-pending-${slot}`"
      >
        {{ t("dressingRoom.positionPending") }}
      </span>
      <span
        v-else-if="item && noHolo"
        class="dressing-room__slot-note"
        :data-test="`dressing-room-no-holo-${slot}`"
      >
        {{ t("dressingRoom.noHolo") }}
      </span>
    </button>
    <Btn
      v-if="holdable"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      :active="held"
      :aria-pressed="held"
      :aria-label="t('dressingRoom.hold')"
      v-tooltip="t('dressingRoom.hold')"
      :data-test="`dressing-room-hold-${slot}`"
      @click="emit('hold')"
    >
      <i class="fa-light fa-hand" />
    </Btn>
    <Btn
      v-if="item && !compact"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      :to="{ name: 'equipment-item', params: { slug: item.slug } }"
      :aria-label="t('dressingRoom.openItem')"
    >
      <i class="fa-light fa-arrow-up-right-from-square" />
    </Btn>
    <Btn
      v-if="selected"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      :aria-label="t('dressingRoom.remove')"
      :data-test="`dressing-room-clear-${slot}`"
      @click="emit('clear')"
    >
      <i class="fa-light fa-xmark" />
    </Btn>
  </li>
</template>

<style lang="scss" scoped>
.dressing-room__slot {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.dressing-room__slot-pick {
  display: grid;
  flex: 1;
  grid-template-columns: 6rem minmax(0, 1fr);
  align-items: baseline;
  column-gap: 0.75rem;
  min-width: 0;
  min-height: $tap-target-min;
  padding: 0.375rem 0.5rem;
  border: 0;
  border-radius: 4px;
  background: none;
  color: inherit;
  text-align: left;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    background: $gray-black-hover;
  }
}

.dressing-room__slot-label {
  color: $gray-lighter;
}

.dressing-room__slot-item {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dressing-room__slot-item--empty {
  color: $gray-light;
  font-style: italic;
}

.dressing-room__slot-item--missing {
  color: $warning;
}

.dressing-room__slot-note {
  grid-column: 2;
  color: $gray-light;
  font-size: 0.85em;
}

.dressing-room__slot-note--warning {
  color: $warning;
}

.dressing-room__slot--compact .dressing-room__slot-pick {
  grid-template-columns: 1.25rem minmax(0, 1fr);
  column-gap: 0.5rem;
}

.dressing-room__slot--compact .dressing-room__slot-item {
  overflow: visible;
  white-space: normal;
}
</style>
