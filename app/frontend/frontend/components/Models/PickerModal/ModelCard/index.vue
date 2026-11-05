<script lang="ts">
export default {
  name: "ModelPickerCard",
};
</script>

<script lang="ts" setup>
import PickerCard from "@/shared/components/PickerCard/index.vue";
import CatalogueItemInfoBtn from "@/frontend/components/CatalogueItemPopover/InfoBtn/index.vue";
import { type ModelOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import type { ModelPickerBadge } from "@/frontend/components/Models/PickerModal/types";

type Props = {
  option: ModelOption;
  selected?: boolean;
  quantity?: number;
  quantities?: boolean;
  highlight?: `${ModelPickerBadge}`;
  note?: string;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selected: false,
  quantity: 1,
  quantities: false,
  highlight: undefined,
  note: undefined,
  disabled: false,
});

const emit = defineEmits<{
  toggle: [];
  increase: [];
  decrease: [];
}>();

const { t } = useI18n();

const subtitle = computed(() =>
  [props.option.manufacturer.name, props.option.classificationLabel]
    .filter(Boolean)
    .join(" · "),
);

/**
 * The flag matching the list you opened the picker from leads, because that is
 * the duplicate you are about to create; the other one is context worth having
 * (a wishlisted ship you are now buying) rather than a warning. A note names why
 * the card cannot be picked, which outranks both.
 */
const badges = computed(() => {
  // Which flag leads is a property of the flag, not of where it lands in the
  // list: keyed on position, a wishlisted ship shown in the *hangar* picker got
  // the loud tint purely by being the only badge on the card.
  const flags = [
    { key: "inHangar", set: props.option.inHangar },
    { key: "onWishlist", set: props.option.onWishlist },
  ]
    .filter((badge) => badge.set)
    .map((badge) => ({
      key: badge.key,
      label: t(`modelPicker.badges.${badge.key}`),
      primary: badge.key === props.highlight,
    }))
    .sort((a, b) => Number(b.primary) - Number(a.primary));

  if (!props.note) {
    return flags;
  }

  return [{ key: "note", label: props.note, primary: true }, ...flags];
});
</script>

<template>
  <PickerCard
    :name="option.name"
    :subtitle="subtitle"
    :image="option.media.storeImage?.mediumUrl"
    :badges="badges"
    :selected="selected"
    :disabled="disabled"
    :data-test="`model-picker-card-${option.slug}`"
    @toggle="emit('toggle')"
  >
    <template #info>
      <CatalogueItemInfoBtn
        :item="{ type: 'Model', slug: option.slug, name: option.name }"
      />
    </template>
    <template v-if="quantities && selected" #overlay>
      <div class="model-card__quantity">
        <button
          type="button"
          class="model-card__step"
          :disabled="quantity <= 1"
          :aria-label="t('modelPicker.actions.decrease', { name: option.name })"
          @click="emit('decrease')"
        >
          <i class="fa-regular fa-minus" />
        </button>
        <span class="model-card__count">{{ quantity }}</span>
        <button
          type="button"
          class="model-card__step"
          :aria-label="t('modelPicker.actions.increase', { name: option.name })"
          @click="emit('increase')"
        >
          <i class="fa-regular fa-plus" />
        </button>
      </div>
    </template>
  </PickerCard>
</template>

<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/* ---------- quantity ---------- */
.model-card__quantity {
  @apply relative z-[2] flex items-center self-end;
  @apply bg-gray-black/90 border-edge rounded-control-bare border;
  margin: 0 8px -8px 0;
}

.model-card__step {
  @apply text-text flex cursor-pointer items-center justify-center;
  @apply m-0 border-0 bg-transparent text-[11px];
  width: 24px;
  height: 24px;
}

.model-card__step:hover:not(:disabled) {
  @apply text-lifted;
}

.model-card__step:disabled {
  @apply cursor-default opacity-40;
}

.model-card__step:focus-visible {
  @apply outline-primary rounded-control-bare outline-2;
  outline-offset: -2px;
}

.model-card__count {
  @apply text-lifted text-[13px] leading-none font-semibold;
  min-width: 18px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}
</style>
