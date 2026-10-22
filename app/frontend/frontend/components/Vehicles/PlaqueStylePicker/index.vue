<script lang="ts">
export default {
  name: "VehiclePlaqueStylePicker",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import { FREE_PLAQUE_STYLE } from "@/frontend/components/Vehicles/Plaque/styles";
import { useI18n } from "@/shared/composables/useI18n";
import {
  NullableVehiclePlaqueStyleEnum,
  type Vehicle,
  type VehiclePlaqueStyleEnum,
} from "@/services/fyApi";

type Props = {
  // The plaque as it will read, drawn once per style.
  vehicle: Vehicle;
  captain?: string;
  isSupporter: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  captain: undefined,
});

const style = defineModel<VehiclePlaqueStyleEnum>({ required: true });

const emit = defineEmits<{
  // The call to support was followed, away from wherever the picker sits.
  support: [];
}>();

const { t } = useI18n();

const maker = computed(() => plaqueMakerFor(props.vehicle));

// Every style is shown, the ones a supporter unlocks greyed out for anyone else,
// so the perk is visible where it would be used.
const options = computed(() =>
  Object.values(NullableVehiclePlaqueStyleEnum)
    .filter((option): option is VehiclePlaqueStyleEnum => !!option)
    .filter((option) => option !== "manufacturer" || !!maker.value)
    .map((option) => ({
      value: option,
      label: t(`labels.vehiclePlaque.styles.${option}`),
      locked: !props.isSupporter && option !== FREE_PLAQUE_STYLE,
    })),
);

const freeOptions = computed(() =>
  options.value.filter((option) => !option.locked),
);

const lockedOptions = computed(() =>
  options.value.filter((option) => option.locked),
);

const previewFor = (option: VehiclePlaqueStyleEnum): Vehicle => ({
  ...props.vehicle,
  id: `${props.vehicle.id}-${option}`,
  plaqueStyle: option,
});

// The perk styles show in full; the call to support covers them only on hover,
// keyboard focus, or -- where nothing hovers -- a tap on one of them.
const upsellShown = ref(false);

const pick = (option: { value: VehiclePlaqueStyleEnum; locked: boolean }) => {
  if (option.locked) {
    upsellShown.value = true;
    return;
  }

  style.value = option.value;
};
</script>

<template>
  <div data-test="vehicle-plaque-styles">
    <div class="plaque-style-picker__styles" data-test="vehicle-plaque-style">
      <button
        v-for="option in freeOptions"
        :key="option.value"
        type="button"
        class="plaque-style-picker__style"
        :class="{
          'plaque-style-picker__style--active': style === option.value,
        }"
        :aria-pressed="style === option.value"
        :aria-disabled="option.locked"
        :data-test="`vehicle-plaque-style-${option.value}`"
        @click="pick(option)"
      >
        <VehiclePlaque :vehicle="previewFor(option.value)" :captain="captain" />
        <span class="plaque-style-picker__label">
          {{ option.label }}
        </span>
      </button>
    </div>
    <!-- The styles a supporter unlocks, under one call to support: the
         perk is shown where it would be used, not described elsewhere. -->
    <div
      v-if="lockedOptions.length"
      class="plaque-style-picker__locked"
      :class="{ 'plaque-style-picker__locked--open': upsellShown }"
      @mouseleave="upsellShown = false"
    >
      <div class="plaque-style-picker__styles">
        <button
          v-for="option in lockedOptions"
          :key="option.value"
          type="button"
          class="plaque-style-picker__style plaque-style-picker__style--locked"
          :aria-pressed="style === option.value"
          :aria-disabled="option.locked"
          :data-test="`vehicle-plaque-style-${option.value}`"
          @click="pick(option)"
        >
          <VehiclePlaque
            :vehicle="previewFor(option.value)"
            :captain="captain"
          />
          <span class="plaque-style-picker__label">
            <i class="fa-light fa-lock" />
            {{ option.label }}
          </span>
        </button>
      </div>
      <div
        class="plaque-style-picker__upsell"
        data-test="vehicle-plaque-upsell"
      >
        <div class="plaque-style-picker__upsell-box">
          <i class="fa-light fa-lock" />
          <p>{{ t("texts.vehiclePlaque.supporter") }}</p>
          <Btn
            :to="{ name: 'support' }"
            data-test="vehicle-plaque-support"
            @click="emit('support')"
          >
            {{ t("actions.supportUs") }}
          </Btn>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.plaque-style-picker__styles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 14px;
}

.plaque-style-picker__style {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 6px;
  border: 2px solid transparent;
  border-radius: 10px;
  background: none;
  color: inherit;
  text-align: left;
  cursor: pointer;
  transition: border-color 150ms ease;

  &:hover,
  &:focus-visible {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  }

  &--active,
  &--active:hover {
    border-color: var(--color-primary, #428bca);
  }

  &--locked:hover,
  &--locked:focus-visible {
    border-color: transparent;
  }
}

.plaque-style-picker__label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
}

.plaque-style-picker__locked {
  position: relative;
  margin-top: 14px;
}

.plaque-style-picker__upsell {
  position: absolute;
  inset: 0;
  z-index: 2;
  opacity: 0;
  pointer-events: none;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 48px;
  border-radius: 10px;
  background: rgb(0 0 0 / 0.45);
  backdrop-filter: blur(0);
  // Out a touch quicker than in, so leaving never feels sticky.
  transition:
    opacity 160ms ease-in,
    backdrop-filter 160ms ease-in;
}

.plaque-style-picker__locked:hover .plaque-style-picker__upsell,
.plaque-style-picker__locked:focus-within .plaque-style-picker__upsell,
.plaque-style-picker__locked--open .plaque-style-picker__upsell {
  opacity: 1;
  pointer-events: auto;
  transition:
    opacity 220ms ease-out,
    backdrop-filter 260ms ease-out;

  .plaque-style-picker__upsell-box {
    opacity: 1;
    transform: none;
    transition:
      opacity 240ms ease-out 60ms,
      transform 320ms cubic-bezier(0.2, 0.9, 0.3, 1.2) 60ms;
  }
}

// The blur and the rise only where motion is welcome; otherwise it just fades.
@media (prefers-reduced-motion: no-preference) {
  .plaque-style-picker__locked:hover .plaque-style-picker__upsell,
  .plaque-style-picker__locked:focus-within .plaque-style-picker__upsell,
  .plaque-style-picker__locked--open .plaque-style-picker__upsell {
    backdrop-filter: blur(3px);
  }

  // Rises and settles in just behind the backdrop.
  .plaque-style-picker__upsell-box {
    transform: translateY(10px) scale(0.96);
  }
}

// Sticks to the top of the dialog while the styles scroll beneath it.
.plaque-style-picker__upsell-box {
  position: sticky;
  top: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  max-width: 380px;
  padding: 20px 24px;
  border: 2px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-surface-slim, 12px);
  background: var(--color-surface, rgb(39 43 48 / 0.9));
  text-align: center;
  opacity: 0;
  transition:
    opacity 140ms ease-in,
    transform 160ms ease-in;

  i {
    font-size: 1.6rem;
    color: var(--color-primary, #428bca);
  }

  p {
    margin: 0;
  }
}
</style>
