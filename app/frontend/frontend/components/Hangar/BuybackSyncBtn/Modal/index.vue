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

const {
  total: detailsTotal,
  done: detailsDone,
  running: detailsRunning,
} = useBuybackDetailsSync();

const working = computed(() => loadingIdentity.value || running.value);

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
  !running.value &&
  extensionReady.value &&
  extensionSupportsBuybacks.value;

watch(running, () => {
  if (canStart()) void checkRSIIdentity();
});

onMounted(() => {
  hangarStore.buybackSyncModalOpen = true;
  void checkExtension();
});

// A run still going is what the modal opens on next time, and so is one that
// ended in the background, until its result has been shown here once.
onBeforeUnmount(() => {
  unmounted = true;
  hangarStore.buybackSyncModalOpen = false;
  buybackSync.reset();
});

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
  <Modal :title="t('headlines.buybackSync')" :loading="working">
    <!-- A run already going is shown at once, not after the extension check. -->
    <div v-if="status === 'idle' && !extensionReady">
      <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
      <SyncExtensionLinks />
    </div>
    <div
      v-else-if="status === 'idle' && !extensionSupportsBuybacks"
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
        v-if="!running || status === 'fetching'"
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.LG"
        data-test="close-buyback-sync"
        @click="cancelRun"
      >
        {{
          status === "idle" || status === "fetching"
            ? t("actions.syncExtension.cancel")
            : t("actions.syncExtension.close")
        }}
      </Btn>
      <Btn
        v-if="running"
        :size="BtnSizesEnum.LG"
        data-test="background-buyback-sync"
        @click="close"
      >
        {{ t("actions.syncExtension.runInBackground") }}
      </Btn>
      <Btn
        v-else-if="
          extensionReady &&
          extensionSupportsBuybacks &&
          ['idle', 'failed'].includes(status)
        "
        :size="BtnSizesEnum.LG"
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
.sync-extension-platforms {
  margin-bottom: 20px;
}
</style>
