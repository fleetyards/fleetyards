<script lang="ts">
export default {
  name: "BlueprintCrafter",
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
import type { CraftedPart } from "@/frontend/composables/craftedComponent";
import { useCraftedStats } from "@/frontend/composables/useCraftedStats";
import { useMaterialStockUpdates } from "@/frontend/composables/useMaterialStock";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import {
  BlueprintCraftableTypeEnum,
  useBlueprint,
  useBlueprints,
} from "@/services/fyApi";

/*
 * Crafting one item: the recipe that makes it and the material quality in each
 * of its slots, worked on as a draft that reaches the caller only on Apply.
 * The caller places it -- a loadout's socket, an inventory's item picker --
 * and decides what applying means there.
 */
type Props = {
  // What it is crafted for, such as the slot the item sits in.
  title: string;
  // The item as catalogued.
  item: { id: string; name: string; slug?: string | null };
  // Which catalogue the item is in, which the recipes are looked up by.
  craftableType?: BlueprintCraftableTypeEnum;
  // How the item is crafted now, if it is: the draft starts from it, and it
  // can be taken back.
  crafted?: CraftedPart;
  // Inside a host whose own footer carries the actions, such as a modal's
  // docked plate: the crafter shows no header or footer of its own, leaves
  // Escape to the host, and is driven through what it exposes.
  embedded?: boolean;
  // For a request rather than a record: a slot left untouched takes any
  // grade, and a set one can be cleared back to that. Without it, applying
  // states a grade for every slot that moves a stat.
  openSlots?: boolean;
  // Fills its containing block instead of sitting in the page as a panel, for
  // a phone, where there is no room beside the sockets.
  sheet?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  craftableType: BlueprintCraftableTypeEnum.COMPONENT,
  crafted: undefined,
  embedded: false,
  openSlots: false,
  sheet: false,
});

const emit = defineEmits<{
  apply: [crafted: CraftedPart];
  remove: [];
  close: [];
}>();

// Copied by hand: the caller's crafting can hold reactive grades, which
// structuredClone refuses, and a toRaw only unwraps the outer object.
const draft = ref<CraftedPart | undefined>(
  props.crafted
    ? { ...props.crafted, qualities: { ...props.crafted.qualities } }
    : undefined,
);

const { t } = useI18n();

const { data: recipesData, isPending: recipesPending } = useBlueprints(
  () => ({
    q: {
      craftableTypeEq: props.craftableType,
      craftableIdEq: props.item.id,
    },
  }),
  { query: { enabled: () => !!props.item.id } },
);

const recipes = computed(() => recipesData.value?.items ?? []);

// The slots mark the material grades held, which an inventory change while
// the crafter is open would otherwise leave stale.
useMaterialStockUpdates();

// A crafted item opens on how it was crafted -- a recipe a new build dropped
// included, which the list no longer names. An item not crafted yet opens as
// crafted from its first recipe, every slot at the neutral grade, as soon as
// the recipe list says which that is.
watch(
  () => recipes.value[0],
  (first) => {
    if (draft.value || !first) return;

    draft.value = {
      blueprintId: first.id,
      blueprintSlug: first.slug,
      qualities: {},
    };
  },
  { immediate: true },
);

const { data: blueprint } = useBlueprint(
  () => draft.value?.blueprintSlug ?? "",
  { query: { enabled: () => !!draft.value } },
);

const costSlots = computed(() => blueprint.value?.costSlots ?? []);

const qualityFor = (position: number) =>
  draft.value?.qualities[position] ?? NEUTRAL_QUALITY;

// Every stat the recipe moves, as the blueprint page composes them -- a
// part's integrity included, which a loadout's own figures never read.
const { stats } = useCraftedStats(costSlots, qualityFor);

// Another recipe has other slots, so its qualities start over.
const chooseRecipe = (blueprintId: string) => {
  const chosen = recipes.value.find((entry) => entry.id === blueprintId);
  if (!chosen || chosen.id === draft.value?.blueprintId) return;

  draft.value = {
    blueprintId: chosen.id,
    blueprintSlug: chosen.slug,
    qualities: {},
  };
};

const setQuality = (position: number, quality: number) => {
  if (!draft.value) return;

  draft.value = {
    ...draft.value,
    qualities: { ...draft.value.qualities, [position]: quality },
  };
};

const isOpen = (position: number) =>
  props.openSlots && !(position in (draft.value?.qualities ?? {}));

const clearQuality = (position: number) => {
  if (!draft.value) return;

  const { [position]: _cleared, ...qualities } = draft.value.qualities;
  draft.value = { ...draft.value, qualities };
};

// A record states every grade that went in, the neutral one included; only a
// request leaves a slot open.
const settled = computed<CraftedPart | undefined>(() => {
  if (!draft.value || props.openSlots) return draft.value;

  return {
    ...draft.value,
    qualities: Object.fromEntries(
      costSlots.value
        .filter((slot) => slot.modifiers?.length)
        .map((slot) => [slot.position, qualityFor(slot.position)]),
    ),
  };
});

// Its slots are known once the recipe is in, which a record's grades need.
const canApply = computed(
  () => !!draft.value && (props.openSlots || !!blueprint.value),
);

const apply = () => {
  if (canApply.value && settled.value) emit("apply", settled.value);
};

const remove = () => {
  emit("remove");
};

// The draft is only ever applied or discarded on purpose, so a press elsewhere
// -- a material's popover, the caller's own save -- leaves the crafter open.
const root = ref<HTMLElement>();

const onKeydown = (event: KeyboardEvent) => {
  if (props.embedded) return;
  if (event.key !== "Escape" || event.defaultPrevented) return;

  event.stopPropagation();
  emit("close");
};

const focus = () => {
  root.value?.focus();
};

defineExpose({ focus, apply, remove, canApply });
</script>

<template>
  <section
    ref="root"
    class="blueprint-crafter"
    :class="{
      'blueprint-crafter--embedded': embedded,
      'blueprint-crafter--sheet': sheet,
    }"
    data-test="blueprint-crafter"
    :aria-label="t('labels.blueprint.crafter.title', { name: title })"
    tabindex="-1"
    @keydown="onKeydown"
  >
    <header v-if="!embedded" class="blueprint-crafter__header">
      <h4 class="blueprint-crafter__title">
        {{ t("labels.blueprint.crafter.title", { name: title }) }}
      </h4>
      <button
        type="button"
        class="blueprint-crafter__close"
        :aria-label="t('labels.loadoutPicker.close')"
        data-test="blueprint-crafter-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-times" aria-hidden="true" />
      </button>
    </header>

    <div class="blueprint-crafter__controls">
      <!-- The catalogue's card on hover, as the part was made rather than
        crafted: the crafted figures are the crafter's own list. No link, which
        would leave an editor with unsaved changes. -->
      <p class="blueprint-crafter__part" data-test="blueprint-crafter-part">
        <CatalogueItemPopover
          :item="{
            type: craftableType,
            slug: item.slug,
            name: item.name,
          }"
          :link="false"
        />
      </p>
      <div v-if="draft && recipes.length > 1" class="blueprint-crafter__row">
        <Btn
          v-for="(entry, index) in recipes"
          :key="entry.id"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          :active="entry.id === draft.blueprintId"
          :aria-pressed="entry.id === draft.blueprintId"
          :data-test="`blueprint-crafter-recipe-${entry.id}`"
          @click="chooseRecipe(entry.id)"
        >
          {{ t("labels.blueprint.crafter.recipe", { number: index + 1 }) }}
        </Btn>
      </div>
    </div>

    <p
      v-if="!draft && !recipesPending"
      class="blueprint-crafter__empty"
      data-test="blueprint-crafter-no-recipe"
    >
      {{ t("labels.blueprint.crafter.noRecipe") }}
    </p>

    <div
      v-if="draft"
      class="blueprint-crafter__slots"
      data-test="blueprint-crafter-slots"
    >
      <BlueprintSlot
        v-for="slot in costSlots"
        :key="slot.position"
        :slot-data="slot"
        :quality="qualityFor(slot.position)"
        :ramps="false"
        :links="false"
        :open="isOpen(slot.position)"
        :clearable="openSlots"
        @update:quality="setQuality(slot.position, $event)"
        @clear="clearQuality(slot.position)"
      />
    </div>

    <dl
      v-if="draft && stats.length"
      class="blueprint-crafter__stats"
      data-test="blueprint-crafter-stats"
    >
      <div
        v-for="stat in stats"
        :key="stat.key"
        class="blueprint-crafter__stat"
        :data-test="`blueprint-crafter-stat-${stat.key}`"
      >
        <dt>{{ stat.name }}</dt>
        <dd>
          <strong>{{ stat.value }}</strong>
          <span
            class="blueprint-crafter__delta"
            :class="`blueprint-crafter__delta--${stat.trend}`"
          >
            {{ stat.delta }}
          </span>
        </dd>
      </div>
    </dl>

    <footer v-if="!embedded" class="blueprint-crafter__actions">
      <Btn
        v-if="crafted"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        :tone="BtnTonesEnum.DANGER"
        class="blueprint-crafter__remove"
        data-test="blueprint-crafter-remove"
        @click="remove"
      >
        {{ t("actions.blueprint.removeCrafting") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="blueprint-crafter-discard"
        @click="emit('close')"
      >
        {{ t("actions.blueprint.discard") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SM"
        :disabled="!canApply"
        data-test="blueprint-crafter-apply"
        @click="apply"
      >
        {{ t("actions.blueprint.apply") }}
      </Btn>
    </footer>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
