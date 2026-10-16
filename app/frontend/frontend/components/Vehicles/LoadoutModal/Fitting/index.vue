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
import { moduleSlots } from "@/frontend/components/Vehicles/LoadoutModal/moduleSlots";
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

const slots = computed(() => moduleSlots(props.modules));

// A loadout is a plan: every module the slot takes, owned or not.
const candidates = (slot: string) =>
  props.modules.filter((mod) => mod.slot === slot);

const { slotLabel } = useLoadoutSlotLabel();

const fittedIn = (slot: string) => props.modelValue[slot];

// Whether picking it means using what the ship has, or planning for something
// it does not have yet.
const ownership = (mod: ModelModule): AddonBadge => {
  if (props.ownedIds.includes(mod.id)) {
    return {
      key: "ownership",
      label: t("labels.vehicleLoadout.owned"),
      variant: PillVariantsEnum.SUCCESS,
    };
  }

  if (mod.stock) {
    return {
      key: "ownership",
      label: t("labels.vehicleLoadout.stock"),
      variant: PillVariantsEnum.NEUTRAL,
    };
  }

  return { key: "ownership", label: t("labels.vehicleLoadout.notOwned") };
};

const badges = (mod: ModelModule): AddonBadge[] =>
  props.editable ? [ownership(mod)] : [];

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
      </div>
    </fieldset>
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
}
</style>
