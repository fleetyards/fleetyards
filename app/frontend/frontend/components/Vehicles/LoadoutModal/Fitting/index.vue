<script lang="ts">
export default {
  name: "VehicleLoadoutModalFitting",
};
</script>

<script lang="ts" setup>
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
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
  // The option under the pointer or focus, so the editor can compare it with
  // what the slot holds; `null` is the empty choice.
  preview: [slot: string, moduleId: string | null];
  // The pointer or focus has left the slots: back to what is picked.
  previewEnd: [];
  pick: [slot: string];
}>();

const root = ref<HTMLElement>();

// Focus moving between options keeps the preview; only leaving the list ends it.
const onFocusOut = (event: FocusEvent) => {
  if (!root.value?.contains(event.relatedTarget as Node | null)) {
    emit("previewEnd");
  }
};

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

// The hull's stock modules are always there to fit; the rest only when owned.
const candidates = (slot: string) =>
  props.modules.filter(
    (mod) =>
      mod.slot === slot && (mod.stock || props.ownedIds.includes(mod.id)),
  );

// Owned, but the game files never said which slot it takes, so there is
// nowhere to fit it.
const unslotted = computed(() => owned.value.filter((mod) => !mod.slot));

const { slotLabel } = useLoadoutSlotLabel();

const fittedIn = (slot: string) => props.modelValue[slot];

const badges = (mod: ModelModule): AddonBadge[] =>
  mod.stock
    ? [
        {
          key: "stock",
          label: t("labels.vehicleLoadout.stock"),
          variant: PillVariantsEnum.NEUTRAL,
        },
      ]
    : [];

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
  <div
    ref="root"
    class="loadout-fitting"
    data-test="vehicle-loadout-fitting"
    @mouseleave="emit('previewEnd')"
    @focusout="onFocusOut"
  >
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
          @mouseenter="emit('preview', slot, null)"
          @focusin="emit('preview', slot, null)"
          @toggle="
            fit(slot);
            emit('pick', slot);
          "
        />
        <AddonOption
          v-for="mod in candidates(slot).filter(
            (mod) => editable || mod.id === fittedIn(slot),
          )"
          :key="mod.id"
          :name="mod.name"
          :image="mod.media?.storeImage?.smallUrl"
          :contents="mod.description || contents(mod)"
          :badges="badges(mod)"
          :selected="editable && mod.id === fittedIn(slot)"
          :editable="editable"
          test-id="vehicle-loadout-slot-module"
          @mouseenter="emit('preview', slot, mod.id)"
          @focusin="emit('preview', slot, mod.id)"
          @toggle="
            fit(slot, mod.id);
            emit('pick', slot);
          "
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
