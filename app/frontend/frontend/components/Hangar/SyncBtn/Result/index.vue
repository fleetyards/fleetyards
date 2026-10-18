<script lang="ts">
export default {
  name: "HangarSyncResult",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import SyncSteps from "@/frontend/components/Hangar/SyncSteps/index.vue";
import type {
  SyncStep,
  SyncStepStatus,
} from "@/frontend/components/Hangar/SyncSteps/types";
import SyncResultTiles, {
  type SyncResultTile,
} from "@/frontend/components/Hangar/SyncResultTiles/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { RsiHangarItemInput, HangarSyncResult } from "@/services/fyApi";
import type { SyncProcessStep, SyncProcessStepStatus } from "./types";

type Props = {
  processSteps: SyncProcessStep[];
  currentPage: number;
  pledges: RsiHangarItemInput[];
  result?: HangarSyncResult;
  finished: boolean;
  finishedWithErrors: boolean;
  cancelled?: boolean;
  showSupportHint?: boolean;
  syncPaints?: boolean;
  syncHangarFlair?: boolean;
  syncEquipment?: boolean;
  syncCcus?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  result: undefined,
  cancelled: false,
  showSupportHint: false,
  syncPaints: true,
  syncHangarFlair: true,
  syncEquipment: true,
  syncCcus: true,
});

defineEmits<{
  (event: "support-hint-dismiss"): void;
}>();

const { t } = useI18n();

const ITEM_TYPES = [
  "ship",
  "component",
  "upgrade",
  "skin",
  "flair",
  "equipment",
  "ccu",
  "extra",
];

const items = computed(() =>
  props.pledges.filter((pledge) => ITEM_TYPES.includes(pledge.type)),
);

const countOf = (type: string) =>
  props.pledges.filter((pledge) => pledge.type === type).length;

// The sync keeps one row per name in a pledge, with a quantity, so a poster
// listed twice is counted once here too and the two steps agree.
const rowsOf = (type: string) =>
  new Set(
    props.pledges
      .filter((pledge) => pledge.type === type)
      .map((pledge) => `${pledge.id}:${pledge.name.trim()}`),
  ).size;

type ReadCount = {
  key: string;
  label: string;
  count: number;
  dataTest?: string;
};

// What a pledge type the sync leaves out says about itself: it is still
// counted, so the two steps agree, but marked as not synced.
const optional = (
  key: string,
  count: number,
  synced: boolean,
  dataTest: string,
): ReadCount => ({
  key,
  count,
  label: t(
    `labels.syncExtension.pledgeItems.${synced ? key : `${key}NotSynced`}`,
  ),
  dataTest: synced ? undefined : dataTest,
});

const readCounts = computed<ReadCount[]>(() =>
  [
    {
      key: "ships",
      label: t("labels.syncExtension.pledgeItems.ships"),
      count: countOf("ship"),
    },
    {
      key: "components",
      label: t("labels.syncExtension.pledgeItems.components"),
      count: countOf("component"),
    },
    {
      key: "upgrades",
      label: t("labels.syncExtension.pledgeItems.upgrades"),
      count: countOf("upgrade"),
    },
    optional("paints", rowsOf("skin"), props.syncPaints, "paints-not-synced"),
    optional(
      "hangarFlair",
      rowsOf("flair"),
      props.syncHangarFlair,
      "hangar-flair-not-synced",
    ),
    optional(
      "equipment",
      rowsOf("equipment"),
      props.syncEquipment,
      "equipment-not-synced",
    ),
    optional("ccus", rowsOf("ccu"), props.syncCcus, "ccus-not-synced"),
    // Sorted into flair or equipment only once the server stores them.
    {
      key: "extras",
      label: t("labels.syncExtension.pledgeItems.extras"),
      count: rowsOf("extra"),
    },
  ].filter((entry) => entry.count > 0),
);

const STEP_STATUS: Record<SyncProcessStepStatus, SyncStepStatus> = {
  pending: "pending",
  processing: "active",
  success: "done",
  failure: "failed",
  backendFailure: "failed",
};

const stepDetail = (step: SyncProcessStep) => {
  if (step.name === "fetchHangar") {
    if (step.status === "pending") return undefined;

    return step.status === "processing"
      ? t("labels.syncExtension.stepDetails.reading", {
          page: props.currentPage,
          count: items.value.length,
        })
      : t("labels.syncExtension.stepDetails.read", {
          pages: props.currentPage,
          count: items.value.length,
        });
  }

  if (step.status === "processing") {
    return t("labels.syncExtension.stepDetails.saving");
  }

  return undefined;
};

// Neither step knows how far along it is: the hangar's pages are read until
// one comes back empty, and the save is a single request.
const steps = computed<SyncStep[]>(() =>
  props.processSteps.map((step) => ({
    key: step.name,
    label: t(`labels.syncExtension.processSteps.${step.name}`),
    detail: stepDetail(step),
    status: STEP_STATUS[step.status],
    progress: step.status === "processing" ? "indeterminate" : undefined,
  })),
);

const readingDone = computed(
  () =>
    props.processSteps.find((step) => step.name === "fetchHangar")?.status ===
    "success",
);

const failedStep = computed(() =>
  props.processSteps.find(
    (step) => step.status === "failure" || step.status === "backendFailure",
  ),
);

const RESULT_KEYS = [
  "importedVehicles",
  "foundVehicles",
  "movedVehiclesToWanted",
  "deletedVehicles",
  "groupedVehicles",
  "unchangedVehicles",
  "importedComponents",
  "foundComponents",
  "importedUpgrades",
  "foundUpgrades",
  "syncedPaints",
  "syncedHangarFlair",
  "syncedEquipment",
  "syncedCcus",
] as const;

const resultTiles = computed<SyncResultTile[]>(() =>
  RESULT_KEYS.map((key) => ({
    key,
    value: props.result?.[key]?.length ?? 0,
    label: t(`labels.syncExtension.importedItems.${key}`),
  })).filter((tile) => tile.value > 0),
);

const UNMATCHED_KEYS = [
  "missingModels",
  "missingComponents",
  "missingComponentVehicles",
  "missingUpgrades",
  "missingUpgradeVehicles",
] as const;

const unmatchedGroups = computed(() =>
  UNMATCHED_KEYS.map((key) => ({
    key,
    label: t(`labels.syncExtension.importedItems.${key}`),
    items: props.result?.[key] ?? [],
  })).filter((group) => group.items.length > 0),
);

const unmatchedTotal = computed(() =>
  unmatchedGroups.value.reduce((sum, group) => sum + group.items.length, 0),
);

const { prefersReducedMotion } = useReducedMotion();

const collapseDuration = computed(() => (prefersReducedMotion.value ? 1 : 200));

const disclosureId = useId();

const readOpen = ref(false);

// The first group starts open, so the most common miss - a ship it could not
// find - is in view without a click; any group the reader toggles keeps
// their choice.
const toggledGroups = ref<Record<string, boolean>>({});

const groupOpen = (key: string, index: number) =>
  toggledGroups.value[key] ?? index === 0;

const toggleGroup = (key: string, index: number) => {
  toggledGroups.value = {
    ...toggledGroups.value,
    [key]: !groupOpen(key, index),
  };
};

const incomplete = computed(() => !!props.result?.incomplete);

const hasWarnings = computed(
  () => incomplete.value || unmatchedTotal.value > 0,
);
</script>

<template>
  <div class="hangar-sync-result">
    <template v-if="finished">
      <div data-test="sync-result-status">
        <Alert
          v-if="hasWarnings"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          :title="
            unmatchedTotal
              ? t('labels.syncExtension.unmatchedCount', {
                  count: unmatchedTotal,
                })
              : t('labels.syncExtension.warnings')
          "
        >
          <p v-if="unmatchedTotal" class="hangar-sync-result__alert-text">
            {{ t("texts.syncExtension.unmatched") }}
          </p>
          <p
            v-if="incomplete"
            class="hangar-sync-result__alert-text"
            data-test="sync-incomplete"
          >
            {{ t("labels.syncExtension.incomplete") }}
          </p>
        </Alert>
        <Alert
          v-else
          :variant="AlertVariantsEnum.SUCCESS"
          :size="AlertSizesEnum.COMPACT"
        >
          {{ t("texts.syncExtension.finished") }}
        </Alert>
      </div>

      <SyncResultTiles v-if="resultTiles.length" :tiles="resultTiles" />

      <section
        v-if="unmatchedGroups.length"
        class="hangar-sync-result__section"
        data-test="sync-unmatched"
      >
        <h3 class="hangar-sync-result__heading">
          {{ t("labels.syncExtension.unmatchedHeading") }}
        </h3>
        <div class="hangar-sync-result__groups">
          <div
            v-for="(group, index) in unmatchedGroups"
            :key="group.key"
            class="hangar-sync-result__group"
            :data-test="`sync-unmatched-${group.key}`"
          >
            <button
              type="button"
              class="hangar-sync-result__summary"
              :aria-expanded="groupOpen(group.key, index)"
              :aria-controls="`${disclosureId}-${group.key}`"
              @click="toggleGroup(group.key, index)"
            >
              <i
                class="fa-light fa-chevron-right hangar-sync-result__chevron"
                aria-hidden="true"
              />
              <span class="hangar-sync-result__summary-label">
                {{ group.label }}
              </span>
              <span class="hangar-sync-result__count">
                {{ group.items.length }}
              </span>
            </button>
            <Collapsed
              :id="`${disclosureId}-${group.key}`"
              :visible="groupOpen(group.key, index)"
              :duration="collapseDuration"
            >
              <ul class="hangar-sync-result__items">
                <li v-for="item in group.items" :key="`${group.key}-${item}`">
                  {{ item }}
                </li>
              </ul>
            </Collapsed>
          </div>
        </div>
      </section>

      <div class="hangar-sync-result__read" data-test="sync-read">
        <button
          type="button"
          class="hangar-sync-result__summary"
          :aria-expanded="readOpen"
          :aria-controls="`${disclosureId}-read`"
          @click="readOpen = !readOpen"
        >
          <i
            class="fa-light fa-chevron-right hangar-sync-result__chevron"
            aria-hidden="true"
          />
          <span class="hangar-sync-result__summary-label">
            {{ t("labels.syncExtension.readFromRsi") }}
          </span>
          <span class="hangar-sync-result__summary-detail">
            {{
              t("labels.syncExtension.stepDetails.read", {
                pages: currentPage,
                count: items.length,
              })
            }}
          </span>
        </button>
        <Collapsed
          :id="`${disclosureId}-read`"
          :visible="readOpen"
          :duration="collapseDuration"
        >
          <dl class="hangar-sync-result__chips">
            <div
              v-for="entry in readCounts"
              :key="entry.key"
              class="hangar-sync-result__chip"
            >
              <dt :data-test="entry.dataTest">{{ entry.label }}</dt>
              <dd>{{ entry.count }}</dd>
            </div>
          </dl>
        </Collapsed>
      </div>

      <transition name="fade">
        <SupportHint
          v-if="showSupportHint"
          inline
          context="hangarSync"
          :meta="{ count: result?.importedVehicles?.length ?? 0 }"
          @dismiss="$emit('support-hint-dismiss')"
        />
      </transition>
    </template>

    <template v-else>
      <div v-if="finishedWithErrors" data-test="sync-result-status">
        <Alert
          v-if="cancelled"
          :variant="AlertVariantsEnum.NEUTRAL"
          :size="AlertSizesEnum.COMPACT"
          :title="t('labels.syncExtension.status.cancelled')"
        />
        <Alert
          v-else
          :variant="AlertVariantsEnum.DANGER"
          :size="AlertSizesEnum.COMPACT"
          :title="
            failedStep
              ? t(`labels.syncExtension.failedStep.${failedStep.name}`)
              : t('labels.syncExtension.status.failed')
          "
        >
          <template v-if="failedStep?.name === 'submitData'">
            {{ t("texts.syncExtension.partialFailure") }}
          </template>
        </Alert>
      </div>

      <SyncSteps :steps="steps">
        <!-- Only once reading is over: while pages come in, the counts change
             and new kinds appear, and the row would keep reflowing. The step's
             detail line carries the running total meanwhile. -->
        <template #step-fetchHangar>
          <dl
            v-if="readingDone && readCounts.length"
            class="hangar-sync-result__chips"
          >
            <div
              v-for="entry in readCounts"
              :key="entry.key"
              class="hangar-sync-result__chip"
            >
              <dt :data-test="entry.dataTest">{{ entry.label }}</dt>
              <dd>{{ entry.count }}</dd>
            </div>
          </dl>
        </template>
      </SyncSteps>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.hangar-sync-result {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.hangar-sync-result__alert-text {
  margin: 0;

  & + & {
    margin-top: 6px;
  }
}

.hangar-sync-result__section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.hangar-sync-result__heading {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 12px;
  font-weight: normal;
  font-family: inherit;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.hangar-sync-result__groups {
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.hangar-sync-result__group + .hangar-sync-result__group {
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
}

.hangar-sync-result__read {
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.hangar-sync-result__summary {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 11px 14px;
  color: inherit;
  font: inherit;
  text-align: left;
  background: transparent;
  border: 0;
  border-radius: var(--radius-surface-slim, 12px);
  cursor: pointer;

  &:hover {
    color: var(--color-lifted, #eee);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: -2px;
  }
}

.hangar-sync-result__chevron {
  color: var(--color-muted, #7a8288);
  transition: transform 150ms ease;
}

.hangar-sync-result__summary[aria-expanded="true"]
  .hangar-sync-result__chevron {
  transform: rotate(90deg);
}

.hangar-sync-result__summary-label {
  flex: 1 1 auto;
  min-width: 0;
}

.hangar-sync-result__summary-detail {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}

.hangar-sync-result__count {
  min-width: 22px;
  padding: 1px 8px;
  font-size: 12px;
  text-align: center;
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: 999px;
  font-variant-numeric: tabular-nums;
}

.hangar-sync-result__items {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0;
  padding: 0 14px 12px 38px;
  list-style: none;
}

.hangar-sync-result__chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0;
}

.hangar-sync-result__read .hangar-sync-result__chips {
  padding: 0 14px 12px;
}

.hangar-sync-result__chip {
  display: inline-flex;
  gap: 6px;
  padding: 3px 10px;
  font-size: 13px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: 999px;

  dt {
    font-weight: normal;
  }

  dd {
    margin: 0;
    color: var(--color-lifted, #eee);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }
}
</style>
