<script lang="ts">
export default {
  name: "VehicleLoadoutModalCrafter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import BlueprintSlot from "@/frontend/components/Blueprints/Slot/index.vue";
import ComponentComparison from "../ComponentComparison/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  CraftedPart,
  FigureChange,
} from "@/frontend/composables/useComponentFitting";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import {
  BlueprintCraftableTypeEnum,
  type LoadoutComponentRef,
  useBlueprint,
  useBlueprints,
} from "@/services/fyApi";

type Props = {
  // The slot the part sits in.
  title: string;
  // The part as catalogued, and as crafted at the qualities chosen.
  component: LoadoutComponentRef;
  crafted?: CraftedPart;
  // How the crafted part's figures differ from the catalogued one's.
  comparison: {
    from?: LoadoutComponentRef;
    to?: LoadoutComponentRef;
    rows: FigureChange[];
  };
};

const props = withDefaults(defineProps<Props>(), {
  crafted: undefined,
});

const emit = defineEmits<{
  "update:crafted": [value: CraftedPart | undefined];
  close: [];
}>();

const { t } = useI18n();

const PRESETS = [0, 250, 500, 750, 1000];

const { data: recipesData } = useBlueprints(
  () => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.COMPONENT,
      craftableIdEq: props.component.id,
    },
  }),
  { query: { enabled: () => !!props.component.id } },
);

const recipes = computed(() => recipesData.value?.items ?? []);

// Three parts have two recipes, each with its own slots; the one it was
// crafted from stays chosen.
//
// A saved crafting whose recipe a new build dropped is no longer in the list,
// and still has to be shown -- and undone.
const recipe = computed(() => {
  const crafted = props.crafted;

  return (
    recipes.value.find((entry) => entry.id === crafted?.blueprintId) ??
    (crafted
      ? { id: crafted.blueprintId, slug: crafted.blueprintSlug }
      : recipes.value[0])
  );
});

const { data: blueprint } = useBlueprint(
  () => props.crafted?.blueprintSlug ?? "",
  { query: { enabled: () => !!props.crafted } },
);

const costSlots = computed(() => blueprint.value?.costSlots ?? []);

const qualityFor = (position: number) =>
  props.crafted?.qualities[position] ?? NEUTRAL_QUALITY;

const toggle = () => {
  if (props.crafted) {
    emit("update:crafted", undefined);
    return;
  }

  if (!recipe.value) return;

  emit("update:crafted", {
    blueprintId: recipe.value.id,
    blueprintSlug: recipe.value.slug,
    qualities: {},
  });
};

// Another recipe has other slots, so its qualities start over.
const chooseRecipe = (blueprintId: string) => {
  const chosen = recipes.value.find((entry) => entry.id === blueprintId);
  if (!chosen || chosen.id === props.crafted?.blueprintId) return;

  emit("update:crafted", {
    blueprintId: chosen.id,
    blueprintSlug: chosen.slug,
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

const root = ref<HTMLElement>();

/*
 * As the picker: a press anywhere else closes it, except on a socket, which
 * switches what it is open for. Captured, so a control that stops the event on
 * its way up still counts.
 */
const onDocumentPointerdown = (event: PointerEvent) => {
  const target = event.target as Element | null;
  if (!target || root.value?.contains(target)) return;
  if (target.closest?.(".loadout-socket")) return;

  emit("close");
};

onMounted(() => {
  document.addEventListener("pointerdown", onDocumentPointerdown, true);
});

onBeforeUnmount(() => {
  document.removeEventListener("pointerdown", onDocumentPointerdown, true);
});

const onKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Escape" || event.defaultPrevented) return;

  event.stopPropagation();
  emit("close");
};

const focus = () => {
  root.value?.focus();
};

defineExpose({ focus });
</script>

<template>
  <section
    ref="root"
    class="loadout-crafter"
    data-test="vehicle-loadout-crafter"
    :aria-label="t('labels.vehicleLoadout.crafting.title', { name: title })"
    tabindex="-1"
    @keydown="onKeydown"
  >
    <header class="loadout-crafter__header">
      <h4 class="loadout-crafter__title">
        {{ t("labels.vehicleLoadout.crafting.title", { name: title }) }}
      </h4>
      <button
        type="button"
        class="loadout-crafter__close"
        :aria-label="t('labels.loadoutPicker.close')"
        data-test="vehicle-loadout-crafter-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-times" aria-hidden="true" />
      </button>
    </header>

    <div class="loadout-crafter__controls">
      <p class="loadout-crafter__part">{{ component.name }}</p>
      <div class="loadout-crafter__row">
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          :active="!!crafted"
          :aria-pressed="!!crafted"
          :disabled="!recipe"
          data-test="vehicle-loadout-crafted-toggle"
          @click="toggle"
        >
          <i class="fa-solid fa-hammer" aria-hidden="true" />
          {{ t("labels.vehicleLoadout.crafting.toggle") }}
        </Btn>
        <template v-if="crafted && recipes.length > 1">
          <Btn
            v-for="(entry, index) in recipes"
            :key="entry.id"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.GHOST"
            :active="entry.id === crafted.blueprintId"
            :aria-pressed="entry.id === crafted.blueprintId"
            :data-test="`vehicle-loadout-crafting-recipe-${entry.id}`"
            @click="chooseRecipe(entry.id)"
          >
            {{
              t("labels.vehicleLoadout.crafting.recipe", { number: index + 1 })
            }}
          </Btn>
        </template>
      </div>

      <div
        v-if="crafted && costSlots.length"
        class="loadout-crafter__row loadout-crafter__quickset"
      >
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
    </div>

    <div
      v-if="crafted"
      class="loadout-crafter__slots"
      data-test="vehicle-loadout-crafting-slots"
    >
      <BlueprintSlot
        v-for="slot in costSlots"
        :key="slot.position"
        :slot-data="slot"
        :quality="qualityFor(slot.position)"
        @update:quality="setQuality(slot.position, $event)"
      />
    </div>
    <p
      v-else
      class="loadout-crafter__hint"
      data-test="vehicle-loadout-crafter-hint"
    >
      {{ t("labels.vehicleLoadout.crafting.hint") }}
    </p>

    <div v-if="comparison.rows.length" class="loadout-crafter__comparison">
      <ComponentComparison v-bind="comparison" />
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
