<script lang="ts">
export default {
  name: "HangarPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import VehiclesTable from "@/frontend/components/Vehicles/Table/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import HangarEmpty from "@/frontend/components/Hangar/Empty/index.vue";
import HangarImportBtn from "@/frontend/components/Hangar/ImportBtn/index.vue";
import HangarSyncBtn from "@/frontend/components/Hangar/SyncBtn/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import GroupLabels from "@/frontend/components/Hangar/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { format } from "date-fns";
import debounce from "lodash.debounce";
import Paginator from "@/shared/components/Paginator/index.vue";
import { type HangarGroupMetric, HangarGroup } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import rsiLogo from "@/images/rsi_logo.png";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  useHangarStats as useHangarStatsQuery,
  useHangar as useHangarQuery,
  useHangarGroups as useHangarGroupsQuery,
  hangarExport as fetchHangarExport,
  useDestroyHangar as useDestroyHangarMutation,
  type HangarParams,
  getHangarQueryKey,
} from "@/services/fyApi";

const { t, toDollar, toUEC, toNumber } = useI18n();

const { displayAlert, displayConfirm } = useAppNotifications();

const comlink = useComlink();

const deleting = ref(false);

const highlightedGroup = ref<string>("");

const mobile = useMobile();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();

const { detailsVisible, gridView, money } = storeToRefs(hangarStore);

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("hangar"));

const shareTitle = computed(() => t("title.hangar.index"));

const { isFilterSelected, getQuery } = useHangarFilters(() => refetch());

const hangarQueryParams = computed(() => {
  const params: HangarParams = {
    page: page.value,
    perPage: perPage.value,
    q: getQuery(),
  };

  return params;
});

const hangarQueryKey = computed(() => {
  return getHangarQueryKey(hangarQueryParams);
});

const { perPage, page, updatePerPage } = usePagination(hangarQueryKey);

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = useHangarQuery(hangarQueryParams);

const { data: hangarStats, refetch: refetchStats } =
  useHangarStatsQuery(hangarQueryParams);

const { data: hangarGroups, refetch: refetchGroups } = useHangarGroupsQuery();

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
  comlink.on("vehicle-save", fetch);
  comlink.on("vehicle-destroy", fetch);
  comlink.on("hangar-change", fetch);
  comlink.on("hangar-delete-all", fetch);
  comlink.on("hangar-group-delete", fetch);
  comlink.on("hangar-group-save", fetch);
  comlink.on("hangar-sync-finished", fetch);
});

onUnmounted(() => {
  comlink.off("vehicle-save");
  comlink.off("vehicle-destroy");
  comlink.off("hangar-change");
  comlink.off("hangar-delete-all");
  comlink.off("hangar-group-delete");
  comlink.off("hangar-group-save");
  comlink.off("hangar-sync-finished");
});

const toggleMoney = () => {
  hangarStore.toggleMoney();
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
    highlightedGroup.value = "";
    return;
  }

  highlightedGroup.value = group.id;
};

useSubscription({
  channelName: ChannelsEnum.HANGAR,
  received: () => debounce(fetch, 500),
});

const exportJson = async () => {
  if (!currentUser?.value) {
    return;
  }

  const exportedData = await fetchHangarExport(hangarQueryParams);

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
      import("@/frontend/components/Hangar/ResetIngameModal/index.vue"),
  });
};

const destroyMutation = useDestroyHangarMutation();

const destroyAll = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.destroyAll"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync()
        .then(() => {
          comlink.emit("hangar-delete-all");
        })
        .finally(() => {
          deleting.value = false;
        });
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const openGuide = () => {
  comlink.emit("open-modal", {
    wide: true,
    component: () =>
      import("@/frontend/components/Hangar/GuideModal/index.vue"),
  });
};

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/DisplayOptionsModal/index.vue"),
  });
};
</script>

<template>
  <Heading hidden>{{ t("headlines.hangar.index") }}</Heading>
  <div class="row">
    <div class="col-12 col-lg-12">
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
              <!-- eslint-disable-next-line vue/no-v-html -->
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

  <Teleport v-if="!mobile" to="#header-right">
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
      no-label
    />
  </Teleport>

  <FilteredList
    key="hangar"
    :hide-loading="fleetchartVisible || !gridView"
    :hide-empty="!gridView"
    :records="vehicles?.items || []"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #actions-right>
      <Btn
        :aria-label="t('actions.models.openTableConfiguration')"
        :size="BtnSizesEnum.SMALL"
        @click="openDisplayOptionsModal"
      >
        <i class="fad fa-sliders" />
      </Btn>
      <HangarSyncBtn :size="BtnSizesEnum.SMALL" />
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <template v-if="mobile">
          <Btn :to="{ name: 'hangar-wishlist' }" :size="BtnSizesEnum.SMALL">
            <i class="fad fa-wand-sparkles" />
            <span>{{ t("labels.wishlist") }}</span>
          </Btn>

          <Btn
            data-test="fleetchart-link"
            :size="BtnSizesEnum.SMALL"
            @click="toggleFleetchart"
          >
            <i class="fad fa-starship" />
            <span>{{ t("labels.fleetchart") }}</span>
          </Btn>

          <Btn :to="{ name: 'hangar-stats' }" :size="BtnSizesEnum.SMALL">
            <i class="fad fa-chart-bar" />
            <span>{{ t("labels.hangarStats") }}</span>
          </Btn>

          <ShareBtn
            v-if="currentUser && currentUser.publicHangar && shareUrl"
            :url="shareUrl"
            :title="shareTitle"
            :size="BtnSizesEnum.SMALL"
          />

          <hr />
        </template>

        <Btn
          :aria-label="t('actions.showGuide')"
          :size="BtnSizesEnum.SMALL"
          @click="openGuide"
        >
          <i class="fad fa-question" />
          <span>{{ t("actions.showGuide") }}</span>
        </Btn>

        <hr />

        <Btn
          :size="BtnSizesEnum.SMALL"
          href="https://robertsspaceindustries.com/account/pledges"
          target="_blank"
        >
          <img :src="rsiLogo" />
          <span>{{ t("nav.rsiHangar") }}</span>
        </Btn>

        <hr />

        <Btn
          :size="BtnSizesEnum.SMALL"
          :aria-label="t('actions.export')"
          @click="exportJson"
        >
          <i class="fal fa-download" />
          <span>{{ t("actions.export") }}</span>
        </Btn>

        <HangarImportBtn :size="BtnSizesEnum.SMALL" @finished="fetch" />

        <Btn
          :size="BtnSizesEnum.SMALL"
          :aria-label="t('actions.hangar.resetIngame.openModal')"
          @click="showResetIngameModal"
        >
          <i class="fal fa-arrow-rotate-left" />
          <span>{{ t("actions.hangar.resetIngame.openModal") }}</span>
        </Btn>

        <hr />

        <Btn
          :size="BtnSizesEnum.SMALL"
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
      <FilterForm />
    </template>

    <template #default="{ records, loading, filterVisible, emptyVisible }">
      <Grid
        v-if="gridView"
        :records="records"
        :filter-visible="filterVisible"
        primary-key="id"
      >
        <template #default="{ record }">
          <VehiclePanel
            :vehicle="record"
            :details="detailsVisible"
            :editable="true"
            :highlight="record.hangarGroupIds.includes(highlightedGroup)"
          />
        </template>
      </Grid>

      <VehiclesTable
        v-else
        :loading="loading"
        :empty-visible="emptyVisible"
        :vehicles="vehicles?.items || []"
        :editable="true"
      />

      <FleetchartApp
        :items="vehicles?.items || []"
        namespace="hangar"
        :loading="loading"
        download-name="my-hangar-fleetchart"
      >
        <template #filter>
          <FilterForm hide-quicksearch />
        </template>
        <template #pagination>
          <Paginator
            v-if="vehicles"
            :query-result-ref="vehicles"
            :per-page="perPage"
            :size="BtnSizesEnum.SMALL"
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

    <template #empty="{ hideEmpty, emptyVisible }">
      <HangarEmpty
        v-if="!hideEmpty && emptyVisible"
        :variant="EmptyVariantsEnum.BOX"
      />
    </template>
  </FilteredList>

  <PrimaryAction :label="t('actions.addVehicle')" :action="showNewModal" />
</template>
