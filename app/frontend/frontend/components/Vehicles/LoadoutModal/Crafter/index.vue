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
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { CraftedPart } from "@/frontend/composables/useComponentFitting";
import { useCraftedStats } from "@/frontend/composables/useCraftedStats";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import {
  type BlueprintCostSlot,
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

const PRESETS = [0, 250, 500, 750, 1000];

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

// A number input reports "" mid-edit -- cleared, or a lone "-" -- and
// Number("") is 0, which would slam the slot to zero under the cursor. An
// unparseable value leaves it where it was.
const onQuality = (position: number, event: Event) => {
  const raw = (event.target as HTMLInputElement).value;
  if (raw === "") return;

  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) return;

  setQuality(position, Math.min(Math.max(Math.round(parsed), 0), 1000));
};

// What one slot takes, in a few words: the amount and the material.
const costOf = (slot: BlueprintCostSlot) => {
  const option = slot.options?.[0];
  if (!option) return undefined;

  const quantity = option.quantity;
  const amount =
    quantity === undefined || quantity === null
      ? undefined
      : option.type === "resource"
        ? t("labels.blueprint.scu", { amount: quantity })
        : t("labels.blueprint.pieces", { count: Math.round(quantity) });

  return [amount, option.commodity?.name ?? option.commodityKey]
    .filter(Boolean)
    .join(" ");
};

// Only a real gate: 4,267 of the 4,289 slots ask for 0 or 1.
const gateOf = (slot: BlueprintCostSlot) => {
  const min = slot.options?.[0]?.minQuality;

  return min === undefined || min === null || min <= 1 ? undefined : min;
};

const setEveryQuality = (quality: number) => {
  if (!props.draft) return;

  emit("update:draft", {
    ...props.draft,
    qualities: Object.fromEntries(
      costSlots.value.map((slot) => [slot.position, quality]),
    ),
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

      <div
        v-if="draft && costSlots.length"
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
      <div
        v-for="slot in costSlots"
        :key="slot.position"
        class="loadout-crafter__slot"
        :data-test="`vehicle-loadout-crafting-slot-${slot.position}`"
      >
        <div class="loadout-crafter__slot-head">
          <span class="loadout-crafter__slot-name">{{ slot.name }}</span>
          <span class="loadout-crafter__slot-cost">{{ costOf(slot) }}</span>
        </div>
        <div class="loadout-crafter__slot-quality">
          <input
            type="range"
            min="0"
            max="1000"
            step="1"
            :value="qualityFor(slot.position)"
            :aria-label="`${slot.name} ${t('labels.blueprint.quality')}`"
            @input="onQuality(slot.position, $event)"
          />
          <input
            type="number"
            min="0"
            max="1000"
            step="1"
            :value="qualityFor(slot.position)"
            :aria-label="`${slot.name} ${t('labels.blueprint.quality')}`"
            class="loadout-crafter__slot-number"
            :class="{
              'loadout-crafter__slot-number--below':
                !!gateOf(slot) && qualityFor(slot.position) < gateOf(slot)!,
            }"
            @input="onQuality(slot.position, $event)"
          />
        </div>
        <p
          v-if="gateOf(slot) && qualityFor(slot.position) < gateOf(slot)!"
          class="loadout-crafter__slot-gate"
        >
          {{ t("labels.blueprint.belowGate", { quality: gateOf(slot) }) }}
        </p>
      </div>
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
