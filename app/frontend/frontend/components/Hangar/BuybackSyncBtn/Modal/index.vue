<script lang="ts">
export default {
  name: "HangarBuybackSyncModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import SyncSessionStatus from "@/frontend/components/Hangar/SyncSessionStatus/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import { extractBuybackPage } from "@/frontend/lib/RSIBuybackParser";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import { createRsiRateLimiter } from "@/frontend/lib/RsiRateLimiter";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useHangarSync } from "@/frontend/composables/useHangarSync";
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";
import {
  RsiPageReportOutcome,
  useRsiPageReport,
} from "@/frontend/composables/useRsiPageReport";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncHealthPayload,
  type FleetyardsSyncMessage,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
import {
  RsiPageKindEnum,
  useSyncRsiBuybacks,
  type BuybackSyncResult,
  type RsiBuybackItemInput,
} from "@/services/fyApi";

type SyncStatus =
  "idle" | "fetching" | "submitting" | "finished" | "unsupported" | "failed";

const { t } = useI18n();

const { displayInfo, displaySuccess, displayWarning, displayAlert } =
  useAppNotifications();

const comlink = useComlink();

const hangarStore = useHangarStore();

// A hangar sync still reading RSI in the background counts as much as one the
// backend is running.
const { running: hangarSyncReading } = useHangarSync();

const hangarSyncRunning = computed(
  () => hangarStore.syncRunning || hangarSyncReading.value,
);

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

const status = ref<SyncStatus>("idle");

const currentPage = ref(1);

const buybacks = ref<RsiBuybackItemInput[]>([]);

const seenIds = new Set<string>();

const result = ref<BuybackSyncResult | undefined>();

// The pass state outlives this sync; its counts only describe a pass started
// by it.
const detailsStarted = ref(false);

const maxMessagesPerMinute = 60;

// The list crawl and the price pass after it share one budget, so the two
// together stay inside it.
let rateLimiter = createRsiRateLimiter(maxMessagesPerMinute);

// An extension that never answers would otherwise leave the sync spinning.
const REPLY_TIMEOUT = 30000;

const working = computed(
  () =>
    loadingIdentity.value ||
    status.value === "fetching" ||
    status.value === "submitting",
);

const extension = useSyncExtension();

let unmounted = false;

const checkExtension = async () => {
  const health = await extension.health();

  extensionReady.value = health?.code === 200;
  extensionInfo.value =
    (health?.payload as FleetyardsSyncHealthPayload | undefined) || {};

  if (!unmounted && extensionReady.value && extensionSupportsBuybacks.value) {
    await checkRSIIdentity();
  }
};

onMounted(() => {
  void checkExtension();
});

onBeforeUnmount(() => {
  unmounted = true;
});

// A reply landing after the sync failed or the modal closed belongs to a crawl
// that is over. No reply at all is a timeout.
const onSyncReply = async (message?: FleetyardsSyncMessage) => {
  if (unmounted || status.value !== "fetching") return;

  if (message?.code === 200) {
    await handlePage(message.payload as string).catch((error) => {
      console.error("Buy-back sync error:", error);
      fail();
    });
  } else if (message && isUnknownAction(message)) {
    status.value = "unsupported";
  } else {
    fail();
  }
};

// Only the latest check answers: retry can be pressed while one is out.
let identityCheck = 0;

const checkRSIIdentity = async () => {
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
    displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
    identityStatus.value = "notFound";
    rsiHandle.value = undefined;
  } else {
    identityStatus.value = "connected";
    rsiHandle.value = handle;
  }
};

// An extension released before buy-backs answers the action it does not know
// with this.
const isUnknownAction = (message: FleetyardsSyncMessage) =>
  message.code === 500 && message.error === "Unknown Action";

const start = () => {
  status.value = "fetching";
  buybacks.value = [];
  seenIds.clear();
  result.value = undefined;
  detailsStarted.value = false;
  currentPage.value = 1;
  rateLimiter = createRsiRateLimiter(maxMessagesPerMinute);

  displayInfo({ text: t("messages.buybackSync.started") });

  fetchPage(currentPage.value);
};

// Every later page and every throttled retry arrives through a timer, which
// can fire after the sync failed or the modal closed.
const fetchPage = (page: number) => {
  if (unmounted || status.value !== "fetching") {
    return;
  }

  if (!rateLimiter.tryTake()) {
    setTimeout(() => fetchPage(page), 500);
    return;
  }

  void extension
    .request(FleetyardsSyncAction.SYNC_BUYBACK, { page }, REPLY_TIMEOUT)
    .catch(() => undefined)
    .then(onSyncReply);
};

const fail = (text = t("messages.buybackSync.failure")) => {
  status.value = "failed";
  displayAlert({ text });
};

const reportRsiPage = useRsiPageReport();

const handlePage = async (html: string) => {
  const result = extractBuybackPage(html);

  // Not a buy-back page this parser understands: the list read so far is
  // incomplete, and submitting it would delete every buy-back after it.
  if (result.status === RsiPageStatus.UNRECOGNISED) {
    status.value = "failed";

    const outcome = await reportRsiPage({
      page: RsiPageKindEnum.BUYBACK,
      check: result.check,
      pageNumber: currentPage.value,
      extensionVersion: extensionInfo.value.version,
    });

    // Signed out, the identify answer has already said so.
    if (outcome === RsiPageReportOutcome.REPORTED) {
      fail(t("messages.syncExtension.pageNotRecognised"));
    } else if (outcome === RsiPageReportOutcome.NO_ANSWER) {
      fail();
    }
    return;
  }

  if (result.status === RsiPageStatus.END) {
    await submit();
    return;
  }

  const newBuybacks = result.pledges.filter(
    (pledge) => !seenIds.has(pledge.id),
  );

  if (newBuybacks.length === 0) {
    await submit();
    return;
  }

  newBuybacks.forEach((pledge) => seenIds.add(pledge.id));
  buybacks.value = [...buybacks.value, ...newBuybacks];

  currentPage.value += 1;
  setTimeout(() => fetchPage(currentPage.value), 500);
};

const {
  total: detailsTotal,
  done: detailsDone,
  running: detailsRunning,
  run: runDetails,
} = useBuybackDetailsSync();

const mutation = useSyncRsiBuybacks();

// Only ever after the last page: the endpoint replaces the whole list, so a
// partial one would drop every buy-back on the pages that were never read.
const submit = async () => {
  status.value = "submitting";

  try {
    result.value = await mutation.mutateAsync({
      data: { items: buybacks.value },
    });
  } catch (error) {
    console.error(error);
    fail();
    return;
  }

  comlink.emit("buyback-sync-finished");

  if (result.value.detailsPending.length && extensionSupportsDetails.value) {
    // A hangar sync started while the list was read would share RSI's rate
    // limit with the pass, and so would a sync from a reopened modal, whose
    // limiter knows nothing of this one; the next sync reads these prices.
    if (hangarSyncRunning.value || unmounted) {
      displayWarning({ text: t("texts.buybackSync.detailsIncomplete") });
    } else {
      detailsStarted.value = true;
      void runDetails(buybacks.value, result.value.detailsPending, {
        waitForSlot: rateLimiter.take,
      });
    }
  }

  status.value = "finished";
  displaySuccess({ text: t("messages.buybackSync.success") });
};

// Not forced, so a close mid-fetch asks first, as the X does.
const close = () => {
  comlink.emit("close-modal");
};

// Only reading the list ends with the modal: a submitted list is stored and
// its toast shows without the modal open.
defineExpose({
  dirty: computed(() => status.value === "fetching"),
  dirtyText: t("messages.buybackSync.closeWhileRunning"),
});
</script>

<template>
  <Modal :title="t('headlines.buybackSync')" :loading="working">
    <div v-if="!extensionReady">
      <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
      <SyncExtensionLinks />
    </div>
    <div
      v-else-if="!extensionSupportsBuybacks"
      data-test="buyback-sync-outdated"
    >
      <p class="text-warning">{{ t("texts.buybackSync.unsupported") }}</p>
      <p v-if="extensionInfo.version">
        {{ t("labels.buybackSync.extensionVersion") }}:
        {{ extensionInfo.version }}
      </p>
      <SyncExtensionLinks />
    </div>
    <div v-else-if="status === 'idle'">
      <SyncSessionStatus
        :status="identityStatus"
        :loading="loadingIdentity"
        :handle="rsiHandle"
        @recheck="checkRSIIdentity"
      />
      <p>{{ t("texts.buybackSync.info") }}</p>
      <p v-if="extensionSupportsDetails">
        {{ t("texts.buybackSync.detailsInfo") }}
      </p>
      <p
        v-if="detailsRunning"
        class="text-warning"
        data-test="buyback-sync-details-running"
      >
        {{ t("texts.buybackSync.detailsRunning") }}
      </p>
      <p
        v-else-if="hangarSyncRunning"
        class="text-warning"
        data-test="buyback-sync-hangar-sync-running"
      >
        {{ t("texts.syncExtension.alreadyRunning") }}
      </p>
    </div>
    <div v-else class="buyback-sync-progress" data-test="buyback-sync-progress">
      <p
        class="text-uppercase text-center"
        :class="{
          'text-warning': working || status === 'unsupported',
          'text-success': status === 'finished',
          'text-danger': status === 'failed',
        }"
      >
        <b>{{ t(`labels.buybackSync.status.${status}`) }}</b>
      </p>
      <p v-if="status === 'unsupported'" class="text-warning">
        {{ t("texts.buybackSync.unsupported") }}
      </p>
      <dl v-else class="row">
        <dt class="col-sm-7">{{ t("labels.buybackSync.pages") }}:</dt>
        <dd class="col-sm-5 text-right">{{ currentPage }}</dd>
        <dt class="col-sm-7">{{ t("labels.buybackSync.found") }}:</dt>
        <dd class="col-sm-5 text-right">{{ buybacks.length }}</dd>
        <template v-if="result">
          <dt class="col-sm-7">{{ t("labels.buybackSync.added") }}:</dt>
          <dd class="col-sm-5 text-right" data-test="buyback-sync-added">
            {{ result.added }}
          </dd>
          <dt class="col-sm-7">{{ t("labels.buybackSync.removed") }}:</dt>
          <dd class="col-sm-5 text-right" data-test="buyback-sync-removed">
            {{ result.removed }}
          </dd>
        </template>
        <template v-if="detailsStarted && detailsTotal">
          <dt class="col-sm-7">{{ t("labels.buybackSync.prices") }}:</dt>
          <dd class="col-sm-5 text-right" data-test="buyback-sync-prices">
            {{ detailsDone }} / {{ detailsTotal }}
          </dd>
        </template>
      </dl>
      <p
        v-if="status === 'finished' && detailsRunning"
        data-test="buyback-sync-details-background"
      >
        {{ t("texts.buybackSync.detailsBackground") }}
      </p>
      <p
        v-if="
          status === 'finished' &&
          result?.detailsPending.length &&
          !extensionSupportsDetails
        "
        class="text-warning"
        data-test="buyback-sync-details-unsupported"
      >
        {{ t("texts.buybackSync.detailsUnsupported") }}
      </p>
    </div>
    <template #footer>
      <Btn
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.LG"
        data-test="close-buyback-sync"
        @click="close"
      >
        {{
          status === "idle" || status === "fetching"
            ? t("actions.syncExtension.cancel")
            : t("actions.syncExtension.close")
        }}
      </Btn>
      <Btn
        v-if="
          extensionReady &&
          extensionSupportsBuybacks &&
          ['idle', 'failed'].includes(status)
        "
        :size="BtnSizesEnum.LG"
        data-test="start-buyback-sync"
        :loading="loadingIdentity"
        :disabled="
          identityStatus !== 'connected' || detailsRunning || hangarSyncRunning
        "
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
.sync-extension-platforms {
  margin-bottom: 20px;
}
</style>
