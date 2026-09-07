<script lang="ts">
export default {
  name: "AddonOption",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";

type Props = {
  name: string;
  image?: string;
  // A glyph instead of a photograph, for a row that stands for the absence of a
  // choice rather than for a thing with a picture.
  icon?: string;
  contents?: string;
  badges?: AddonBadge[];
  selected?: boolean;
  // How many copies are fitted. Only ever shown above one — a stepper reading
  // "1" on every fitted row is noise, and the fitted pill already says it.
  count?: number;
  quantities?: boolean;
  editable?: boolean;
  testId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  icon: undefined,
  contents: undefined,
  badges: () => [],
  selected: false,
  count: 0,
  quantities: false,
  editable: true,
  testId: "addon-option",
});

const emit = defineEmits<{
  toggle: [];
  increase: [];
  decrease: [];
}>();

const { t } = useI18n();

const { supported: webpSupported } = useWebpCheck();

// Named apart from the prop it reads: a setup binding sharing a prop's name
// shadows it in the template, which is a trap rather than a shorthand.
const imageSrc = computed(
  () => props.image || (webpSupported.value ? fallbackImage : fallbackImageJpg),
);

const stepper = computed(
  () => props.editable && props.quantities && props.selected,
);

/**
 * The toggle is an overlay covering the row, so its name has to carry
 * everything the row shows — the badges included, which are decoration to a
 * screen reader.
 */
const accessibleName = computed(() =>
  [
    props.name,
    props.contents,
    ...props.badges.map((badge) => badge.label),
    props.count > 1 ? t("addon.copies", { count: props.count }) : undefined,
  ]
    .filter(Boolean)
    .join(", "),
);
</script>

<template>
  <div
    class="addon-option"
    :class="{
      'addon-option--selected': selected,
      'addon-option--static': !editable,
    }"
    :data-test="testId"
  >
    <span v-if="icon" class="addon-option__image addon-option__image--glyph">
      <i :class="icon" />
    </span>
    <img
      v-else
      :src="imageSrc"
      :alt="name"
      class="addon-option__image"
      loading="lazy"
    />

    <span class="addon-option__body">
      <span class="addon-option__name">{{ name }}</span>
      <span v-if="contents" class="addon-option__contents">{{ contents }}</span>
    </span>

    <span class="addon-option__meta">
      <template v-for="badge in badges" :key="badge.key">
        <Pill v-if="badge.variant" :variant="badge.variant">
          {{ badge.label }}
        </Pill>
        <span v-else class="addon-option__figure">{{ badge.label }}</span>
      </template>
    </span>

    <!--
      A sibling of the toggle rather than a child: the toggle is a button, and a
      button may not contain buttons. It is stacked above the overlay so its
      clicks are its own.
    -->
    <span v-if="stepper" class="addon-option__quantity">
      <button
        type="button"
        class="addon-option__step"
        :disabled="count <= 1"
        :aria-label="t('addon.actions.decrease', { name })"
        :data-test="`${testId}-decrease`"
        @click="emit('decrease')"
      >
        <i class="fa-regular fa-minus" />
      </button>
      <span class="addon-option__count">{{ count }}</span>
      <button
        type="button"
        class="addon-option__step"
        :aria-label="t('addon.actions.increase', { name })"
        :data-test="`${testId}-increase`"
        @click="emit('increase')"
      >
        <i class="fa-regular fa-plus" />
      </button>
    </span>

    <button
      v-if="editable"
      type="button"
      class="addon-option__toggle"
      :aria-pressed="selected"
      :aria-label="accessibleName"
      :data-test="`${testId}-toggle`"
      @click="emit('toggle')"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
