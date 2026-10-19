<script lang="ts">
export default {
  name: "HangarSyncResult",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import SyncSteps from "@/frontend/components/Hangar/SyncSteps/index.vue";
import { readingPages } from "@/frontend/components/Hangar/SyncSteps/readingPages";
import { lastSyncCaption } from "@/frontend/components/Hangar/SyncSteps/lastSyncCaption";
import type {
  SyncStep,
  SyncStepStatus,
} from "@/frontend/components/Hangar/SyncSteps/types";
import SyncCountList from "@/frontend/components/Hangar/SyncCountList/index.vue";
import type { SyncCount } from "@/frontend/components/Hangar/SyncCountList/types";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  HangarSyncLastRead,
  HangarSyncLastReadCounts,
  RsiHangarItemInput,
  HangarSyncResult,
} from "@/services/fyApi";
import type { SyncProcessStep, SyncProcessStepStatus } from "./types";
import { syncOutcomeMessage } from "./status";

type Props = {
  processSteps: SyncProcessStep[];
  currentPage: number;
  totalPages?: number;
  lastRead?: HangarSyncLastRead;
  // The import the save created, once the server has taken the items.
  importId?: string;
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
  syncShipComponents?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  result: undefined,
  totalPages: undefined,
  lastRead: undefined,
  importId: undefined,
  cancelled: false,
  showSupportHint: false,
  syncPaints: true,
  syncHangarFlair: true,
  syncEquipment: true,
  syncCcus: true,
  syncShipComponents: true,
});

defineEmits<{
  (event: "support-hint-dismiss"): void;
}>();

const { t } = useI18n();

type PledgeFilter = (pledge: RsiHangarItemInput) => boolean;

const ofType =
  (type: string): PledgeFilter =>
  (pledge) =>
    pledge.type === type;

// RSI lists ship modules and ship parts alike as components. A module is named
// as one, as the server tells them apart: it is fitted to a ship, and a part is
// kept as a ship component.
const MODULE_NAME = /\bmodule\b/i;

const isModule: PledgeFilter = (pledge) =>
  pledge.type === "component" && MODULE_NAME.test(pledge.name);

const isShipPart: PledgeFilter = (pledge) =>
  pledge.type === "component" && !MODULE_NAME.test(pledge.name);

const countOf = (filter: PledgeFilter) => props.pledges.filter(filter).length;

// The sync keeps one row per name in a pledge, with a quantity, so a poster
// listed twice is counted once here too and the two steps agree.
const rowsOf = (filter: PledgeFilter) =>
  new Set(
    props.pledges
      .filter(filter)
      .map((pledge) => `${pledge.id}:${pledge.name.trim()}`),
  ).size;

const readStatus = computed(
  () => props.processSteps.find((step) => step.name === "fetchHangar")?.status,
);

const readingDone = computed(() => readStatus.value === "success");

// A run that stopped reading has nothing to measure against the last sync.
const measuring = computed(
  () =>
    !!props.lastRead &&
    (readStatus.value === "processing" || readStatus.value === "success"),
);

// The last sync's figure for a kind, for its row to fill toward while the run
// reads and to measure against once it has read everything.
const comparedToLast = (
  type: keyof HangarSyncLastReadCounts,
): Pick<SyncCount, "reference" | "final"> => {
  if (!measuring.value || !props.lastRead) return {};

  return { reference: props.lastRead.counts[type], final: readingDone.value };
};

// A kind the run leaves out is still counted, so the two steps agree, but
// marked as not synced.
const kind = (
  key: string,
  type: keyof HangarSyncLastReadCounts,
  count: number,
  synced = true,
  dataTest?: string,
): SyncCount => ({
  key,
  value: count,
  // The kinds' names are the result's, so the two read as one list.
  label: synced
    ? t(`labels.syncExtension.resultKinds.${key}`)
    : t(`labels.syncExtension.pledgeItems.${key}NotSynced`),
  skipped: !synced,
  labelTest: synced ? undefined : dataTest,
  ...comparedToLast(type),
});

const allReadCounts = computed<SyncCount[]>(() => [
  kind("ships", "ship", countOf(ofType("ship"))),
  kind("components", "component", countOf(isModule)),
  kind("upgrades", "upgrade", countOf(ofType("upgrade"))),
  kind(
    "paints",
    "skin",
    rowsOf(ofType("skin")),
    props.syncPaints,
    "paints-not-synced",
  ),
  kind(
    "hangarFlair",
    "flair",
    rowsOf(ofType("flair")),
    props.syncHangarFlair,
    "hangar-flair-not-synced",
  ),
  kind(
    "equipment",
    "equipment",
    rowsOf(ofType("equipment")),
    props.syncEquipment,
    "equipment-not-synced",
  ),
  kind("ccus", "ccu", rowsOf(ofType("ccu")), props.syncCcus, "ccus-not-synced"),
  kind(
    "shipComponents",
    "shipComponent",
    rowsOf(isShipPart),
    props.syncShipComponents,
    "ship-components-not-synced",
  ),
  // Sorted into flair or equipment only once the server stores them.
  {
    ...kind("extras", "extra", rowsOf(ofType("extra"))),
    label: t("labels.syncExtension.pledgeItems.extras"),
  },
]);

// A kind shows once something of it is read. With a last sync to go by, every
// kind it had is listed from the start, so the list holds still while the run
// reads, and a kind gone since still shows what it lost.
const readCounts = computed(() =>
  allReadCounts.value.filter(
    (count) => Number(count.value) > 0 || (count.reference ?? 0) > 0,
  ),
);

// Counted as the kinds are, so the total and the list agree.
const readTotal = computed(() =>
  allReadCounts.value.reduce((sum, count) => sum + Number(count.value), 0),
);

const lastReadCaption = (): SyncStep["caption"] =>
  props.lastRead
    ? lastSyncCaption(readTotal.value, props.lastRead.total, readingDone.value)
    : undefined;

const STEP_STATUS: Record<SyncProcessStepStatus, SyncStepStatus> = {
  pending: "pending",
  processing: "active",
  success: "done",
  failure: "failed",
  backendFailure: "failed",
};

// RSI's pager names the list's length; without one, the last sync's page count
// is the best guess, and said to be one.
const reading = computed(() =>
  props.totalPages
    ? readingPages(props.currentPage, props.totalPages)
    : readingPages(props.currentPage, props.lastRead?.pages ?? undefined, true),
);

const stepDetail = (step: SyncProcessStep): SyncStep["detail"] => {
  if (step.name === "fetchHangar") {
    if (step.status === "pending") return undefined;

    // While reading, the list under the step carries the counts.
    if (step.status === "processing") return reading.value.detail;

    return {
      key: "labels.syncExtension.stepDetails.read",
      values: { pages: pagesRead.value, count: readTotal.value },
    };
  }

  // The save is one request, then the server's own run: first what is on its
  // way, then what arrived.
  if (step.status === "success") {
    return {
      key: "labels.syncExtension.stepDetails.sent",
      values: { count: readTotal.value },
    };
  }

  if (step.status === "processing") {
    return {
      key: props.importId
        ? "labels.syncExtension.stepDetails.sent"
        : "labels.syncExtension.stepDetails.sending",
      values: { count: readTotal.value },
    };
  }

  return undefined;
};

const saveCaption = (step: SyncProcessStep) =>
  step.status === "processing" && props.importId
    ? t("labels.syncExtension.stepDetails.saving")
    : undefined;

const importRoute = computed(() =>
  props.importId
    ? { name: "hangar-import", params: { id: props.importId } }
    : undefined,
);

// Reading fills by page; the save, a single request, only shows that it is
// working. Each kind's row measures itself against the last sync.
const stepProgress = (step: SyncProcessStep): SyncStep["progress"] => {
  if (step.status !== "processing") return undefined;
  if (step.name === "fetchHangar") return reading.value.progress;

  return "indeterminate";
};

// A run that ended with something to look at is not a clean success: reading
// that missed items, or a save that could not match some, says so on its step.
const stepStatus = (step: SyncProcessStep): SyncStepStatus => {
  // A cancelled run stops a step without it failing.
  if (props.cancelled && step.status === "failure") return "pending";

  const status = STEP_STATUS[step.status];
  if (status !== "done" || !props.finished) return status;

  if (step.name === "fetchHangar" && incomplete.value) return "warning";
  if (step.name === "submitData" && unmatchedTotal.value > 0) return "warning";

  return status;
};

const steps = computed<SyncStep[]>(() =>
  props.processSteps.map((step) => ({
    key: step.name,
    label: t(`labels.syncExtension.processSteps.${step.name}`),
    detail: stepDetail(step),
    caption:
      step.name === "fetchHangar"
        ? measuring.value
          ? lastReadCaption()
          : undefined
        : saveCaption(step),
    status: stepStatus(step),
    progress: stepProgress(step),
  })),
);

// The run learns the list has ended by asking for one page past it - RSI's
// empty list, or its last page again - and stops there without counting it.
// A run that failed stopped on the page it could not read. Either way, the
// page it stands on is not one it read.
const pagesRead = computed(() => Math.max(props.currentPage - 1, 0));

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

// A kind's row counts all of it, found and added alike, and notes how many
// are new: under "Hangar synced", "found" and "synced" said nothing more.
const RESULT_KINDS = [
  { key: "ships", found: "foundVehicles", added: "importedVehicles" },
  { key: "components", found: "foundComponents", added: "importedComponents" },
  { key: "upgrades", found: "foundUpgrades", added: "importedUpgrades" },
  { key: "paints", found: "syncedPaints" },
  { key: "hangarFlair", found: "syncedHangarFlair" },
  { key: "equipment", found: "syncedEquipment" },
  { key: "ccus", found: "syncedCcus" },
  { key: "shipComponents", found: "syncedShipComponents" },
] as const;

// What happened to the ships not in the RSI hangar: actions, named as such.
const RESULT_ACTIONS = [
  "movedVehiclesToWanted",
  "deletedVehicles",
  "groupedVehicles",
  "unchangedVehicles",
] as const;

const resultCounts = computed<SyncCount[]>(() =>
  [
    ...RESULT_KINDS.map((row) => {
      const added =
        "added" in row ? (props.result?.[row.added]?.length ?? 0) : 0;

      return {
        key: row.key,
        value: (props.result?.[row.found]?.length ?? 0) + added,
        label: t(`labels.syncExtension.resultKinds.${row.key}`),
        note: added
          ? t("labels.syncExtension.newCount", { count: added })
          : undefined,
      };
    }),
    ...RESULT_ACTIONS.map((key) => ({
      key,
      value: props.result?.[key]?.length ?? 0,
      label: t(`labels.syncExtension.resultActions.${key}`),
    })),
  ].filter((row) => row.value > 0),
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

const incomplete = computed(() => !!props.result?.incomplete);

// A run that found nothing to change, or only kinds it is set to skip, is no
// success to report; its toast's words say what happened instead.
const outcome = computed(() =>
  syncOutcomeMessage(props.result?.outcome, incomplete.value),
);

const hasWarnings = computed(
  () => incomplete.value || unmatchedTotal.value > 0,
);
</script>

<template>
  <div class="hangar-sync-result">
    <div v-if="finished" data-test="sync-result-status">
      <Alert v-if="!outcome.synced" :variant="AlertVariantsEnum.NEUTRAL">
        {{ t(outcome.key) }}
      </Alert>
      <Alert
        v-else-if="hasWarnings"
        :variant="AlertVariantsEnum.WARNING"
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
      <Alert v-else :variant="AlertVariantsEnum.SUCCESS">
        {{ t("texts.syncExtension.finished") }}
      </Alert>
    </div>

    <!-- A save the server failed is retryable rather than finished with
         errors, and needs its notice all the more. -->
    <div
      v-else-if="finishedWithErrors || failedStep"
      data-test="sync-result-status"
    >
      <Alert
        v-if="cancelled"
        :variant="AlertVariantsEnum.NEUTRAL"
        :title="t('labels.syncExtension.status.cancelled')"
      />
      <Alert
        v-else
        :variant="AlertVariantsEnum.DANGER"
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

    <!-- The result is the run's last step, read the same way as while it ran:
         what was read folds away under its step, and what the save did stays
         in view under its own. -->
    <SyncSteps :steps="steps">
      <template #step-fetchHangar>
        <SyncCountList v-if="readingStarted" :counts="readCounts" />
      </template>
      <template v-if="finished || importRoute" #step-submitData>
        <template v-if="finished">
          <SyncCountList v-if="resultCounts.length" :counts="resultCounts" />

          <section
            v-if="unmatchedGroups.length"
            class="hangar-sync-result__section"
            data-test="sync-unmatched"
          >
            <h3 class="hangar-sync-result__heading">
              {{ t("labels.syncExtension.unmatchedHeading") }}
            </h3>
            <div class="hangar-sync-result__groups">
              <!-- What the sync could not match is what the reader has to act
                   on, so it is never folded away. -->
              <div
                v-for="group in unmatchedGroups"
                :key="group.key"
                class="hangar-sync-result__group"
                :data-test="`sync-unmatched-${group.key}`"
              >
                <h4 class="hangar-sync-result__group-heading">
                  <span class="hangar-sync-result__summary-label">
                    {{ group.label }}
                  </span>
                  <span class="hangar-sync-result__count">
                    {{ group.items.length }}
                  </span>
                </h4>
                <ul class="hangar-sync-result__items">
                  <li v-for="item in group.items" :key="`${group.key}-${item}`">
                    {{ item }}
                  </li>
                </ul>
              </div>
            </div>
          </section>
        </template>

        <router-link
          v-if="importRoute"
          :to="importRoute"
          class="hangar-sync-result__import-link"
          data-test="sync-import-link"
        >
          {{ t("labels.syncExtension.viewImport") }}
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
        </router-link>
      </template>
    </SyncSteps>

    <transition name="fade">
      <SupportHint
        v-if="finished && showSupportHint"
        inline
        context="hangarSync"
        :meta="{ count: result?.importedVehicles?.length ?? 0 }"
        @dismiss="$emit('support-hint-dismiss')"
      />
    </transition>
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

.hangar-sync-result__group-heading {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 11px 14px 8px;
  color: var(--color-lifted, #eee);
  font-size: 15px;
  font-weight: normal;
  font-family: inherit;
}

.hangar-sync-result__summary-label {
  flex: 1 1 auto;
  min-width: 0;
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
  padding: 0 14px 12px;
  color: var(--color-text-dim, #959595);
  list-style: none;
}

.hangar-sync-result__import-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  align-self: flex-start;
  font-size: 14px;
}
</style>
