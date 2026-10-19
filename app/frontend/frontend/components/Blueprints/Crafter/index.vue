<script lang="ts">
export default {
  name: "VehicleLoadoutModalCrafter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import BlueprintSlot from "@/frontend/components/Blueprints/Slot/index.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { CraftedPart } from "@/frontend/composables/useComponentFitting";
import { useCraftedStats } from "@/frontend/composables/useCraftedStats";
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
  // The part as catalogued.
  component: LoadoutComponentRef;
  // The crafting being worked on, which reaches the loadout only on Apply.
  draft?: CraftedPart;
  // Whether the loadout already holds the part as crafted, which can then be
  // taken back.
  crafted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  draft: undefined,
  crafted: false,
});

const emit = defineEmits<{
  "update:draft": [value: CraftedPart];
  apply: [];
  remove: [];
  close: [];
}>();

const { t } = useI18n();

const { data: recipesData, isPending: recipesPending } = useBlueprints(
  () => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.COMPONENT,
      craftableIdEq: props.component.id,
    },
  }),
  { query: { enabled: () => !!props.component.id } },
);

const recipes = computed(() => recipesData.value?.items ?? []);

// A crafted part opens on how it was crafted -- a recipe a new build dropped
// included, which the list no longer names. A part not crafted yet opens as
// crafted from its first recipe, every slot at the neutral grade, as soon as
// the recipe list says which that is.
watch(
  () => recipes.value[0],
  (first) => {
    if (props.draft || !first) return;

    emit("update:draft", {
      blueprintId: first.id,
      blueprintSlug: first.slug,
      qualities: {},
    });
  },
  { immediate: true },
);

const { data: blueprint } = useBlueprint(
  () => props.draft?.blueprintSlug ?? "",
  { query: { enabled: () => !!props.draft } },
);

const costSlots = computed(() => blueprint.value?.costSlots ?? []);

const qualityFor = (position: number) =>
  props.draft?.qualities[position] ?? NEUTRAL_QUALITY;

// Every stat the recipe moves, as the blueprint page composes them -- those a
// loadout's figures never read, such as a part's integrity, included.
const { stats } = useCraftedStats(costSlots, qualityFor);

// Another recipe has other slots, so its qualities start over.
const chooseRecipe = (blueprintId: string) => {
  const chosen = recipes.value.find((entry) => entry.id === blueprintId);
  if (!chosen || chosen.id === props.draft?.blueprintId) return;

  emit("update:draft", {
    blueprintId: chosen.id,
    blueprintSlug: chosen.slug,
    qualities: {},
  });
};

const setQuality = (position: number, quality: number) => {
  if (!props.draft) return;

  emit("update:draft", {
    ...props.draft,
    qualities: { ...props.draft.qualities, [position]: quality },
  });
};

// The draft is only ever applied or discarded on purpose, so unlike the
// picker a press elsewhere -- a material's popover, the modal's own save --
// leaves the crafter open.
const root = ref<HTMLElement>();

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
      <!-- The catalogue's card on hover, as the part was made rather than
        crafted: the crafted figures are the crafter's own list. No link, which
        would leave an editor with unsaved changes. -->
      <p class="loadout-crafter__part" data-test="vehicle-loadout-crafter-part">
        <CatalogueItemPopover
          :item="{
            type: 'Component',
            slug: component.slug,
            name: component.name,
          }"
          :link="false"
        />
      </p>
      <div v-if="draft && recipes.length > 1" class="loadout-crafter__row">
        <Btn
          v-for="(entry, index) in recipes"
          :key="entry.id"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          :active="entry.id === draft.blueprintId"
          :aria-pressed="entry.id === draft.blueprintId"
          :data-test="`vehicle-loadout-crafting-recipe-${entry.id}`"
          @click="chooseRecipe(entry.id)"
        >
          {{
            t("labels.vehicleLoadout.crafting.recipe", { number: index + 1 })
          }}
        </Btn>
      </div>
    </div>

    <p
      v-if="!draft && !recipesPending"
      class="loadout-crafter__empty"
      data-test="vehicle-loadout-crafter-no-recipe"
    >
      {{ t("labels.vehicleLoadout.crafting.noRecipe") }}
    </p>

    <div
      v-if="draft"
      class="loadout-crafter__slots"
      data-test="vehicle-loadout-crafting-slots"
    >
      <BlueprintSlot
        v-for="slot in costSlots"
        :key="slot.position"
        :slot-data="slot"
        :quality="qualityFor(slot.position)"
        :ramps="false"
        @update:quality="setQuality(slot.position, $event)"
      />
    </div>

    <dl
      v-if="draft && stats.length"
      class="loadout-crafter__stats"
      data-test="vehicle-loadout-crafter-stats"
    >
      <div
        v-for="stat in stats"
        :key="stat.key"
        class="loadout-crafter__stat"
        :data-test="`vehicle-loadout-crafter-stat-${stat.key}`"
      >
        <dt>{{ stat.name }}</dt>
        <dd>
          <strong>{{ stat.value }}</strong>
          <span
            class="loadout-crafter__delta"
            :class="`loadout-crafter__delta--${stat.trend}`"
          >
            {{ stat.delta }}
          </span>
        </dd>
      </div>
    </dl>

    <footer class="loadout-crafter__actions">
      <Btn
        v-if="crafted"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        :tone="BtnTonesEnum.DANGER"
        class="loadout-crafter__remove"
        data-test="vehicle-loadout-crafter-remove"
        @click="emit('remove')"
      >
        {{ t("actions.vehicleLoadout.removeCrafting") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="vehicle-loadout-crafter-discard"
        @click="emit('close')"
      >
        {{ t("actions.vehicleLoadout.discardCrafting") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SM"
        :disabled="!draft"
        data-test="vehicle-loadout-crafter-apply"
        @click="emit('apply')"
      >
        {{ t("actions.vehicleLoadout.applyCrafting") }}
      </Btn>
    </footer>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
