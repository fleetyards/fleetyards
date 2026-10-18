<script lang="ts">
export default {
  name: "VehiclesResetIngameModal",
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
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useRouter, useRoute } from "vue-router";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import SyncSessionStatus from "@/frontend/components/Hangar/SyncSessionStatus/index.vue";
import HangarGroupsSelect from "@/frontend/components/base/HangarGroupsSelect/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import SyncResultPanel from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";
import { isSyncStepRunning } from "@/frontend/components/Hangar/SyncBtn/Result/status";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  HangarSyncOutcomeEnum,
  HangarSyncUnmatchedActionEnum,
} from "@/services/fyApi";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { useHangarSync } from "@/frontend/composables/useHangarSync";

const { t } = useI18n();

const { displayWarning } = useAppNotifications();

const identityStatus = ref<"pending" | "connected" | "notFound">("pending");

// The RSI account the extension found signed in, shown so a sync into the
// wrong hangar is caught before it starts.
const rsiHandle = ref<string>();

const loadingIdentity = ref(false);

const hangarStore = useHangarStore();

const hangarSync = useHangarSync();

const {
  started,
  processSteps,
  currentPage,
  pledges,
  result,
  finished,
  finishedWithErrors,
  retryable,
  cancelled,
  running,
  fetching,
} = hangarSync;

const hangarGroupId = ref<string | undefined>(undefined);

// Declared order rather than alphabetical: it runs from the least destructive
// answer to the most, and "wishlist" first is what a sync has always done.
const unmatchedActionOptions = computed(() =>
  [
    HangarSyncUnmatchedActionEnum.WISHLIST,
    HangarSyncUnmatchedActionEnum.DELETE,
    HangarSyncUnmatchedActionEnum.KEEP,
    HangarSyncUnmatchedActionEnum.GROUP,
  ].map((value) => ({
    value,
    label: t(`labels.syncExtension.unmatchedVehiclesActions.${value}`),
  })),
);

const unmatchedActionLabel = computed(() =>
  t(
    `labels.syncExtension.unmatchedVehiclesActions.${hangarStore.syncUnmatchedVehiclesAction}`,
  ),
);

// The settings a run reads, in the order they are listed: the least
// destructive first, as the sync options have always been shown.
const syncToggles = [
  { name: "syncAddBundledVehicles", label: "addBundledVehicles" },
  { name: "syncPaints", label: "syncPaints" },
  { name: "syncHangarFlair", label: "syncHangarFlair" },
  { name: "syncEquipment", label: "syncEquipment" },
  { name: "syncCcus", label: "syncCcus" },
] as const;

const filesUnmatchedIntoGroup = computed(
  () =>
    hangarStore.syncUnmatchedVehiclesAction ===
    HangarSyncUnmatchedActionEnum.GROUP,
);

const settingsOpen = ref(false);

// `group` with no group is not that action: the endpoint falls back to leaving
// the ships alone, which is not what the modal would be showing the user.
const missingUnmatchedGroup = computed(
  () =>
    filesUnmatchedIntoGroup.value && !hangarStore.syncUnmatchedHangarGroupId,
);

// The toggles live behind the cog and are remembered, so a user who turned
// one off once would otherwise start every later sync without seeing it.
const skippedItems = computed(() => [
  ...(hangarStore.syncPaints
    ? []
    : [t("labels.syncExtension.pledgeItems.paints")]),
  ...(hangarStore.syncHangarFlair
    ? []
    : [t("labels.syncExtension.pledgeItems.hangarFlair")]),
  ...(hangarStore.syncEquipment
    ? []
    : [t("labels.syncExtension.pledgeItems.equipment")]),
  ...(hangarStore.syncCcus ? [] : [t("labels.syncExtension.pledgeItems.ccus")]),
]);

// Only once Start could be pressed: a check mid-run would spend an RSI request
// and warn about a session the run already has.
onMounted(() => {
  hangarStore.syncModalOpen = true;

  if (hangarStore.extensionReady && !running.value) {
    void checkRSIIdentity();
  }
});

let unmounted = false;

// A run still going is what the modal opens on next time, and so is one that
// ended in the background, until its result has been shown here once.
onBeforeUnmount(() => {
  unmounted = true;
  hangarStore.syncModalOpen = false;
  hangarSync.reset();
});

watch(
  () => hangarStore.extensionReady,
  () => {
    if (hangarStore.extensionReady && !running.value) {
      void checkRSIIdentity();
    }
  },
);

// A read that failed may have failed on the session; the run has already said
// so, so the check only updates what Start relies on.
watch(finishedWithErrors, (failed) => {
  if (failed && hangarStore.extensionReady) {
    void checkRSIIdentity({ quiet: true });
  }
});

const extension = useSyncExtension();

// Only the latest check answers: retry can be pressed while one is out.
let identityCheck = 0;

const checkRSIIdentity = async ({ quiet = false } = {}) => {
  const current = ++identityCheck;
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  const identity = await extension
    .request(FleetyardsSyncAction.IDENTIFY)
    .catch(() => undefined);
  // A check still out when the modal closed answers nobody.
  if (unmounted || current !== identityCheck) return;
  const handle = (identity?.payload as FleetyardsSyncSessionPayload)?.handle;

  loadingIdentity.value = false;

  if (identity?.code !== 200 || !handle) {
    console.info("FY Extension: No RSI Session found");
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

// The run's state names the dialog; the sync it is stays above as the eyebrow.
const headline = computed(() => t("headlines.syncExtension"));

const title = computed(() => {
  if (!hangarStore.extensionReady) {
    return t("labels.syncExtension.extensionNeededTitle");
  }
  if (!started.value) {
    return settingsOpen.value
      ? t("labels.syncExtension.settings")
      : headline.value;
  }
  if (finished.value) return t("labels.syncExtension.finishedTitle");
  if (cancelled.value) return t("labels.syncExtension.backgroundCancelled");
  if (finishedWithErrors.value || retryable.value) {
    return t("labels.syncExtension.failedTitle");
  }

  return t("labels.syncExtension.backgroundProgress");
});

const eyebrow = computed(() =>
  title.value === headline.value ? undefined : headline.value,
);

// Checking the RSI identity or running a step: the modal's bottom cap says so.
const working = computed(
  () => loadingIdentity.value || isSyncStepRunning(processSteps.value),
);

// Runs from before the sync reported an outcome always synced.
const syncedSomething = computed(
  () =>
    !result.value?.outcome ||
    result.value.outcome === HangarSyncOutcomeEnum.SYNCED,
);

const supportPrompt = useSupportPrompt();
const supportHintDismissed = ref(false);
const showSupportHint = computed(
  () =>
    finished.value &&
    !finishedWithErrors.value &&
    syncedSomething.value &&
    !supportHintDismissed.value &&
    supportPrompt.canShow(),
);

const comlink = useComlink();

const close = () => {
  comlink.emit("close-modal", true);
};

const cancelRun = () => {
  hangarSync.cancel();
  close();
};

const start = () => {
  hangarSync.start({
    hangarGroupId: hangarGroupId.value,
    addBundledVehicles: hangarStore.syncAddBundledVehicles,
    syncPaints: hangarStore.syncPaints,
    syncHangarFlair: hangarStore.syncHangarFlair,
    syncEquipment: hangarStore.syncEquipment,
    syncCcus: hangarStore.syncCcus,
    unmatchedVehiclesAction: hangarStore.syncUnmatchedVehiclesAction,
    unmatchedHangarGroupId: filesUnmatchedIntoGroup.value
      ? hangarStore.syncUnmatchedHangarGroupId
      : undefined,
    extensionVersion: hangarStore.extensionVersion,
  });
};

const router = useRouter();
const route = useRoute();

const refreshPage = async () => {
  await router.replace({
    name: "hangar",
    query: { ...route.query, openSync: "1" },
  });
  window.location.reload();
};
</script>

<template>
  <Modal :title="title" :eyebrow="eyebrow" :loading="working">
    <transition name="fade" mode="out-in">
      <div v-if="!hangarStore.extensionReady" class="hangar-sync">
        <p class="hangar-sync__text">
          {{ t("texts.syncExtension.gettingStarted") }}
        </p>
        <SyncExtensionLinks list />
      </div>
      <div v-else-if="!started" class="hangar-sync">
        <div
          v-if="settingsOpen"
          class="hangar-sync hangar-sync--settings"
          data-test="sync-settings"
        >
          <section class="hangar-sync__section">
            <h3 class="hangar-sync__heading">
              {{ t("labels.syncExtension.whatToSync") }}
            </h3>
            <div class="hangar-sync__list">
              <div
                v-for="setting in syncToggles"
                :key="setting.name"
                class="hangar-sync__setting"
              >
                <FormToggle
                  v-model="hangarStore[setting.name]"
                  :name="setting.name"
                  autosaved
                  :label="t(`labels.syncExtension.${setting.label}`)"
                  no-placeholder
                />
                <p class="hangar-sync__hint">
                  {{ t(`labels.syncExtension.${setting.label}Hint`) }}
                </p>
              </div>
            </div>
          </section>
          <section class="hangar-sync__section">
            <h3 class="hangar-sync__heading">
              {{ t("labels.syncExtension.unmatchedVehiclesAction") }}
            </h3>
            <p class="hangar-sync__hint">
              {{ t("labels.syncExtension.unmatchedVehiclesActionHint") }}
            </p>
            <div class="hangar-sync__fields">
              <BaseSelect
                v-model="hangarStore.syncUnmatchedVehiclesAction"
                name="syncUnmatchedVehiclesAction"
                autosaved
                :options="unmatchedActionOptions"
                :label="t('labels.syncExtension.unmatchedActionLabel')"
                :searchable="false"
                :paginated="false"
                :nullable="false"
                :no-label="false"
                unsorted
              />
              <HangarGroupsSelect
                v-if="filesUnmatchedIntoGroup"
                v-model="hangarStore.syncUnmatchedHangarGroupId"
                name="syncUnmatchedHangarGroupId"
                autosaved
                :multiple="false"
                :no-label="false"
                :label="t('labels.syncExtension.unmatchedHangarGroup')"
                :info="t('labels.syncExtension.unmatchedHangarGroupHint')"
              />
            </div>
          </section>
        </div>
        <div v-else class="hangar-sync">
          <SyncSessionStatus
            :status="identityStatus"
            :loading="loadingIdentity"
            :handle="rsiHandle"
            :hint="t('texts.syncExtension.sessionHint')"
            @recheck="checkRSIIdentity"
          />
          <ul class="hangar-sync__points">
            <li>
              <i class="fa-light fa-arrow-right" aria-hidden="true" />
              {{ t("texts.syncExtension.pointMatch") }}
            </li>
            <li>
              <i class="fa-light fa-plus" aria-hidden="true" />
              {{ t("texts.syncExtension.pointAdd") }}
            </li>
          </ul>
          <dl class="hangar-sync__list hangar-sync__summary">
            <div class="hangar-sync__summary-row">
              <div class="hangar-sync__summary-text">
                <dt>{{ t("labels.syncExtension.unmatchedVehiclesAction") }}</dt>
                <dd>{{ unmatchedActionLabel }}</dd>
              </div>
              <Btn
                :variant="BtnVariantsEnum.BARE"
                data-test="open-sync-settings"
                @click="settingsOpen = true"
              >
                {{ t("actions.syncExtension.change") }}
              </Btn>
            </div>
            <div
              v-if="skippedItems.length"
              class="hangar-sync__summary-row"
              data-test="sync-skipped-items"
            >
              <div class="hangar-sync__summary-text">
                <dt>{{ t("labels.syncExtension.notSyncing") }}</dt>
                <dd class="hangar-sync__chips">
                  <span
                    v-for="item in skippedItems"
                    :key="item"
                    class="hangar-sync__chip"
                  >
                    {{ item }}
                  </span>
                </dd>
              </div>
              <Btn :variant="BtnVariantsEnum.BARE" @click="settingsOpen = true">
                {{ t("actions.syncExtension.change") }}
              </Btn>
            </div>
          </dl>
          <Alert
            v-if="missingUnmatchedGroup"
            :variant="AlertVariantsEnum.WARNING"
            :size="AlertSizesEnum.COMPACT"
            data-test="sync-missing-unmatched-group"
          >
            {{ t("texts.syncExtension.missingUnmatchedGroup") }}
          </Alert>
          <HangarGroupsSelect
            v-model="hangarGroupId"
            name="hangarGroupId"
            :multiple="false"
            :no-label="false"
            :label="t('labels.syncExtension.targetGroup')"
            :info="t('labels.syncExtension.targetGroupHint')"
          />
          <Alert
            v-if="hangarStore.syncRunning"
            :variant="AlertVariantsEnum.WARNING"
            :size="AlertSizesEnum.COMPACT"
          >
            {{ t("texts.syncExtension.alreadyRunning") }}
          </Alert>
        </div>
      </div>
      <div v-else>
        <SyncResultPanel
          :process-steps="processSteps"
          :current-page="currentPage"
          :pledges="pledges"
          :result="result"
          :finished="finished"
          :finished-with-errors="finishedWithErrors"
          :cancelled="cancelled"
          :show-support-hint="showSupportHint"
          :sync-paints="hangarStore.syncPaints"
          :sync-hangar-flair="hangarStore.syncHangarFlair"
          :sync-equipment="hangarStore.syncEquipment"
          :sync-ccus="hangarStore.syncCcus"
          @support-hint-dismiss="supportHintDismissed = true"
        />
      </div>
    </transition>
    <template
      v-if="!finished && hangarStore.extensionReady && !started"
      #footer-start
    >
      <Btn
        v-if="settingsOpen"
        :variant="BtnVariantsEnum.BARE"
        data-test="close-sync-settings"
        @click="settingsOpen = false"
      >
        <i class="fa-light fa-chevron-left" />
        {{ t("actions.back") }}
      </Btn>
      <Btn
        v-else
        :variant="BtnVariantsEnum.BARE"
        data-test="toggle-sync-settings"
        @click="settingsOpen = true"
      >
        <i class="fa-light fa-gear" />
        {{ t("labels.syncExtension.settings") }}
      </Btn>
    </template>
    <template #footer>
      <Btn
        v-if="finished"
        :variant="BtnVariantsEnum.BARE"
        data-test="close-sync"
        @click="close"
      >
        {{ t("actions.syncExtension.close") }}
      </Btn>
      <template
        v-else-if="!settingsOpen || !hangarStore.extensionReady || started"
      >
        <Btn
          v-if="!running || fetching"
          :variant="BtnVariantsEnum.BARE"
          data-test="cancel-sync"
          @click="cancelRun"
        >
          {{
            started && !fetching
              ? t("actions.syncExtension.close")
              : t("actions.syncExtension.cancel")
          }}
        </Btn>
        <Btn v-if="running" data-test="background-sync" @click="close">
          {{ t("actions.syncExtension.runInBackground") }}
        </Btn>
        <Btn
          v-else-if="retryable"
          data-test="start-sync"
          @click="hangarSync.retry"
        >
          {{ t("actions.syncExtension.retry") }}
        </Btn>
        <Btn
          v-else-if="hangarStore.extensionReady"
          data-test="start-sync"
          :loading="loadingIdentity"
          :disabled="
            identityStatus !== 'connected' ||
            hangarStore.syncRunning ||
            missingUnmatchedGroup
          "
          @click="start"
        >
          {{ t("actions.syncExtension.start") }}
        </Btn>
        <Btn v-else data-test="recheck-sync" @click="refreshPage">
          {{ t("actions.syncExtension.refresh") }}
        </Btn>
      </template>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
