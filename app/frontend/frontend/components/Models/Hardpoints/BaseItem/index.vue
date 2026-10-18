<script lang="ts">
export default {
  name: "HardpointBaseItem",
};
</script>

<script lang="ts" setup>
import { groupIntoStacks } from "@/frontend/components/Models/Hardpoints/stacks";
import { partContents } from "@/frontend/components/Models/Hardpoints/contents";
import { rowPresentation } from "@/frontend/components/Models/Hardpoints/rowPresentation";
import { useHardpointStack } from "@/frontend/components/Models/Hardpoints/useHardpointStack";
import HardpointStackToggle from "@/frontend/components/Models/Hardpoints/StackToggle/index.vue";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
// eslint-disable-next-line import/no-self-import
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import HardpointHeadline from "@/frontend/components/Models/Hardpoints/Headline/index.vue";
import HardpointManufacturer from "@/frontend/components/Models/Hardpoints/Manufacturer/index.vue";
import HardpointStats from "@/frontend/components/Models/Hardpoints/Stats/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { useHardpointStats } from "@/frontend/composables/useHardpointStats";
import {
  HardpointSourceEnum,
  HardpointCategoryEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoints: Hardpoint[];
  intended?: boolean;
  collapsible?: boolean;
  // Number of identical parent stacks this loadout sits under, so nested DPS
  // totals reflect every copy of the item across the stacked spot.
  countMultiplier?: number;
};

const props = withDefaults(defineProps<Props>(), {
  intended: false,
  collapsible: false,
  countMultiplier: 1,
});

const emit = defineEmits<{ toggle: [] }>();

const { t, toNumber } = useI18n();

const { isGroup, stackExpanded, toggleExpanded, onRowClick } =
  useHardpointStack(
    () => props.hardpoints,
    () => props.collapsible,
    () => emit("toggle"),
  );

// What sits inside the part -- a turret's guns, a rack's missiles -- shown
// until folded away, as the loadout editor does. Its category folds them all
// at once; a row's own chevron still opens or folds it alone afterwards.
const partsFolded = inject<Ref<boolean>>("hardpointPartsFolded", ref(false));

const childrenOpen = ref(!partsFolded.value);

watch(partsFolded, (value) => {
  childrenOpen.value = !value;
});

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const count = computed(() => {
  return props.hardpoints.length;
});

// Total copies of this item across the stacked spot: its own stack size times
// any stacked parent (e.g. a gimbal mount present ×4 that each hold this gun).
const effectiveCount = computed(() => count.value * props.countMultiplier);

// The single primary stat is promoted to a right-aligned gold headline; the
// remaining stats render inline on the card.
const detailStats = useHardpointStats(
  () => hardpoint.value,
  () => effectiveCount.value,
);
const primaryStat = computed(() => detailStats.value.find((s) => s.primary));

// What this kind of hardpoint shows in place of a part's name and figures.
const presentation = computed(() => rowPresentation(hardpoint.value.category));

const presentedLabel = computed(() =>
  presentation.value.label?.(hardpoint.value, t),
);

const headline = computed(() => {
  if (presentation.value.headline) {
    return presentation.value.headline(hardpoint.value, t, toNumber);
  }

  return primaryStat.value
    ? { value: primaryStat.value.value, unit: primaryStat.value.label }
    : undefined;
});

// A consumer that repeats this row across many columns — the compare table — can cap the
// strip so a cell shows the key metrics instead of the component's whole stat set. The
// gold headline is never capped; it is the key figure.
const statLimit = inject<number | undefined>("hardpointStatLimit", undefined);

// A named game-files component opens its stats card from the name, and the
// card lists every figure, so the row keeps to the ones its type ranks. A row
// without a card is the only place its figures appear and keeps them all --
// as is one whose kind shows a label in place of the name.
const hasStatsCard = computed(
  () =>
    hardpoint.value.source === HardpointSourceEnum.GAME_FILES &&
    !!hardpoint.value.component?.name &&
    !presentedLabel.value,
);

// Everything except the headline, rather than everything not flagged key. A
// category can mark more than one figure key -- a gun marks sustained and burst
// DPS -- and only the first becomes the gold headline, so filtering on the flag
// dropped the others off the row altogether.
const inlineStats = computed(() => {
  if (presentation.value.stats) {
    return presentation.value.stats(hardpoint.value, t, toNumber);
  }

  let stats = detailStats.value.filter((s) => s !== primaryStat.value);

  if (hasStatsCard.value) {
    stats = stats
      .filter((s) => typeof s.row === "number")
      .sort((a, b) => (a.row ?? 0) - (b.row ?? 0));
  }

  return typeof statLimit === "number" ? stats.slice(0, statLimit) : stats;
});

const loadout = computed(() => partContents(hardpoint.value));

const groupedLoadout = computed(() => {
  return groupIntoStacks(loadout.value);
});

const hardpointNames = computed(() => {
  return props.hardpoints
    .map((hp) => {
      return hp.name
        .split("_")
        .join(" ")
        .replace("hardpoint", "")
        .replace(/\b\w/g, (l) => l.toUpperCase());
    })
    .join(", ");
});
</script>

<template>
  <HardpointItem
    v-show="!stackExpanded"
    :count="count"
    :intended="intended"
    :class="{ 'hardpoint-item--clickable': isGroup || collapsible }"
    @click="onRowClick"
  >
    <template v-if="loadout.length" #actions>
      <button
        type="button"
        class="hardpoint-item__ctl"
        :aria-expanded="childrenOpen"
        :aria-label="t(childrenOpen ? 'labels.collapse' : 'labels.expand')"
        data-test="hardpoint-children-toggle"
        @click.stop="childrenOpen = !childrenOpen"
      >
        <i
          class="fa-solid"
          :class="childrenOpen ? 'fa-chevron-up' : 'fa-chevron-down'"
          aria-hidden="true"
        />
      </button>
    </template>
    <!-- The rest of the row toggles the stack too. -->
    <template v-if="isGroup || collapsible" #stack>
      <HardpointStackToggle :split="collapsible" @toggle="onRowClick" />
    </template>
    <template #default>
      <HardpointSize v-if="!presentation.sizeless" :size="hardpoint.maxSize" />
      <div class="hardpoint-item__main">
        <HardpointComponent>
          <template v-if="hardpoint.source === HardpointSourceEnum.GAME_FILES">
            <template v-if="presentedLabel">{{ presentedLabel }}</template>
            <template
              v-else-if="hardpoint.component && hardpoint.component.name"
            >
              <!-- The catalogue link. Only when the component has a slug -- one
                   without a name never got one, and a link to nowhere is worse
                   than plain text -- and only when the catalogue actually
                   carries it: doors, subsystem controllers, seats and the
                   uncategorised are fitted by the shipwright rather than the
                   player, and a link here would be a way into a page the
                   catalogue has decided not to list. The server decides that,
                   so the two cannot drift. -->
              <CatalogueItemPopover
                :item="{
                  type: 'Component',
                  slug: hardpoint.component.slug,
                  name: hardpoint.component.name,
                  listed: hardpoint.component.catalogued,
                }"
                :record="hardpoint.component"
              />
              <span v-if="hardpoint.component.itemClass">
                {{ hardpoint.component.itemClassLabel }}
                {{ t("labels.component.grade") }}
                {{ hardpoint.component.gradeLabel }}
              </span>
            </template>
            <template v-else>
              {{ hardpointNames }}
              <span v-if="!loadout.length">TBD</span>
            </template>
          </template>
          <template v-else>
            <template
              v-if="
                (hardpoint.category !== HardpointCategoryEnum.TURRET &&
                  hardpoint.category !== HardpointCategoryEnum.MISSILE_RACKS) ||
                intended
              "
            >
              {{ hardpoint.name }}
            </template>
            <span v-if="hardpoint.details">
              {{ hardpoint.details }}
            </span>
          </template>
        </HardpointComponent>
        <HardpointManufacturer
          :manufacturer="hardpoint.component?.manufacturer"
        />
      </div>
      <HardpointHeadline
        v-if="headline"
        :value="headline.value"
        :unit="headline.unit"
      />
      <HardpointStats :stats="inlineStats" />
    </template>
    <template #loadout>
      <Collapsed v-if="loadout.length" :visible="childrenOpen" :duration="200">
        <div class="hardpoint-item__loadout">
          <HardpointBaseItem
            v-for="(items, key) in groupedLoadout"
            :key="key"
            :hardpoints="items"
            :count-multiplier="effectiveCount"
            intended
          />
        </div>
      </Collapsed>
    </template>
  </HardpointItem>

  <Collapsed v-if="isGroup" :visible="stackExpanded" :duration="200">
    <HardpointBaseItem
      v-for="hp in hardpoints"
      :key="hp.id"
      :hardpoints="[hp]"
      :intended="intended"
      collapsible
      @toggle="toggleExpanded"
    />
  </Collapsed>
</template>

<style lang="scss" scoped>
@import "index";
</style>
