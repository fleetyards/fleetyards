<script lang="ts">
export default {
  name: "HardpointsMinimalRow",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import {
  humanize,
  rowPresentation,
} from "@/frontend/components/Models/Hardpoints/rowPresentation";
import {
  slotId,
  type EquippedModules,
} from "@/frontend/composables/useEquippedHardpoints";
import { useHardpointStats } from "@/frontend/composables/useHardpointStats";
import {
  HardpointCategoryEnum,
  HardpointSourceEnum,
  type ComponentThruster,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type MinimalRow } from "../rows";

interface Props {
  row: MinimalRow;
}

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const hardpoint = computed(() => props.row.hardpoints[0]);

const count = computed(() => props.row.hardpoints.length);

const fromGameFiles = computed(
  () => hardpoint.value.source === HardpointSourceEnum.GAME_FILES,
);

const equippedModules = inject<Ref<EquippedModules>>(
  "equippedModules",
  ref({}),
);

const presentation = computed(() => rowPresentation(hardpoint.value.category));

// A count of one: the figure beside "×2" is for one part, so a reader never has
// to work out whether it was multiplied already.
const stats = useHardpointStats(
  () => hardpoint.value,
  () => 1,
);

const label = computed(() => {
  if (props.row.total) {
    return t(`labels.hardpoint.categories.${hardpoint.value.category}`);
  }

  // A picked module hangs its contents off the slot and leaves the slot's own
  // component as it was, so only the pick knows the module's name.
  const picked =
    hardpoint.value.category === HardpointCategoryEnum.MODULE
      ? equippedModules.value[slotId(hardpoint.value)]
      : undefined;

  return picked?.name ?? presentation.value.label?.(hardpoint.value, t);
});

// A total row can fold thrusters of several sizes, and then no one badge is true.
const size = computed(() => {
  if (presentation.value.sizeless) return undefined;

  const [first, ...others] = props.row.hardpoints.map(({ maxSize }) => maxSize);

  return others.every((other) => other === first) ? first : undefined;
});

// A value carrying its own unit ("3 200 DMG") needs no label after it.
const endsInUnit = (value: string) => /[^\d\s .,]$/.test(value);

const figure = computed(() => {
  if (props.row.total) {
    const thrust = props.row.hardpoints.reduce(
      (sum, { component }) =>
        sum + ((component?.typeData as ComponentThruster)?.thrustCapacity ?? 0),
      0,
    );

    return {
      value: String(toNumber(thrust, "thrust")),
      unit: t("labels.hardpoints.total"),
    };
  }

  if (presentation.value.headline) {
    return presentation.value.headline(hardpoint.value, t, toNumber);
  }

  // The metrics row leads with burst DPS, so gun rows add up to that figure.
  const stat =
    stats.value.find(({ key }) => key === "weapons.burstDps") ??
    stats.value.find(({ primary }) => primary);

  return stat && { value: stat.value, unit: stat.label };
});

const unit = computed(() => {
  if (!figure.value || props.row.total) {
    return figure.value?.unit;
  }

  return endsInUnit(figure.value.value) ? undefined : figure.value.unit;
});
</script>

<template>
  <div class="minimal-row" data-test="hardpoints-minimal-row">
    <span v-if="size" class="minimal-row__size"> S{{ size }} </span>
    <span class="minimal-row__name">
      <template v-if="!fromGameFiles">
        {{ hardpoint.name }}
        <span v-if="hardpoint.details" class="minimal-row__grade">
          {{ hardpoint.details }}
        </span>
      </template>
      <template v-else-if="label">{{ label }}</template>
      <template v-else-if="hardpoint.component?.name">
        <CatalogueItemPopover
          :item="{
            type: 'Component',
            slug: hardpoint.component.slug,
            name: hardpoint.component.name,
            listed: hardpoint.component.catalogued,
          }"
          :record="hardpoint.component"
        />
        <span v-if="hardpoint.component.itemClass" class="minimal-row__grade">
          {{ hardpoint.component.itemClassLabel }}
          {{ hardpoint.component.gradeLabel }}
        </span>
      </template>
      <template v-else>
        {{ humanize(hardpoint.name) }}
        <span class="minimal-row__grade">TBD</span>
      </template>
    </span>
    <span v-if="count > 1" class="minimal-row__count">×{{ count }}</span>
    <span v-if="figure" class="minimal-row__figure">
      <span class="minimal-row__value">{{ figure.value }}</span>
      <span v-if="unit" class="minimal-row__unit">{{ unit }}</span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
.minimal-row {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 30px;

  &__size {
    flex: none;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 30px;
    height: 22px;
    background: var(--color-gray-black);
    border: 1px solid var(--color-edge-soft);
    border-radius: var(--radius-control-bare);
    color: var(--color-lifted);
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.6875rem;
    font-weight: 700;
  }

  &__name {
    flex: 0 1 auto;
    min-width: 0;
    overflow: hidden;
    color: var(--color-lifted);
    font-size: 0.8125rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__grade {
    margin-left: 4px;
    color: var(--color-text-dim);
    font-size: 0.6875rem;
  }

  &__count {
    flex: none;
    color: var(--color-lifted);
    font-size: 0.75rem;
    font-weight: 600;
  }

  &__figure {
    flex: none;
    display: flex;
    align-items: baseline;
    gap: 6px;
    margin-left: auto;
    padding-left: 8px;
  }

  &__value {
    color: var(--color-gold);
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.75rem;
    font-weight: 700;
    font-variant-numeric: tabular-nums;
  }

  &__unit {
    color: var(--color-text-dim);
    font-size: 0.6875rem;
  }
}
</style>
