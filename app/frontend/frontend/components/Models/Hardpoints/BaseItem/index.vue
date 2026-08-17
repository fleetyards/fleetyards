<script lang="ts">
export default {
  name: "HardpointBaseItem",
};
</script>

<script lang="ts" setup>
import { groupBy } from "@/shared/utils/Array";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
// eslint-disable-next-line import/no-self-import
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import HardpointHeadline from "@/frontend/components/Models/Hardpoints/Headline/index.vue";
import HardpointManufacturer from "@/frontend/components/Models/Hardpoints/Manufacturer/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
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

const { t } = useI18n();

const density = inject<Ref<"compact" | "expanded">>(
  "hardpointDensity",
  ref("compact"),
);

const expanded = ref(density.value === "expanded");

watch(density, (value) => {
  expanded.value = value === "expanded";
});

const isGroup = computed(() => {
  return props.hardpoints.length > 1;
});

const toggleExpanded = () => {
  expanded.value = !expanded.value;
};

// Only a real stack (>1 identical mount) collapses to a summary row; single
// items always render, even when the global density is "expanded".
const stackExpanded = computed(() => isGroup.value && expanded.value);

const onRowClick = () => {
  if (props.collapsible) {
    emit("toggle");
  } else if (isGroup.value) {
    toggleExpanded();
  }
};

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const count = computed(() => {
  return props.hardpoints.length;
});

// Total copies of this item across the stacked spot: its own stack size times
// any stacked parent (e.g. a gimbal mount present ×4 that each hold this gun).
const effectiveCount = computed(() => count.value * props.countMultiplier);

// The single primary stat is promoted to a right-aligned gold headline; every
// remaining stat renders inline on the card — there is no separate details
// panel, so the row surfaces the component's full stat set.
const detailStats = useHardpointStats(
  () => hardpoint.value,
  () => effectiveCount.value,
);
const primaryStat = computed(() => detailStats.value.find((s) => s.primary));

// A consumer that repeats this row across many columns — the compare table — can cap the
// strip so a cell shows the key metrics instead of the component's whole stat set. The
// gold headline is never capped; it is the key figure. Unset means "show everything",
// which is what the ship page wants.
const statLimit = inject<number | undefined>("hardpointStatLimit", undefined);

const inlineStats = computed(() => {
  const stats = detailStats.value.filter((s) => !s.primary);

  return typeof statLimit === "number" ? stats.slice(0, statLimit) : stats;
});

// Cosmetic geometry (turret shells, weapon shrouds, wingtip covers) sits on
// child ports as nameless `Misc`/`AttachedPart` items that stay uncategorised —
// they'd render as bare "TBD" rows, unlike a genuinely empty slot, which keeps
// its category.
const isCosmetic = (hp: Hardpoint) =>
  hp.category === HardpointCategoryEnum.UNKNOWN && !hp.component?.name;

const loadout = computed(() => {
  if (hardpoint.value.hardpoints?.length) {
    return hardpoint.value.hardpoints.filter((hp) => !isCosmetic(hp));
  }

  if (
    hardpoint.value.component?.hardpoints?.length &&
    hardpoint.value.component.hardpoints[0].component
  ) {
    return hardpoint.value.component.hardpoints.filter((hp) => !isCosmetic(hp));
  }

  return [];
});

const groupedLoadout = computed(() => {
  return groupBy<Hardpoint>(loadout.value, "groupKey");
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
    <template v-if="isGroup || collapsible" #actions>
      <span class="hardpoint-item__controls">
        <i
          class="fa-solid hardpoint-item__ctl hardpoint-stack-chevron"
          :class="collapsible ? 'fa-chevron-up' : 'fa-chevron-down'"
        />
      </span>
    </template>
    <template #default>
      <HardpointSize :size="hardpoint.maxSize" />
      <div class="hardpoint-item__main">
        <HardpointComponent>
          <template v-if="hardpoint.source === HardpointSourceEnum.GAME_FILES">
            <template v-if="hardpoint.component && hardpoint.component.name">
              {{ hardpoint.component.name }}
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
        <div v-if="inlineStats.length" class="hardpoint-item__stats">
          <span
            v-for="(s, i) in inlineStats"
            :key="i"
            class="hardpoint-item__stat"
          >
            <span class="hardpoint-item__stat-k">{{ s.label }}</span>
            <span class="hardpoint-item__stat-v">{{ s.value }}</span>
          </span>
        </div>
      </div>
      <HardpointHeadline
        v-if="primaryStat"
        :value="primaryStat.value"
        :unit="primaryStat.label"
      />
    </template>
    <template #loadout>
      <div v-if="loadout.length" class="hardpoint-item__loadout">
        <HardpointBaseItem
          v-for="(items, key) in groupedLoadout"
          :key="key"
          :hardpoints="items"
          :count-multiplier="effectiveCount"
          intended
        />
      </div>
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
