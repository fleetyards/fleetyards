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
import SyncResultTiles from "@/frontend/components/Hangar/SyncResultTiles/index.vue";
import SyncReadCounts from "@/frontend/components/Hangar/SyncReadCounts/index.vue";
import type { SyncReadCount } from "@/frontend/components/Hangar/SyncReadCounts/types";
import type { SyncResultTile } from "@/frontend/components/Hangar/SyncResultTiles/types";
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

// A kind the run leaves out is still counted, so the two steps agree, but
// marked as not synced.
const kind = (
  key: string,
  count: number,
  synced = true,
  dataTest?: string,
): SyncReadCount => ({
  key,
  count,
  label: t(
    `labels.syncExtension.pledgeItems.${synced ? key : `${key}NotSynced`}`,
  ),
  skipped: !synced,
  dataTest: synced ? undefined : dataTest,
});

// Every kind, zeros included: the grid is laid out once, when reading starts,
// and only its numbers move after that.
const readCounts = computed<SyncReadCount[]>(() => [
  kind("pages", props.currentPage),
  kind("ships", countOf("ship")),
  kind("components", countOf("component")),
  kind("upgrades", countOf("upgrade")),
  kind("paints", rowsOf("skin"), props.syncPaints, "paints-not-synced"),
  kind(
    "hangarFlair",
    rowsOf("flair"),
    props.syncHangarFlair,
    "hangar-flair-not-synced",
  ),
  kind(
    "equipment",
    rowsOf("equipment"),
    props.syncEquipment,
    "equipment-not-synced",
  ),
  kind("ccus", rowsOf("ccu"), props.syncCcus, "ccus-not-synced"),
  // Sorted into flair or equipment only once the server stores them.
  kind("extras", rowsOf("extra")),
]);

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

    // While reading, the grid under the step carries the numbers.
    return step.status === "processing"
      ? undefined
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

const readingStarted = computed(() => {
  const status = props.processSteps.find(
    (step) => step.name === "fetchHangar",
  )?.status;

  return !!status && status !== "pending";
});

const failedStep = computed(() =>
  props.processSteps.find(
    (step) => step.status === "failure" || step.status === "backendFailure",
  ),
);

// A kind's tile counts all of it, found and added alike, and notes how many
// are new: under "Hangar synced", "found" and "synced" said nothing more.
const KIND_TILES = [
  { key: "ships", found: "foundVehicles", added: "importedVehicles" },
  { key: "components", found: "foundComponents", added: "importedComponents" },
  { key: "upgrades", found: "foundUpgrades", added: "importedUpgrades" },
  { key: "paints", found: "syncedPaints" },
  { key: "hangarFlair", found: "syncedHangarFlair" },
  { key: "equipment", found: "syncedEquipment" },
  { key: "ccus", found: "syncedCcus" },
] as const;

// What happened to the ships not in the RSI hangar: actions, named as such.
const ACTION_TILES = [
  "movedVehiclesToWanted",
  "deletedVehicles",
  "groupedVehicles",
  "unchangedVehicles",
] as const;

const resultTiles = computed<SyncResultTile[]>(() =>
  [
    ...KIND_TILES.map((tile) => {
      const added =
        "added" in tile ? (props.result?.[tile.added]?.length ?? 0) : 0;

      return {
        key: tile.key,
        value: (props.result?.[tile.found]?.length ?? 0) + added,
        label: t(`labels.syncExtension.resultKinds.${tile.key}`),
        note: added
          ? t("labels.syncExtension.newCount", { count: added })
          : undefined,
      };
    }),
    ...ACTION_TILES.map((key) => ({
      key,
      value: props.result?.[key]?.length ?? 0,
      label: t(`labels.syncExtension.resultActions.${key}`),
    })),
  ].filter((tile) => tile.value > 0),
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
          <div class="hangar-sync-result__read-counts">
            <SyncReadCounts :counts="readCounts" />
          </div>
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
        <template #step-fetchHangar>
          <SyncReadCounts v-if="readingStarted" :counts="readCounts" />
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

// Inside the element Collapsed animates, not on it: it holds the animated
// element's padding at zero until the end, and the content would jump.
.hangar-sync-result__read-counts {
  padding: 0 14px 12px;
}
</style>
