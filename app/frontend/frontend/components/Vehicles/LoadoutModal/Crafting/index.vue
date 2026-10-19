<script lang="ts">
export default {
  name: "VehicleLoadoutModalCrafting",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import BlueprintSlot from "@/frontend/components/Blueprints/Slot/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { CraftedPart } from "@/frontend/composables/useComponentFitting";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import {
  BlueprintCraftableTypeEnum,
  type LoadoutComponentRef,
  useBlueprint,
  useBlueprints,
} from "@/services/fyApi";

type Props = {
  // The part the slot holds, as catalogued.
  component: LoadoutComponentRef;
  crafted?: CraftedPart;
};

const props = withDefaults(defineProps<Props>(), {
  crafted: undefined,
});

const emit = defineEmits<{
  "update:crafted": [value: CraftedPart | undefined];
}>();

const { t } = useI18n();

const PRESETS = [0, 250, 500, 750, 1000];

// Most parts have no recipe, and then there is nothing to offer.
const { data: recipesData } = useBlueprints(
  () => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.COMPONENT,
      craftableIdEq: props.component.id,
    },
  }),
  { query: { enabled: () => !!props.component.id } },
);

// Three parts have two recipes; the one it was crafted from stays chosen.
const recipe = computed(() => {
  const list = recipesData.value?.items ?? [];

  return (
    list.find((entry) => entry.id === props.crafted?.blueprintId) ?? list[0]
  );
});

const { data: blueprint } = useBlueprint(
  () => props.crafted?.blueprintSlug ?? "",
  { query: { enabled: () => !!props.crafted } },
);

const costSlots = computed(() => blueprint.value?.costSlots ?? []);

const open = ref(false);

const qualityFor = (position: number) =>
  props.crafted?.qualities[position] ?? NEUTRAL_QUALITY;

const toggle = () => {
  if (props.crafted) {
    emit("update:crafted", undefined);
    return;
  }

  if (!recipe.value) return;

  open.value = true;
  emit("update:crafted", {
    blueprintId: recipe.value.id,
    blueprintSlug: recipe.value.slug,
    qualities: {},
  });
};

const setQuality = (position: number, quality: number) => {
  if (!props.crafted) return;

  emit("update:crafted", {
    ...props.crafted,
    qualities: { ...props.crafted.qualities, [position]: quality },
  });
};

const setEveryQuality = (quality: number) => {
  if (!props.crafted) return;

  emit("update:crafted", {
    ...props.crafted,
    qualities: Object.fromEntries(
      costSlots.value.map((slot) => [slot.position, quality]),
    ),
  });
};

// One figure for the whole craft when the panel is closed: the grade every
// slot shares, or the range they span.
const summary = computed(() => {
  if (!costSlots.value.length) return undefined;

  const grades = costSlots.value.map((slot) => qualityFor(slot.position));
  const low = Math.min(...grades);
  const high = Math.max(...grades);

  return low === high
    ? t("labels.vehicleLoadout.crafting.qualityAll", { quality: low })
    : t("labels.vehicleLoadout.crafting.qualityRange", { low, high });
});
</script>

<template>
  <section
    v-if="recipe"
    class="loadout-crafting"
    data-test="vehicle-loadout-crafting"
  >
    <div class="loadout-crafting__head">
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        :active="!!crafted"
        :aria-pressed="!!crafted"
        data-test="vehicle-loadout-crafted-toggle"
        @click="toggle"
      >
        <i class="fa-solid fa-hammer" aria-hidden="true" />
        {{ t("labels.vehicleLoadout.crafting.toggle") }}
      </Btn>
      <span
        v-if="crafted && summary"
        class="loadout-crafting__summary"
        data-test="vehicle-loadout-crafting-summary"
      >
        {{ summary }}
      </span>
      <Btn
        v-if="crafted"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :aria-expanded="open"
        class="loadout-crafting__expand"
        data-test="vehicle-loadout-crafting-expand"
        @click="open = !open"
      >
        {{
          open
            ? t("labels.vehicleLoadout.crafting.hideQualities")
            : t("labels.vehicleLoadout.crafting.showQualities")
        }}
      </Btn>
    </div>

    <div
      v-if="crafted && open"
      class="loadout-crafting__body"
      data-test="vehicle-loadout-crafting-slots"
    >
      <div v-if="costSlots.length" class="loadout-crafting__quickset">
        <span>{{ t("labels.blueprint.setEverySlot") }}</span>
        <Btn
          v-for="preset in PRESETS"
          :key="preset"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          :data-test="`vehicle-loadout-crafting-preset-${preset}`"
          @click="setEveryQuality(preset)"
        >
          {{ preset }}
        </Btn>
      </div>

      <BlueprintSlot
        v-for="slot in costSlots"
        :key="slot.position"
        :slot-data="slot"
        :quality="qualityFor(slot.position)"
        @update:quality="setQuality(slot.position, $event)"
      />
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
