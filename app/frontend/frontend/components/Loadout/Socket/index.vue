<script lang="ts">
export default {
  name: "LoadoutSocket",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointHeadline from "@/frontend/components/Models/Hardpoints/Headline/index.vue";
import HardpointStats from "@/frontend/components/Models/Hardpoints/Stats/index.vue";
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

const count = computed(() => props.socket.members?.length ?? 1);

const lockedLabel = computed(() => {
  if (props.socket.lockedBy === "ship") {
    return t("labels.loadoutPicker.fixedByShip");
  }

  return props.socket.lockedBy === "noAlternatives"
    ? t("labels.loadoutPicker.noOtherPart")
    : undefined;
});

const accessibleName = computed(() =>
  [
    props.socket.label,
    count.value > 1 ? `× ${count.value}` : undefined,
    props.socket.size,
    props.socket.item?.name || t("labels.loadoutPicker.emptySocket"),
    props.socket.item?.figure,
    props.socket.item?.headline
      ? `${props.socket.item.headline.value} ${props.socket.item.headline.label}`
      : undefined,
    props.socket.changed ? t("labels.loadoutPicker.changed") : undefined,
    props.socket.refused
      ? `${t("labels.vehicleLoadout.refused.badge")}: ${props.socket.refused}`
      : undefined,
    lockedLabel.value,
  ]
    .filter(Boolean)
    .join(", "),
);

// The row is the control, as a ship page's module row is: a click on what sits
// inside it is that row's own, so it goes no further up the tree.
const select = (event: Event) => {
  event.stopPropagation();
  if (props.editable) emit("select");
};
</script>

<template>
  <HardpointItem
    :count="count"
    class="loadout-socket"
    :class="{
      'loadout-socket--active': active,
      'loadout-socket--empty': !socket.item,
      'loadout-socket--occupied': !!socket.item,
      'loadout-socket--changed': socket.changed,
      'loadout-socket--refused': !!socket.refused,
      'loadout-socket--filled': justFilled,
      'loadout-socket--static': !editable,
      'loadout-socket--locked': !!lockedLabel,
    }"
    :role="editable ? 'button' : undefined"
    :tabindex="editable ? 0 : undefined"
    :aria-pressed="editable ? active : undefined"
    :aria-label="editable || lockedLabel ? accessibleName : undefined"
    :data-test="`loadout-socket-${socket.id}`"
    data-loadout-socket
    @click="select"
    @keydown.enter.self.prevent="select"
    @keydown.space.self.prevent="select"
  >
    <template v-if="$slots.actions" #actions>
      <slot name="actions" />
    </template>
    <template #default>
      <HardpointSize :size="socket.maxSize" />
      <span class="loadout-socket__frame">
        <img
          v-if="socket.item?.image"
          :src="socket.item.image"
          alt=""
          class="loadout-socket__image"
          loading="lazy"
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
        <span
          v-if="socket.refused"
          class="loadout-socket__refused"
          data-test="loadout-socket-refused"
        >
          <i class="fa-solid fa-triangle-exclamation" aria-hidden="true" />
          {{ t("labels.vehicleLoadout.refused.badge") }}: {{ socket.refused }}
        </span>
        <span
          v-if="lockedLabel"
          class="loadout-socket__locked"
          data-test="loadout-socket-locked"
        >
          <i class="fa-solid fa-lock" aria-hidden="true" />
          {{ lockedLabel }}
        </span>
      </span>
      <HardpointHeadline
        v-if="socket.item?.headline"
        :value="socket.item.headline.value"
        :unit="socket.item.headline.label"
        data-test="loadout-socket-headline"
      />
      <HardpointStats
        v-if="socket.item?.stats?.length"
        :stats="socket.item.stats"
      />
    </template>
    <template v-if="$slots.children" #loadout>
      <slot name="children" />
    </template>
  </HardpointItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
