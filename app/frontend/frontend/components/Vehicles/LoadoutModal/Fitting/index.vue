<script lang="ts">
export default {
  name: "VehicleLoadoutModalFitting",
};
</script>

<script lang="ts" setup>
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { type ModelModule } from "@/services/fyApi";

type Props = {
  // The hull's whole module catalogue; each module names the slot it takes.
  modules: ModelModule[];
  ownedIds: string[];
  // The fitted module per slot.
  modelValue?: Record<string, string>;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => ({}),
  editable: false,
});

const emit = defineEmits<{
  "update:modelValue": [fitted: Record<string, string>];
}>();

const { t } = useI18n();

const { contents } = useModuleContents();

const owned = computed(() =>
  props.modules.filter((mod) => props.ownedIds.includes(mod.id)),
);

const slots = computed(() =>
  [
    ...new Set(
      props.modules
        .map((mod) => mod.slot)
        .filter((slot): slot is string => !!slot),
    ),
  ].sort(),
);

const candidates = (slot: string) =>
  owned.value.filter((mod) => mod.slot === slot);

// Owned, but the game files never said which slot it takes, so there is
// nowhere to fit it.
const unslotted = computed(() => owned.value.filter((mod) => !mod.slot));

// The same keywords `ModuleHardpoint.derive_slot` reads a slot's position
// from, bow and stern being the front and rear by another name.
const SLOT_POSITIONS = [
  ["front", "front"],
  ["bow", "front"],
  ["rear", "rear"],
  ["stern", "rear"],
  ["left", "left"],
  ["right", "right"],
] as const;

const slotLabel = (slot: string) => {
  const position = SLOT_POSITIONS.find(([keyword]) => slot.includes(keyword));

  return t(`labels.vehicleLoadout.slots.${position?.[1] || "default"}`);
};

const fittedIn = (slot: string) => props.modelValue[slot];

const fit = (slot: string, moduleId?: string) => {
  const next = { ...props.modelValue };

  if (moduleId) {
    next[slot] = moduleId;
  } else {
    delete next[slot];
  }

  emit("update:modelValue", next);
};

const visibleSlots = computed(() =>
  props.editable ? slots.value : slots.value.filter((slot) => !!fittedIn(slot)),
);
</script>

<template>
  <div class="loadout-fitting" data-test="vehicle-loadout-fitting">
    <fieldset
      v-for="slot in visibleSlots"
      :key="slot"
      :data-test="`vehicle-loadout-slot-${slot}`"
    >
      <legend>
        <h4>{{ slotLabel(slot) }}</h4>
      </legend>
      <div class="addon-options">
        <AddonOption
          v-if="editable"
          :name="t('labels.vehicleLoadout.nothingFitted')"
          icon="fa-duotone fa-layer-minus"
          :selected="!fittedIn(slot)"
          test-id="vehicle-loadout-slot-empty"
          @toggle="fit(slot)"
        />
        <AddonOption
          v-for="mod in candidates(slot).filter(
            (mod) => editable || mod.id === fittedIn(slot),
          )"
          :key="mod.id"
          :name="mod.name"
          :image="mod.media?.storeImage?.smallUrl"
          :contents="mod.description || contents(mod)"
          :selected="editable && mod.id === fittedIn(slot)"
          :editable="editable"
          test-id="vehicle-loadout-slot-module"
          @toggle="fit(slot, mod.id)"
        />
        <p
          v-if="editable && !candidates(slot).length"
          class="loadout-fitting__hint"
        >
          {{ t("labels.vehicleLoadout.noOwnedModuleForSlot") }}
        </p>
      </div>
    </fieldset>

    <p
      v-if="editable && unslotted.length"
      class="loadout-fitting__hint"
      data-test="vehicle-loadout-unslotted"
    >
      {{
        t("labels.vehicleLoadout.unslotted", {
          modules: unslotted.map((mod) => mod.name).join(", "),
        })
      }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddonOption/list";

.loadout-fitting {
  display: flex;
  flex-direction: column;
  gap: 16px;

  fieldset {
    min-width: 0;
  }

  legend {
    margin-bottom: 8px;
    border: none;

    h4 {
      margin: 0;
    }
  }

  &__hint {
    margin: 0;
    color: var(--color-text-dim);
    font-size: 13px;
  }
}
</style>
