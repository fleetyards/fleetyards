<script lang="ts">
export default {
  name: "LoadoutSocket",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { HardpointCategoryEnum } from "@/services/fyApi";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import type { LoadoutSocketSlot } from "@/frontend/components/Loadout/Socket/types";

type Props = {
  socket: LoadoutSocketSlot;
  active?: boolean;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: false,
  editable: false,
});

const emit = defineEmits<{
  select: [];
}>();

const { t } = useI18n();

const FILL_DURATION = 700;

// Set for the length of the fill animation each time something new lands in
// the socket, so a pick reads as the slot taking the item.
const justFilled = ref(false);

let fillTimer: ReturnType<typeof setTimeout> | undefined;

watch(
  () => props.socket.item?.id,
  (id, previous) => {
    if (!id || id === previous) return;

    justFilled.value = true;
    clearTimeout(fillTimer);
    fillTimer = setTimeout(() => {
      justFilled.value = false;
    }, FILL_DURATION);
  },
);

onBeforeUnmount(() => clearTimeout(fillTimer));

const accessibleName = computed(() =>
  [
    props.socket.label,
    props.socket.size,
    props.socket.item?.name || t("labels.loadoutPicker.emptySocket"),
    props.socket.item?.figure,
    props.socket.item?.headline
      ? `${props.socket.item.headline.value} ${props.socket.item.headline.label}`
      : undefined,
    props.socket.changed ? t("labels.loadoutPicker.changed") : undefined,
  ]
    .filter(Boolean)
    .join(", "),
);
</script>

<template>
  <component
    :is="editable ? 'button' : 'div'"
    :type="editable ? 'button' : undefined"
    class="loadout-socket"
    :class="{
      'loadout-socket--active': active,
      'loadout-socket--empty': !socket.item,
      'loadout-socket--occupied': !!socket.item,
      'loadout-socket--changed': socket.changed,
      'loadout-socket--filled': justFilled,
      'loadout-socket--static': !editable,
    }"
    :aria-pressed="editable ? active : undefined"
    :aria-label="editable ? accessibleName : undefined"
    :data-test="`loadout-socket-${socket.id}`"
    @click="editable && emit('select')"
  >
    <span class="loadout-socket__frame">
      <img
        v-if="socket.item?.image"
        :src="socket.item.image"
        alt=""
        class="loadout-socket__image"
        loading="lazy"
      />
      <HardpointCategoryIcon
        v-else-if="socket.item"
        :category="socket.item.category || HardpointCategoryEnum.MODULE"
        class="loadout-socket__glyph"
      />
      <i
        v-else
        class="loadout-socket__glyph fa-light fa-plus"
        aria-hidden="true"
      />
    </span>

    <span class="loadout-socket__body">
      <span class="loadout-socket__label">
        {{ socket.label }}
        <span v-if="socket.size" class="loadout-socket__size">
          {{ socket.size }}
        </span>
        <span
          v-if="socket.changed"
          class="loadout-socket__changed"
          :title="t('labels.loadoutPicker.changed')"
          data-test="loadout-socket-changed"
        />
      </span>
      <span class="loadout-socket__name" data-test="loadout-socket-name">
        {{ socket.item?.name || t("labels.loadoutPicker.emptySocket") }}
      </span>
      <span v-if="socket.item?.figure" class="loadout-socket__figure">
        {{ socket.item.figure }}
      </span>
    </span>

    <span
      v-if="socket.item?.headline"
      class="loadout-socket__headline"
      data-test="loadout-socket-headline"
    >
      <span class="loadout-socket__headline-value">
        {{ socket.item.headline.value }}
      </span>
      <span class="loadout-socket__headline-label">
        {{ socket.item.headline.label }}
      </span>
    </span>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
