<template>
  <Modal :title="t('headlines.syncExtension')">
    <transition name="fade" mode="out-in">
      <div v-if="!extensionReady">
        <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
        <div class="sync-extension-platforms">
          <a
            v-for="link in extensionUrls"
            :key="`extension-link-${link.platform}`"
            v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
            :href="link.url"
            target="_blank"
          >
            <i :class="`fab fa-${link.platform}`" />
          </a>
        </div>
      </div>
      <div v-else-if="!started">
        <p
          class="flex justify-content-center text-uppercase relative"
          :class="{
            'text-warning': identityStatus === 'pending',
            'text-success': identityStatus === 'connected',
            'text-danger': identityStatus === 'notFound',
          }"
        >
          {{ t("labels.syncExtension.sessionStatus") }}:
          {{ t(`labels.syncExtension.identityStatus.${identityStatus}`) }}
          <SmallLoader :loading="loadingIdentity" alignment="right" />
          <Btn
            v-if="identityStatus === 'notFound'"
            v-tooltip="t('labels.syncExtension.checkIdentity')"
            size="small"
            variant="link"
            class="check-identity-btn"
            :text-inline="true"
            :disabled="loadingIdentity"
            @click.native="checkRSIIdentity"
          >
            <i class="fal fa-sync" />
          </Btn>
        </p>
        <p v-html="t('texts.syncExtension.info')" />
      </div>
      <div v-else>
        <p
          class="flex justify-content-center text-uppercase"
          :class="{
            'text-warning': !finished && !finishedWithErrors,
            'text-success': finished,
            'text-danger': finishedWithErrors,
          }"
        >
          <b v-if="finished">{{ t("labels.syncExtension.status.finished") }}</b>
          <b v-else-if="finishedWithErrors">
            {{ t("labels.syncExtension.status.failed") }}
          </b>
          <b v-else>{{ t("labels.syncExtension.status.started") }}</b>
        </p>
        <ul v-if="processSteps.length" class="list-unstyled process-steps-list">
          <li
            v-for="step in processSteps.filter(
              (step) => step.status !== 'pending',
            )"
            :key="step.name"
            class="process-steps-item"
            :class="{
              'text-muted': step.status === 'pending',
            }"
          >
            <div class="process-steps-item-title">
              <p>{{ t(`labels.syncExtension.processSteps.${step.name}`) }}</p>
              <SmallLoader
                :loading="step.status === 'processing'"
                alignment="right"
              />
              <i
                v-if="step.status === 'success'"
                class="fal fa-check text-success"
              />
              <i
                v-if="step.status === 'failure'"
                class="fal fa-times text-danger"
              />
            </div>
            <div
              v-if="step.name === 'fetchHangar'"
              class="process-steps-item-info"
            >
              <dl class="row">
                <dt class="col-sm-7">
                  {{ t("labels.syncExtension.pledgeItems.pages") }}:
                </dt>
                <dd class="col-sm-5 text-right">{{ currentPage }}</dd>
                <template v-if="items.length">
                  <dt class="col-sm-7">
                    {{ t("labels.syncExtension.pledgeItems.all") }}:
                  </dt>
                  <dd class="col-sm-5 text-right">{{ items.length }}</dd>
                </template>
                <template v-if="ships.length">
                  <dt class="col-sm-7">
                    {{ t("labels.syncExtension.pledgeItems.ships") }}:
                  </dt>
                  <dd class="col-sm-5 text-right">{{ ships.length }}</dd>
                </template>
                <template v-if="components.length">
                  <dt class="col-sm-7">
                    {{ t("labels.syncExtension.pledgeItems.components") }}:
                  </dt>
                  <dd class="col-sm-5 text-right">{{ components.length }}</dd>
                </template>
                <template v-if="upgrades.length">
                  <dt class="col-sm-7">
                    {{ t("labels.syncExtension.pledgeItems.upgrades") }}:
                  </dt>
                  <dd class="col-sm-5 text-right">{{ upgrades.length }}</dd>
                </template>
              </dl>
            </div>
            <div
              v-if="step.name === 'submitData'"
              class="process-steps-item-info"
            >
              <dl class="row">
                <template v-if="importedVehicles.length">
                  <dt class="col-sm-8">
                    {{
                      t("labels.syncExtension.importedItems.importedVehicles")
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ importedVehicles.length }}
                  </dd>
                </template>
                <template v-if="foundVehicles.length">
                  <dt class="col-sm-8">
                    {{ t("labels.syncExtension.importedItems.foundVehicles") }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ foundVehicles.length }}
                  </dd>
                </template>
                <template v-if="movedVehiclesToWanted.length">
                  <dt class="col-sm-8">
                    {{
                      t(
                        "labels.syncExtension.importedItems.movedVehiclesToWanted",
                      )
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ movedVehiclesToWanted.length }}
                  </dd>
                </template>
                <template v-if="missingModels.length">
                  <dt class="col-sm-8">
                    {{ t("labels.syncExtension.importedItems.missingModels") }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ missingModels.length }}
                  </dd>
                  <ul>
                    <li
                      v-for="item in missingModels"
                      :key="`missing-ship-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </template>
                <template v-if="importedComponents.length">
                  <dt class="col-sm-8">
                    {{
                      t(
                        "labels.syncExtension.importedItems.importedComponents",
                      )
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ importedComponents.length }}
                  </dd>
                </template>
                <template v-if="foundComponents.length">
                  <dt class="col-sm-8">
                    {{
                      t("labels.syncExtension.importedItems.foundComponents")
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ foundComponents.length }}
                  </dd>
                </template>
                <template v-if="missingComponents.length">
                  <dt class="col-sm-8">
                    {{
                      t("labels.syncExtension.importedItems.missingComponents")
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ missingComponents.length }}
                  </dd>
                  <ul>
                    <li
                      v-for="item in missingComponents"
                      :key="`missing-component-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </template>
                <template v-if="missingComponentVehicles.length">
                  <dt class="col-sm-8">
                    {{
                      t(
                        "labels.syncExtension.importedItems.missingComponentVehicles",
                      )
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ missingComponentVehicles.length }}
                  </dd>
                  <ul>
                    <li
                      v-for="item in missingComponentVehicles"
                      :key="`missing-component-vehicle-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </template>
                <template v-if="importedUpgrades.length">
                  <dt class="col-sm-8">
                    {{
                      t("labels.syncExtension.importedItems.importedUpgrades")
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ importedUpgrades.length }}
                  </dd>
                </template>
                <template v-if="foundUpgrades.length">
                  <dt class="col-sm-8">
                    {{ t("labels.syncExtension.importedItems.foundUpgrades") }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ foundUpgrades.length }}
                  </dd>
                </template>
                <template v-if="missingUpgrades.length">
                  <dt class="col-sm-8">
                    {{
                      t("labels.syncExtension.importedItems.missingUpgrades")
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ missingUpgrades.length }}
                  </dd>
                  <ul>
                    <li
                      v-for="item in missingUpgrades"
                      :key="`missing-component-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </template>
                <template v-if="missingUpgradeVehicles.length">
                  <dt class="col-sm-8">
                    {{
                      t(
                        "labels.syncExtension.importedItems.missingUpgradeVehicles",
                      )
                    }}:
                  </dt>
                  <dd class="col-sm-4 text-right">
                    {{ missingUpgradeVehicles.length }}
                  </dd>
                  <ul>
                    <li
                      v-for="item in missingUpgradeVehicles"
                      :key="`missing-component-vehicle-${item}`"
                    >
                      {{ item }}
                    </li>
                  </ul>
                </template>
              </dl>
            </div>
          </li>
        </ul>
      </div>
    </transition>
    <div class="page-actions page-actions-block">
      <Btn
        v-if="finished"
        size="small"
        :inline="true"
        data-test="close-sync"
        @click.native="cancel"
      >
        {{ t("actions.syncExtension.close") }}
      </Btn>
      <template v-else>
        <Btn
          size="small"
          :inline="true"
          data-test="cancel-sync"
          :disabled="started && !finishedWithErrors"
          @click.native="cancel"
        >
          {{ t("actions.syncExtension.cancel") }}
        </Btn>
        <Btn
          v-if="retryable"
          :inline="true"
          data-test="start-sync"
          @click.native="finishSync"
        >
          {{ t("actions.syncExtension.retry") }}
        </Btn>
        <Btn
          v-else-if="extensionReady"
          :inline="true"
          data-test="start-sync"
          :loading="started || loadingIdentity"
          :disabled="identityStatus !== 'connected'"
          @click.native="start"
        >
          {{ t("actions.syncExtension.start") }}
        </Btn>
        <Btn
          v-else
          :inline="true"
          data-test="recheck-sync"
          @click.native="refreshPage"
        >
          {{ t("actions.syncExtension.refresh") }}
        </Btn>
      </template>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import SmallLoader from "@/frontend/core/components/SmallLoader/index.vue";
import {
  displayInfo,
  displaySuccess,
  displayWarning,
  displayAlert,
} from "@/frontend/lib/Noty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";
import { RSIHangarParser } from "@/frontend/lib/RSIHangarParser";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";
import type { VehiclesCollection } from "@/frontend/api/collections/Vehicles";
import Store from "@/frontend/lib/Store";
import { useRouter, useRoute } from "vue-router/composables";
import { extensionUrls } from "@/types/extension";
import {
  type FleetyardsSyncMessage,
  type FleetyardsSyncEvent,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { differenceInMinutes } from "date-fns";

const started = ref(false);

const identityStatus = ref<"pending" | "connected" | "notFound">("pending");

const loadingIdentity = ref(false);

const currentPage = ref(1);

const syncStartedAt = ref<Date>(new Date());

const fetchCount = ref(0);

const maxMessagesPerMinute = 60;

const extensionReady = computed(() => Store.getters["hangar/extensionReady"]);

const pledges = ref<TRSIHangarItem[]>([]);

const items = computed(() =>
  pledges.value.filter((pledge) =>
    ["ship", "component", "upgrade"].includes(pledge.type),
  ),
);

const ships = computed(() =>
  pledges.value.filter((pledge) => pledge.type === "ship"),
);

const components = computed(() =>
  pledges.value.filter((pledge) => pledge.type === "component"),
);

const upgrades = computed(() =>
  pledges.value.filter((pledge) => pledge.type === "upgrade"),
);

const result = ref<THangarSyncResult | null>(null);

const importedVehicles = computed(() => result.value?.importedVehicles || []);
const foundVehicles = computed(() => result.value?.foundVehicles || []);
const movedVehiclesToWanted = computed(
  () => result.value?.movedVehiclesToWanted || [],
);
const missingModels = computed(() => result.value?.missingModels || []);
const importedComponents = computed(
  () => result.value?.importedComponents || [],
);
const foundComponents = computed(() => result.value?.foundComponents || []);
const missingComponents = computed(() => result.value?.missingComponents || []);
const missingComponentVehicles = computed(
  () => result.value?.missingComponentVehicles || [],
);
const importedUpgrades = computed(() => result.value?.importedUpgrades || []);
const foundUpgrades = computed(() => result.value?.foundUpgrades || []);
const missingUpgrades = computed(() => result.value?.missingUpgrades || []);
const missingUpgradeVehicles = computed(
  () => result.value?.missingUpgradeVehicles || [],
);

const retryable = computed(() => {
  const submitDataStatus = processSteps.value.find(
    (step) => step.name === "submitData",
  )?.status;

  return submitDataStatus === "backendFailure" && pledges.value.length > 0;
});

const collection: VehiclesCollection = vehiclesCollection;

type ProcessStep = {
  name: string;
  status: "pending" | "processing" | "success" | "failure" | "backendFailure";
};

const processSteps = ref<ProcessStep[]>([
  {
    name: "fetchHangar",
    status: "pending",
  },
  {
    name: "submitData",
    status: "pending",
  },
]);

onMounted(() => {
  started.value = false;
  currentPage.value = 1;

  window.addEventListener("message", handleExtensionMessage);

  if (extensionReady.value) {
    checkRSIIdentity();
  }
});

onBeforeUnmount(() => {
  window.removeEventListener("message", handleExtensionMessage);
});

const handleExtensionMessage = (event: FleetyardsSyncEvent) => {
  if (event.data.direction === "fy-sync") {
    const message = JSON.parse(event.data.message) as FleetyardsSyncMessage;

    if (message.action === "sync") {
      if (message.code === 200) {
        fetchRSIHangar(message.payload as string);
      } else {
        displayAlert({ text: t("messages.syncExtension.failure") });
        updateStep("fetchHangar", "failure");
      }
    }

    if (message.action === "identify") {
      loadingIdentity.value = false;
      if (
        message.code !== 200 ||
        !(message.payload as FleetyardsSyncSessionPayload)?.handle
      ) {
        console.info("FY Extension: No RSI Session found");
        displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
        identityStatus.value = "notFound";
      } else {
        identityStatus.value = "connected";
      }
    }
  }
};

watch(
  () => extensionReady.value,
  () => {
    if (extensionReady.value) {
      checkRSIIdentity();
    }
  },
);

const checkRSIIdentity = () => {
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  window.postMessage({
    direction: "fy",
    message: '{ "action": "identify" }',
  });
};

const updateStep = (step: string, status: ProcessStep["status"]) => {
  const index = processSteps.value.findIndex((s) => s.name === step);

  if (index !== -1) {
    processSteps.value[index].status = status;
  }
};

const finished = computed(() =>
  processSteps.value.every((step) => step.status === "success"),
);

const finishedWithErrors = computed(() =>
  processSteps.value.some((step) => step.status === "failure"),
);

const { t } = useI18n();

const comlink = useComlink();

const cancel = async () => {
  comlink.$emit("close-modal", true);
};

const start = () => {
  started.value = true;
  pledges.value = [];
  currentPage.value = 1;
  syncStartedAt.value = new Date();
  fetchCount.value = 0;

  fetchPage(currentPage.value);

  displayInfo({ text: t("messages.syncExtension.started") });
};

const fetchPage = (page: number) => {
  const elapsedMinutes = differenceInMinutes(new Date(), syncStartedAt.value);

  const allowedMessages = (elapsedMinutes + 1) * maxMessagesPerMinute;

  if (fetchCount.value >= allowedMessages) {
    setTimeout(() => {
      fetchPage(page);
    }, 500);

    return;
  }

  fetchCount.value += 1;

  window.postMessage({
    direction: "fy",
    message: `{ "action": "sync", "page": ${page} }`,
  });
};

const fetchRSIHangar = (htmlPage: string) => {
  updateStep("fetchHangar", "processing");

  const items = new RSIHangarParser().extractPage(htmlPage);

  if (items) {
    pledges.value = [...pledges.value, ...items];

    currentPage.value += 1;

    setTimeout(() => fetchPage(currentPage.value), 500);
  } else {
    updateStep("fetchHangar", "success");

    finishSync();
  }
};

const finishSync = async () => {
  updateStep("submitData", "processing");

  result.value = await collection.syncRsiHangar(pledges.value);

  if (result.value) {
    displaySuccess({ text: t("messages.syncExtension.success") });
    updateStep("submitData", "success");
    comlink.$emit("hangar-sync-finished");
  } else {
    updateStep("submitData", "backendFailure");
  }
};

const router = useRouter();
const route = useRoute();

const refreshPage = () => {
  router.replace({
    name: "hangar",
    query: { ...route.query, openSync: "1" },
  });
  window.location.reload();
};
</script>

<script lang="ts">
export default {
  name: "VehiclesResetIngameModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
