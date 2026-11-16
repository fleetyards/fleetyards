<script lang="ts">
export default {
  name: "HangarPlannerComparisonDetails",
};
</script>

<script lang="ts" setup>
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import MetricsTable from "@/frontend/components/Hangar/Planner/MetricsTable/index.vue";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanComparison,
  type HangarPlanModel,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
} from "@/services/fyApi";

type Props = {
  comparison: HangarPlanComparison;
  slots?: HangarPlanSlot[];
};

const props = withDefaults(defineProps<Props>(), {
  slots: () => [],
});

const { t } = useI18n();

// What comes into the hangar and what leaves it, ship by ship, so a model
// melted in one place and brought in by a slot shows on both sides even where
// its count stays the same. The biggest moves come first; models the plan
// leaves alone are only counted.
const byMoves = (side: "in" | "out") =>
  props.comparison.models
    .map((diff) => ({
      ...diff,
      moves: side === "in" ? diff.inCount : diff.outCount,
    }))
    .filter((diff) => diff.moves > 0)
    .sort(
      (a, b) => b.moves - a.moves || a.model.name.localeCompare(b.model.name),
    );

type SlotRow = {
  key: string;
  ships: HangarPlanModel[];
  label: string;
};

// A slot still choosing its ship is not counted, so it shows with every ship
// it weighs.
const slotRows = computed<SlotRow[]>(() =>
  props.slots
    .filter((slot) => slot.state === HangarPlanSlotStateEnum.UNDECIDED)
    .map((slot) => ({
      key: `undecided-${slot.id}`,
      ships: slot.candidates.map((candidate) => candidate.model),
      label: slot.label,
    })),
);

const changeColumns = computed(() =>
  (["in", "out"] as const)
    .map((side) => ({
      side,
      rows: byMoves(side),
      slots: side === "in" ? slotRows.value : [],
    }))
    .filter((column) => column.rows.length || column.slots.length),
);

const hasChanges = computed(() => changeColumns.value.length > 0);

const unchangedCount = computed(
  () =>
    props.comparison.models.filter(
      (diff) => diff.inCount === 0 && diff.outCount === 0,
    ).length,
);
</script>

<template>
  <div class="comparison-details">
    <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
      <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
        {{ t("hangarPlanner.comparison.changes") }}
      </PanelHeading>
      <PanelBody>
        <p v-if="!hasChanges" class="comparison-details__muted">
          {{ t("hangarPlanner.comparison.noChanges") }}
        </p>
        <div v-else class="comparison-details__changes">
          <section
            v-for="column in changeColumns"
            :key="column.side"
            class="comparison-details__change-column"
          >
            <h4>
              {{ t(`hangarPlanner.comparison.changeSides.${column.side}`) }}
            </h4>
            <ul>
              <li
                v-for="diff in column.rows"
                :key="diff.model.id"
                data-test="hangar-plan-model-diff"
              >
                <img
                  :src="diff.model.image?.smallUrl || fallbackImage"
                  alt=""
                  class="comparison-details__change-image"
                  loading="lazy"
                />
                <span class="comparison-details__change-text">
                  <strong><ShipName :ship="diff.model" /></strong>
                  <span class="comparison-details__muted">
                    {{ t(`hangarPlanner.changes.${diff.change}`) }} ·
                    {{ diff.leftCount }} → {{ diff.rightCount }}
                  </span>
                </span>
                <span
                  class="comparison-details__change-delta"
                  :class="{
                    'comparison-details__change-delta--out':
                      column.side === 'out',
                  }"
                >
                  {{ column.side === "in" ? "+" : "−" }}{{ diff.moves }}
                </span>
              </li>
              <li
                v-for="slot in column.slots"
                :key="slot.key"
                data-test="hangar-plan-slot-diff"
              >
                <img
                  :src="slot.ships[0]?.image?.smallUrl || fallbackImage"
                  alt=""
                  class="comparison-details__change-image"
                  loading="lazy"
                />
                <span class="comparison-details__change-text">
                  <strong>
                    <template
                      v-for="(ship, index) in slot.ships"
                      :key="ship.id"
                    >
                      <template v-if="index > 0"> / </template>
                      <ShipName :ship="ship" />
                    </template>
                  </strong>
                  <span class="comparison-details__muted">
                    {{ slot.label }} · {{ t("hangarPlanner.states.undecided") }}
                  </span>
                </span>
                <span class="comparison-details__change-delta">+1</span>
              </li>
            </ul>
          </section>
        </div>
        <p
          v-if="hasChanges && unchangedCount"
          class="comparison-details__muted"
        >
          {{
            t("hangarPlanner.comparison.unchangedCount", {
              count: unchangedCount,
            })
          }}
        </p>
      </PanelBody>
    </Panel>

    <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
      <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
        {{ t("hangarPlanner.metrics.title") }}
      </PanelHeading>
      <PanelBody>
        <MetricsTable
          :left="comparison.metrics.live"
          :right="comparison.metrics.plan"
          :left-label="t('hangarPlanner.comparison.hangar')"
          :right-label="t('hangarPlanner.comparison.after')"
        />
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.comparison-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 24px;
}

.comparison-details__changes {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px 24px;
  margin-bottom: 12px;
}

.comparison-details__change-column {
  h4 {
    margin: 0 0 8px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  ul {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  li {
    display: flex;
    gap: 10px;
    align-items: center;
    padding: 6px 8px;
    border: 1px solid var(--color-edge-faint);
    border-radius: 8px;
  }
}

.comparison-details__change-image {
  flex: none;
  width: 56px;
  height: 32px;
  object-fit: cover;
  border-radius: 4px;
}

.comparison-details__change-text {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;

  strong {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: var(--color-lifted);
  }
}

.comparison-details__change-delta {
  padding: 2px 8px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--color-primary) 20%, transparent);
  color: var(--color-primary-tint);
  font-weight: 600;
}

.comparison-details__change-delta--out {
  background: rgba(122, 130, 136, 0.18);
  color: var(--color-text);
}

.comparison-details__muted {
  margin: 0;
  color: var(--color-text-dim);
}
</style>
