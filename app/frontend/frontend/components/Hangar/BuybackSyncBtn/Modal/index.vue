<script lang="ts">
export default {
  name: "HangarBuybackSyncModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import LoadingDots from "@/shared/components/LoadingDots/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { extensionUrls } from "@/types/extension";
import { extractBuybackPage } from "@/frontend/lib/RSIBuybackParser";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import { useRsiPageReport } from "@/frontend/composables/useRsiPageReport";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncEvent,
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
import { differenceInMinutes } from "date-fns";

type SyncStatus =
  | "idle"
  | "fetching"
  | "submitting"
  | "details"
  | "finished"
  | "unsupported"
  | "failed";

const { t } = useI18n();

const { displayInfo, displaySuccess, displayWarning, displayAlert } =
  useAppNotifications();

const comlink = useComlink();

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

const syncStartedAt = ref<Date>(new Date());

const fetchCount = ref(0);

const maxMessagesPerMinute = 60;

// An extension that never answers would otherwise leave the sync spinning.
const REPLY_TIMEOUT = 30000;

let replyTimer: ReturnType<typeof setTimeout> | null = null;

const working = computed(
  () =>
    loadingIdentity.value ||
    status.value === "fetching" ||
    status.value === "submitting" ||
    status.value === "details",
);

const onExtensionMessage = (event: FleetyardsSyncEvent) => {
  handleExtensionMessage(event).catch((error) => {
    console.error("Buy-back sync error:", error);
    fail();
  });
};

onMounted(() => {
  window.addEventListener("message", onExtensionMessage as EventListener);

  window.postMessage({
    direction: "fy",
    message: JSON.stringify({ action: FleetyardsSyncAction.HEALTH }),
  });
});

let unmounted = false;

onBeforeUnmount(() => {
  unmounted = true;

  if (status.value === "details") {
    cancelDetails();
  }
  window.removeEventListener("message", onExtensionMessage as EventListener);

  clearReplyTimer();
});

const handleExtensionMessage = async (event: FleetyardsSyncEvent) => {
  if (event.data.direction !== "fy-sync") {
    return;
  }

  const message = JSON.parse(event.data.message) as FleetyardsSyncMessage;

  if (message.action === FleetyardsSyncAction.HEALTH) {
    extensionReady.value = message.code === 200;
    extensionInfo.value =
      (message.payload as FleetyardsSyncHealthPayload | undefined) || {};

    if (extensionReady.value && extensionSupportsBuybacks.value) {
      checkRSIIdentity();
    }
  }

  if (message.action === FleetyardsSyncAction.IDENTIFY) {
    loadingIdentity.value = false;

    if (
      message.code !== 200 ||
      !(message.payload as FleetyardsSyncSessionPayload)?.handle
    ) {
      displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
      identityStatus.value = "notFound";
      rsiHandle.value = undefined;
    } else {
      identityStatus.value = "connected";
      rsiHandle.value = (
        message.payload as FleetyardsSyncSessionPayload
      ).handle;
    }
  }

  // A reply landing after the sync timed out belongs to a crawl that is over.
  if (
    message.action === FleetyardsSyncAction.SYNC_BUYBACK &&
    status.value === "fetching"
  ) {
    clearReplyTimer();

    if (message.code === 200) {
      await handlePage(message.payload as string);
    } else if (isUnknownAction(message)) {
      status.value = "unsupported";
    } else {
      fail();
    }
  }
};

const checkRSIIdentity = () => {
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  window.postMessage({
    direction: "fy",
    message: JSON.stringify({ action: FleetyardsSyncAction.IDENTIFY }),
  });
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
  currentPage.value = 1;
  syncStartedAt.value = new Date();
  fetchCount.value = 0;

  displayInfo({ text: t("messages.buybackSync.started") });

  fetchPage(currentPage.value);
};

// Every later page and every throttled retry arrives through a timer, which
// can fire after the sync failed or the modal closed.
const fetchPage = (page: number) => {
  if (unmounted || status.value !== "fetching") {
    return;
  }

  const elapsedMinutes = differenceInMinutes(new Date(), syncStartedAt.value);

  if (fetchCount.value >= (elapsedMinutes + 1) * maxMessagesPerMinute) {
    setTimeout(() => fetchPage(page), 500);
    return;
  }

  fetchCount.value += 1;

  window.postMessage({
    direction: "fy",
    message: JSON.stringify({
      action: FleetyardsSyncAction.SYNC_BUYBACK,
      page,
    }),
  });

  replyTimer = setTimeout(fail, REPLY_TIMEOUT);
};

const clearReplyTimer = () => {
  if (replyTimer) {
    clearTimeout(replyTimer);
    replyTimer = null;
  }
};

const fail = () => {
  clearReplyTimer();
  status.value = "failed";
  displayAlert({ text: t("messages.buybackSync.failure") });
};

const reportRsiPage = useRsiPageReport();

const handlePage = async (html: string) => {
  const page = extractBuybackPage(html);

  // Not a buy-back page this parser understands: the list read so far is
  // incomplete, and submitting it would delete every buy-back after it.
  if (page.unrecognised) {
    clearReplyTimer();
    status.value = "failed";
    displayAlert({ text: t("messages.syncExtension.pageNotRecognised") });
    reportRsiPage({
      page: RsiPageKindEnum.BUYBACK,
      check: page.unrecognised,
      pageNumber: currentPage.value,
      extensionVersion: extensionInfo.value.version,
    });
    return;
  }

  const newBuybacks = page.pledges.filter((pledge) => !seenIds.has(pledge.id));

  if (newBuybacks.length === 0) {
    await submit();
    return;
  }

  newBuybacks.forEach((pledge) => seenIds.add(pledge.id));
  buybacks.value = [...buybacks.value, ...newBuybacks];

  currentPage.value += 1;
  setTimeout(() => fetchPage(currentPage.value), 500);
};

// The detail pass runs after the list crawl and draws on the same budget of 60
// requests a minute since the sync started, so the two together stay inside it.
const waitForSlot = async () => {
  while (
    !unmounted &&
    fetchCount.value >=
      (differenceInMinutes(new Date(), syncStartedAt.value) + 1) *
        maxMessagesPerMinute
  ) {
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  fetchCount.value += 1;
};

const {
  status: detailsStatus,
  total: detailsTotal,
  done: detailsDone,
  run: runDetails,
  cancel: cancelDetails,
} = useBuybackDetailsSync({ waitForSlot });

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
    status.value = "details";

    await runDetails(buybacks.value, result.value.detailsPending);

    if (unmounted) {
      return;
    }

    comlink.emit("buyback-sync-finished");

    if (detailsStatus.value === "incomplete") {
      displayWarning({ text: t("texts.buybackSync.detailsIncomplete") });
    }
  }

  status.value = "finished";
  displaySuccess({ text: t("messages.buybackSync.success") });
};

const close = () => {
  comlink.emit("close-modal", true);
};
</script>

<template>
  <Modal :title="t('headlines.buybackSync')" :fixed="true" :loading="working">
    <div v-if="!extensionReady">
      <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
      <div class="sync-extension-platforms">
        <a
          v-for="link in extensionUrls"
          :key="`extension-link-${link.platform}`"
          v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
          :aria-label="t(`labels.syncExtension.platforms.${link.platform}`)"
          :href="link.url"
          target="_blank"
        >
          <i :class="`fa-brands fa-${link.platform}`" />
        </a>
      </div>
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
      <div class="sync-extension-platforms">
        <a
          v-for="link in extensionUrls"
          :key="`extension-update-link-${link.platform}`"
          v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
          :aria-label="t(`labels.syncExtension.platforms.${link.platform}`)"
          :href="link.url"
          target="_blank"
        >
          <i :class="`fa-brands fa-${link.platform}`" />
        </a>
      </div>
    </div>
    <div v-else-if="status === 'idle'">
      <p
        class="flex justify-center gap-2 text-uppercase relative mt-4"
        :class="{
          'text-warning': identityStatus === 'pending',
          'text-success': identityStatus === 'connected',
          'text-danger': identityStatus === 'notFound',
        }"
      >
        {{ t("labels.syncExtension.sessionStatus") }}:
        {{ t(`labels.syncExtension.identityStatus.${identityStatus}`) }}
        <LoadingDots :loading="loadingIdentity" />
        <Btn
          v-if="identityStatus === 'notFound'"
          v-tooltip="t('labels.syncExtension.checkIdentity')"
          class="check-identity-btn"
          :disabled="loadingIdentity"
          :variant="BtnVariantsEnum.BARE"
          @click="checkRSIIdentity"
        >
          <i class="fa-light fa-sync" />
        </Btn>
      </p>
      <p
        v-if="identityStatus === 'connected' && rsiHandle"
        class="text-center"
        data-test="sync-extension-signed-in-as"
      >
        {{ t("labels.syncExtension.signedInAs", { handle: rsiHandle }) }}
      </p>
      <p>{{ t("texts.buybackSync.info") }}</p>
      <p v-if="extensionSupportsDetails">
        {{ t("texts.buybackSync.detailsInfo") }}
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
        <template v-if="detailsTotal">
          <dt class="col-sm-7">{{ t("labels.buybackSync.prices") }}:</dt>
          <dd class="col-sm-5 text-right" data-test="buyback-sync-prices">
            {{ detailsDone }} / {{ detailsTotal }}
          </dd>
        </template>
      </dl>
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
        data-test="close-buyback-sync"
        :disabled="working && !['idle', 'details'].includes(status)"
        @click="close"
      >
        {{
          status === "finished"
            ? t("actions.syncExtension.close")
            : t("actions.syncExtension.cancel")
        }}
      </Btn>
      <Btn
        v-if="
          extensionReady &&
          extensionSupportsBuybacks &&
          ['idle', 'failed'].includes(status)
        "
        data-test="start-buyback-sync"
        :loading="loadingIdentity"
        :disabled="identityStatus !== 'connected'"
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

.check-identity-btn {
  margin-left: 10px;
}
</style>
