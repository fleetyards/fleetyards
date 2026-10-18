<script lang="ts">
export default {
  name: "HangarBuybackSyncModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import SupportHint from "@/shared/components/SupportHint/index.vue";
import SyncSteps from "@/frontend/components/Hangar/SyncSteps/index.vue";
import type {
  SyncStep,
  SyncStepStatus,
} from "@/frontend/components/Hangar/SyncSteps/types";
import SyncResultTiles, {
  type SyncResultTile,
} from "@/frontend/components/Hangar/SyncResultTiles/index.vue";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import SyncSessionStatus from "@/frontend/components/Hangar/SyncSessionStatus/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import { useBuybackSync } from "@/frontend/composables/useBuybackSync";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncHealthPayload,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";

const { t } = useI18n();

const { displayWarning } = useAppNotifications();

const comlink = useComlink();

const hangarStore = useHangarStore();

const extensionReady = ref(false);

const extensionInfo = ref<FleetyardsSyncHealthPayload>({});

// Asked by capability rather than by version number: a local dev build only
// carries the next version once the release is cut, but already lists the
// action.
const extensionSupportsBuybacks = computed(
  () =>
    extensionInfo.value.actions?.includes(FleetyardsSyncAction.SYNC_BUYBACK) ??
    false,
);

// An extension that can read the list but not yet a pledge's price still
// syncs the list.
const extensionSupportsDetails = computed(() =>
  [
    FleetyardsSyncAction.SYNC_BUYBACK_DETAIL,
    FleetyardsSyncAction.SYNC_BUYBACK_PRICING,
  ].every((action) => extensionInfo.value.actions?.includes(action)),
);

const identityStatus = ref<"pending" | "connected" | "notFound">("pending");

// The RSI account the extension found signed in, shown so a sync into the
// wrong hangar is caught before it starts.
const rsiHandle = ref<string>();

const loadingIdentity = ref(false);

const buybackSync = useBuybackSync();

const { status, currentPage, buybacks, result, detailsStarted, running } =
  buybackSync;

const details = useBuybackDetailsSync();

const {
  total: detailsTotal,
  done: detailsDone,
  running: detailsRunning,
} = details;

// Cancelled passes go back to idle; their prices are missing all the same.
const detailsIncomplete = computed(
  () =>
    status.value === "finished" &&
    detailsStarted.value &&
    !detailsRunning.value &&
    details.status.value !== "finished",
);

// A run going or one that ended with a result is shown whatever the extension
// says now; a failed one needs the extension for its retry, so it shows the
// install or update links when that is missing.
const showsRun = computed(() =>
  ["fetching", "submitting", "finished", "unsupported"].includes(status.value),
);

const working = computed(() => loadingIdentity.value || running.value);

// The price pass is part of the run: it is only over once that is.
const settled = computed(
  () => status.value === "finished" && !detailsRunning.value,
);

// The run only says it failed, not where; the modal remembers the phase it
// last saw running. One opened onto a failed run never saw it, and says less.
const failedAt = ref<"fetching" | "submitting">();

watch(
  status,
  (current) => {
    if (current === "fetching" || current === "submitting") {
      failedAt.value = current;
    } else if (current === "idle") {
      failedAt.value = undefined;
    }
  },
  { immediate: true },
);

const stepStatus = (index: number, current: number, failed = false) => {
  if (index < current) return "done";
  if (index > current) return "pending";

  return (failed ? "failed" : "active") as SyncStepStatus;
};

const steps = computed<SyncStep[]>(() => {
  const failed = status.value === "failed";
  // Where a failure stopped: the list is read until it is submitted.
  const current = detailsRunning.value
    ? 2
    : status.value === "submitting" || failedAt.value === "submitting"
      ? 1
      : 0;
  const list: SyncStep[] = [
    {
      key: "fetching",
      label: t("labels.buybackSync.status.fetching"),
      detail: t(
        current > 0
          ? "labels.buybackSync.stepDetails.read"
          : "labels.buybackSync.stepDetails.reading",
        { page: currentPage.value, count: buybacks.value.length },
      ),
      status: stepStatus(0, current, failed),
      // The list's pages are read until one comes back empty.
      progress: current === 0 && !failed ? "indeterminate" : undefined,
    },
    {
      key: "submitting",
      label: t("labels.buybackSync.status.submitting"),
      detail: result.value
        ? t("labels.buybackSync.stepDetails.saved", {
            added: result.value.added,
            removed: result.value.removed,
          })
        : undefined,
      status: stepStatus(1, current, failed),
      progress: current === 1 && !failed ? "indeterminate" : undefined,
    },
  ];

  if (extensionSupportsDetails.value || detailsStarted.value) {
    list.push({
      key: "prices",
      label: t("labels.buybackSync.detailsProgress"),
      detail: detailsTotal.value
        ? t("labels.buybackSync.stepDetails.prices", {
            done: detailsDone.value,
            total: detailsTotal.value,
          })
        : t("labels.buybackSync.stepDetails.pricesPending"),
      status: stepStatus(2, current, failed),
      progress:
        current === 2 && detailsTotal.value
          ? { value: detailsDone.value, max: detailsTotal.value }
          : undefined,
    });
  }

  return list;
});

const resultTiles = computed<SyncResultTile[]>(() => [
  {
    key: "found",
    label: t("labels.buybackSync.found"),
    value: buybacks.value.length,
  },
  {
    key: "added",
    label: t("labels.buybackSync.added"),
    value: result.value?.added ?? 0,
    valueTest: "buyback-sync-added",
  },
  {
    key: "removed",
    label: t("labels.buybackSync.removed"),
    value: result.value?.removed ?? 0,
    valueTest: "buyback-sync-removed",
  },
  ...(detailsStarted.value && detailsTotal.value
    ? [
        {
          key: "prices",
          label: t("labels.buybackSync.prices"),
          value: `${detailsDone.value} / ${detailsTotal.value}`,
          valueTest: "buyback-sync-prices",
        },
      ]
    : []),
]);

const headline = computed(() => t("headlines.buybackSync"));

const title = computed(() => {
  if (!showsRun.value && !extensionReady.value) {
    return t("labels.syncExtension.extensionNeededTitle");
  }
  if (
    status.value === "unsupported" ||
    (!showsRun.value && !extensionSupportsBuybacks.value)
  ) {
    return t("labels.buybackSync.updateExtensionTitle");
  }
  if (status.value === "idle") return headline.value;
  if (status.value === "failed") return t("labels.syncExtension.failedTitle");
  if (settled.value) return t("labels.buybackSync.finishedTitle");

  return t("labels.buybackSync.runningTitle");
});

const eyebrow = computed(() =>
  title.value === headline.value ? undefined : headline.value,
);

const supportPrompt = useSupportPrompt();
const supportHintDismissed = ref(false);
const showSupportHint = computed(
  () => settled.value && !supportHintDismissed.value && supportPrompt.canShow(),
);

const extension = useSyncExtension();

let unmounted = false;

const checkExtension = async () => {
  const health = await extension.health();

  extensionReady.value = health?.code === 200;
  extensionInfo.value =
    (health?.payload as FleetyardsSyncHealthPayload | undefined) || {};

  if (canStart()) {
    await checkRSIIdentity();
  }
};

// Only once Start could be pressed: a check mid-run would spend an RSI request
// and warn about a session the run already has.
const canStart = () =>
  !unmounted &&
  ["idle", "failed"].includes(status.value) &&
  extensionReady.value &&
  extensionSupportsBuybacks.value;

// A read that failed may have failed on the session; the run has already said
// so, so the check only updates what Start relies on. A finished or cancelled
// run offers no Start, and needs no RSI request for one.
watch(status, (current) => {
  if (current === "failed" && canStart()) {
    void checkRSIIdentity({ quiet: true });
  }
});

onMounted(() => {
  hangarStore.buybackSyncModalOpen = true;
  void checkExtension();
});

// A run still going is what the modal opens on next time, and so is one that
// ended in the background, until its result has been shown here once. The
// price pass is part of the run: its result is only shown once it is over.
onBeforeUnmount(() => {
  unmounted = true;
  hangarStore.buybackSyncModalOpen = false;
  if (detailsRunning.value) return;

  buybackSync.reset();
  details.reset();
});

// Only the latest check answers: retry can be pressed while one is out.
let identityCheck = 0;

const checkRSIIdentity = async ({ quiet = false } = {}) => {
  const current = ++identityCheck;
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  const identity = await extension
    .request(FleetyardsSyncAction.IDENTIFY)
    .catch(() => undefined);
  if (unmounted || current !== identityCheck) return;
  const handle = (identity?.payload as FleetyardsSyncSessionPayload)?.handle;

  loadingIdentity.value = false;

  if (identity?.code !== 200 || !handle) {
    if (!quiet) {
      displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
    }
    identityStatus.value = "notFound";
    rsiHandle.value = undefined;
  } else {
    identityStatus.value = "connected";
    rsiHandle.value = handle;
  }
};

const start = () => {
  buybackSync.start({
    readDetails: extensionSupportsDetails.value,
    extensionVersion: extensionInfo.value.version,
  });
};

const close = () => {
  comlink.emit("close-modal");
};

const cancelRun = () => {
  buybackSync.cancel();
  close();
};
</script>

<template>
  <Modal :title="title" :eyebrow="eyebrow" :loading="working">
    <!-- A run already going is shown at once, not after the extension check. -->
    <div v-if="!showsRun && !extensionReady" class="buyback-sync">
      <p class="buyback-sync__text">
        {{ t("texts.syncExtension.gettingStarted") }}
      </p>
      <SyncExtensionLinks list />
    </div>
    <div
      v-else-if="!showsRun && !extensionSupportsBuybacks"
      class="buyback-sync"
      data-test="buyback-sync-outdated"
    >
      <Alert
        :variant="AlertVariantsEnum.WARNING"
        :size="AlertSizesEnum.COMPACT"
      >
        {{ t("texts.buybackSync.unsupported") }}
        <template v-if="extensionInfo.version">
          {{ t("labels.buybackSync.extensionVersion") }}:
          {{ extensionInfo.version }}
        </template>
      </Alert>
      <SyncExtensionLinks list update />
    </div>
    <div v-else-if="status === 'idle'" class="buyback-sync">
      <SyncSessionStatus
        :status="identityStatus"
        :loading="loadingIdentity"
        :handle="rsiHandle"
        :hint="t('texts.buybackSync.sessionHint')"
        @recheck="checkRSIIdentity"
      />
      <ul class="buyback-sync__points">
        <li>
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
          {{ t("texts.buybackSync.pointReplace") }}
        </li>
        <li>
          <i class="fa-light fa-check" aria-hidden="true" />
          {{ t("texts.buybackSync.pointUntouched") }}
        </li>
        <li>
          <i class="fa-light fa-clock" aria-hidden="true" />
          {{ t("texts.buybackSync.pointBackground") }}
        </li>
      </ul>
      <Alert
        v-if="extensionSupportsDetails"
        :variant="AlertVariantsEnum.INFO"
        :size="AlertSizesEnum.COMPACT"
        :title="t('labels.buybackSync.firstSyncTitle')"
      >
        {{ t("texts.buybackSync.detailsInfo") }}
      </Alert>
      <Alert
        v-if="detailsRunning"
        :variant="AlertVariantsEnum.WARNING"
        :size="AlertSizesEnum.COMPACT"
        data-test="buyback-sync-details-running"
      >
        {{ t("texts.buybackSync.detailsRunning") }}
      </Alert>
    </div>
    <div v-else class="buyback-sync" data-test="buyback-sync-progress">
      <Alert
        v-if="status === 'unsupported'"
        :variant="AlertVariantsEnum.WARNING"
        :size="AlertSizesEnum.COMPACT"
      >
        {{ t("texts.buybackSync.unsupported") }}
      </Alert>
      <template v-else-if="settled">
        <Alert
          :variant="AlertVariantsEnum.SUCCESS"
          :size="AlertSizesEnum.COMPACT"
        >
          {{ t("texts.buybackSync.finished") }}
        </Alert>
        <SyncResultTiles :tiles="resultTiles" />
        <Alert
          v-if="detailsIncomplete"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          data-test="buyback-sync-details-incomplete"
        >
          {{ t("texts.buybackSync.detailsIncomplete") }}
        </Alert>
        <Alert
          v-if="result?.detailsPending.length && !extensionSupportsDetails"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          data-test="buyback-sync-details-unsupported"
        >
          {{ t("texts.buybackSync.detailsUnsupported") }}
        </Alert>
        <transition name="fade">
          <SupportHint
            v-if="showSupportHint"
            inline
            context="hangarSync"
            :meta="{ count: result?.added ?? 0 }"
            @dismiss="supportHintDismissed = true"
          />
        </transition>
      </template>
      <template v-else>
        <Alert
          v-if="status === 'failed'"
          :variant="AlertVariantsEnum.DANGER"
          :size="AlertSizesEnum.COMPACT"
          :title="t('labels.buybackSync.status.failed')"
        />
        <SyncSteps v-if="status !== 'failed' || failedAt" :steps="steps" />
        <p
          v-if="status === 'finished' && detailsRunning"
          class="buyback-sync__note"
          data-test="buyback-sync-details-background"
        >
          <i class="fa-light fa-circle-info" aria-hidden="true" />
          {{ t("texts.buybackSync.detailsBackground") }}
        </p>
        <p v-else-if="running" class="buyback-sync__note">
          <i class="fa-light fa-circle-info" aria-hidden="true" />
          {{ t("texts.buybackSync.keepsRunning") }}
        </p>
      </template>
    </div>
    <template #footer>
      <Btn
        v-if="!running || status === 'fetching'"
        :variant="BtnVariantsEnum.BARE"
        data-test="close-buyback-sync"
        @click="cancelRun"
      >
        {{
          status === "idle" || status === "fetching"
            ? t("actions.syncExtension.cancel")
            : t("actions.syncExtension.close")
        }}
      </Btn>
      <Btn v-if="running" data-test="background-buyback-sync" @click="close">
        {{ t("actions.syncExtension.runInBackground") }}
      </Btn>
      <Btn
        v-else-if="
          extensionReady &&
          extensionSupportsBuybacks &&
          ['idle', 'failed'].includes(status)
        "
        data-test="start-buyback-sync"
        :loading="loadingIdentity"
        :disabled="identityStatus !== 'connected' || detailsRunning"
        @click="start"
      >
        {{
          status === "failed"
            ? t("actions.syncExtension.retry")
            : t("actions.syncExtension.start")
        }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.buyback-sync {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.buyback-sync__text {
  margin: 0;
  line-height: 1.55;
}

.buyback-sync__points {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    display: flex;
    align-items: baseline;
    gap: 10px;
    line-height: 1.5;
  }

  i {
    flex-shrink: 0;
    width: 16px;
    color: var(--color-muted, #7a8288);
    text-align: center;
  }
}

.buyback-sync__note {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 14px;
  line-height: 1.5;

  i {
    color: var(--color-muted, #7a8288);
  }
}
</style>
