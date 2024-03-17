<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ t("headlines.hangar.index") }}
            </h1>
          </div>
        </div>
        <div class="hangar-header">
          <div class="hangar-labels">
            <ModelClassLabels
              v-if="hangarStats"
              :count-data="hangarStats.classifications"
              :label="t('labels.hangar')"
              filter-key="classificationIn"
            />
            <GroupLabels
              v-if="hangarStats && hangarGroups"
              :hangar-groups="hangarGroups"
              :hangar-group-counts="hangarGroupCounts"
              :label="t('labels.groups')"
              :editable="true"
              @highlight="highlightGroup"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Btn :to="{ name: 'hangar-wishlist' }">
              <i class="fad fa-wand-sparkles" />
              {{ t("labels.wishlist") }}
              <transition name="fade" mode="out-in" appear>
                <span v-if="hangarStats && hangarStats.wishlistTotal">
                  ({{ hangarStats.wishlistTotal }})
                </span>
              </transition>
            </Btn>

            <Btn data-test="fleetchart-link" @click="toggleFleetchart">
              <i class="fad fa-starship" />
              {{ t("labels.fleetchart") }}
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }">
              <i class="fal fa-chart-bar" />
              {{ t("labels.hangarStats") }}
            </Btn>

            <ShareBtn
              v-if="currentUser && currentUser.publicHangar && shareUrl"
              :url="shareUrl"
              :title="shareTitle"
            />
          </div>
        </div>
        <div v-if="hangarStats && !mobile" class="row">
          <div class="col-12 hangar-metrics metrics-block" @click="toggleMoney">
            <div v-if="money" class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.totalMoney") }}:
              </div>
              <div class="metrics-value">
                {{ toDollar(hangarStats.metrics.totalMoney) }}
              </div>
            </div>
            <div v-if="money" class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.totalCredits") }}:
              </div>
              <div class="metrics-value">
                <span v-html="toUEC(hangarStats.metrics.totalCredits)" />
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.total") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(hangarStats.total, "ships") }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.totalMinCrew") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(hangarStats.metrics.totalMinCrew, "people") }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.totalMaxCrew") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(hangarStats.metrics.totalMaxCrew, "people") }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t("labels.hangarMetrics.totalCargo") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(hangarStats.metrics.totalCargo, "cargo") }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <FilteredList
      key="hangar"
      :paginated="true"
      :hide-loading="fleetchartVisible"
      :hide-empty-box="!gridView"
      :records="vehicles?.items || []"
      :name="route.name?.toString() || ''"
      :async-status="asyncStatus"
    >
      <template #actions>
        <HangarSyncBtn size="small" />
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              :to="{ name: 'hangar-wishlist' }"
              size="small"
              variant="dropdown"
            >
              <i class="fad fa-wand-sparkles" />
              <span>{{ t("labels.wishlist") }}</span>
            </Btn>

            <Btn
              data-test="fleetchart-link"
              size="small"
              variant="dropdown"
              @click="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ t("labels.fleetchart") }}</span>
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }" size="small" variant="dropdown">
              <i class="fad fa-chart-bar" />
              <span>{{ t("labels.hangarStats") }}</span>
            </Btn>

            <ShareBtn
              v-if="currentUser && currentUser.publicHangar && shareUrl"
              :url="shareUrl"
              :title="shareTitle"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Btn
            :aria-label="toggleGridView"
            size="small"
            variant="dropdown"
            @click="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            <span>{{ toggleGridViewTooltip }}</span>
          </Btn>

          <Btn
            v-if="gridView"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn
            :aria-label="t('actions.showGuide')"
            size="small"
            variant="dropdown"
            @click="openGuide"
          >
            <i class="fad fa-question" />
            <span>{{ t("actions.showGuide") }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            href="https://robertsspaceindustries.com/account/pledges"
            target="_blank"
            variant="dropdown"
          >
            <img :src="rsiLogo" />
            <span>{{ t("nav.rsiHangar") }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :aria-label="t('actions.export')"
            @click="exportJson"
          >
            <i class="fal fa-download" />
            <span>{{ t("actions.export") }}</span>
          </Btn>

          <HangarImportBtn size="small" variant="dropdown" @finished="fetch" />

          <Btn
            size="small"
            variant="dropdown"
            :aria-label="t('actions.hangar.resetIngame.openModal')"
            @click="showResetIngameModal"
          >
            <i class="fal fa-arrow-rotate-left" />
            <span>{{ t("actions.hangar.resetIngame.openModal") }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :disabled="deleting"
            :aria-label="t('actions.hangar.destroyAll')"
            @click="destroyAll"
          >
            <i class="fal fa-trash" />
            <span>{{ t("actions.hangar.destroyAll") }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <template #filter>
        <VehiclesFilterForm :hangar-groups-options="hangarGroups" />
      </template>

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <VehiclePanel
              :vehicle="record"
              :details="detailsVisible"
              :editable="true"
              :highlight="record.hangarGroupIds.includes(highlightedGroup)"
            />
          </template>
        </FilteredGrid>

        <VehiclesTable
          v-else
          :vehicles="vehicles?.items || []"
          :primary-key="primaryKey"
          :editable="true"
        />

        <FleetchartApp
          :items="vehicles?.items || []"
          namespace="hangar"
          :loading="loading"
          download-name="my-hangar-fleetchart"
        >
          <template #pagination>
            <Paginator
              v-if="vehicles"
              :query-result-ref="vehicles"
              :per-page="perPage"
              :update-per-page="updatePerPage"
            />
          </template>
        </FleetchartApp>
      </template>

      <template #pagination-bottom>
        <Paginator
          v-if="vehicles"
          :query-result-ref="vehicles"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>

      <template #empty="{ hideEmptyBox, emptyBoxVisible }">
        <HangarEmptyBox v-if="!hideEmptyBox" :visible="emptyBoxVisible" />
      </template>
    </FilteredList>

    <PrimaryAction :label="t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredGrid from "@/shared/components/FilteredGrid/index.vue";
import VehiclesTable from "@/frontend/components/Vehicles/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import HangarImportBtn from "@/frontend/components/HangarImportBtn/index.vue";
import HangarSyncBtn from "@/frontend/components/HangarSyncBtn/index.vue";
import VehiclesFilterForm from "@/frontend/components/Vehicles/FilterForm/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { format } from "date-fns";
import { debounce } from "ts-debounce";
import HangarEmptyBox from "@/frontend/components/HangarEmptyBox/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  type HangarQuery,
  type HangarGroupMetric,
  HangarGroup,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useCable } from "@/shared/composables/useCable";
import { useNoty } from "@/shared/composables/useNoty";
import { Subscription } from "@rails/actioncable";
import { useMobile } from "@/shared/composables/useMobile";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import rsiLogo from "@/images/rsi_logo.png";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useHangarQueries } from "@/frontend/composables/useHangarQueries";
import { useFilters } from "@/shared/composables/useFilters";

const { t, toDollar, toUEC, toNumber } = useI18n();

const { displayAlert, displayConfirm } = useNoty(t);
const comlink = useComlink();

const deleting = ref(false);

const vehiclesChannel = ref<Subscription | null>(null);

const highlightedGroup = ref<string | undefined>();

const mobile = useMobile();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();

const { detailsVisible, gridView, money } = storeToRefs(hangarStore);

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("hangar"));

const shareTitle = computed(() => t("title.hangar.index"));

const { statsQuery, hangarQuery, groupsQuery } = useHangarQueries();

const { filters } = useFilters<HangarQuery>();

const { perPage, page, updatePerPage } = usePagination("hangar");

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = hangarQuery(filters, page, perPage);

const { data: hangarStats, refetch: refetchStats } = statsQuery(filters);

const { data: hangarGroups, refetch: refetchGroups } = groupsQuery();

const fetch = () => {
  refetch();
  refetchStats();
  refetchGroups();
};

const hangarGroupCounts = computed<HangarGroupMetric[]>(() => {
  if (!hangarStats.value) {
    return [];
  }

  return hangarStats.value.groups;
});

const toggleDetailsTooltip = computed(() => {
  if (detailsVisible.value) {
    return t("actions.hideDetails");
  }
  return t("actions.showDetails");
});

const toggleGridViewTooltip = computed(() => {
  if (gridView.value) {
    return t("actions.showTableView");
  }
  return t("actions.showGridView");
});

const shareUrl = computed(() => {
  if (!currentUser?.value) {
    return null;
  }

  return currentUser.value.publicHangarUrl;
});

const route = useRoute();

watch(
  () => route.query.q,
  () => {
    fetch();
  },
);

onMounted(() => {
  setupUpdates();

  comlink.on("vehicle-save", fetch);
  comlink.on("vehicles-delete-all", fetch);
  comlink.on("hangar-group-delete", fetch);
  // comlink.on("hangar-group-save", groupsCollection.findAll);
  comlink.on("hangar-sync-finished", fetch);
});

onUnmounted(() => {
  if (vehiclesChannel.value) {
    vehiclesChannel.value.unsubscribe();
  }

  comlink.off("vehicle-save");
  comlink.off("vehicles-delete-all");
  comlink.off("hangar-group-delete");
  // comlink.off("hangar-group-save");
  comlink.off("hangar-sync-finished");
});

const toggleDetails = () => {
  hangarStore.toggleDetails();
};

const toggleMoney = () => {
  hangarStore.toggleMoney();
};

const toggleGridView = () => {
  hangarStore.toggleGridView();
};

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("hangar");
};

const showNewModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/NewVehiclesModal/index.vue"),
  });
};

const highlightGroup = (group?: HangarGroup) => {
  if (!group) {
    highlightedGroup.value = undefined;
    return;
  }

  highlightedGroup.value = group.id;
};

const { consumer } = useCable();

const setupUpdates = () => {
  if (vehiclesChannel.value) {
    vehiclesChannel.value.unsubscribe();
  }

  vehiclesChannel.value = consumer.subscriptions.create(
    {
      channel: "HangarChannel",
    },
    {
      received: () => debounce(fetch, 500),
    },
  );
};

const exportJson = async () => {
  if (!currentUser?.value) {
    return;
  }

  const exportedData = await collection.export(filters.value);

  if (!exportedData || !window.URL) {
    displayAlert({ text: t("messages.hangarExport.failure") });
    return;
  }

  const link = document.createElement("a");

  link.href = window.URL.createObjectURL(
    new Blob([exportedData as unknown as BlobPart]),
  );

  link.setAttribute(
    "download",
    `fleetyards-${currentUser.value.username}-hangar-${format(
      new Date(),
      "yyyy-MM-dd",
    )}.json`,
  );

  document.body.appendChild(link);

  link.click();

  document.body.removeChild(link);
};

const showResetIngameModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/ResetIngameModal/index.vue"),
  });
};

const destroyAll = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.destroyAll"),
    onConfirm: async () => {
      await collection.destroyAll();

      comlink.emit("vehicles-delete-all");

      deleting.value = false;
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const openGuide = () => {
  comlink.emit("open-modal", {
    wide: true,
    component: () => import("@/frontend/components/HangarGuideModal/index.vue"),
  });
};
</script>

<script lang="ts">
export default {
  name: "HangarPage",
};
</script>
