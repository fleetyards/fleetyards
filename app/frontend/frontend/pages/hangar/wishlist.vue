<script lang="ts">
export default {
  name: "WishlistPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { format } from "date-fns";
import debounce from "lodash.debounce";
import VehiclesTable from "@/frontend/components/Vehicles/Table/index.vue";
import HangarEmpty from "@/frontend/components/Hangar/Empty/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useWishlist as useWishlistQuery,
  exportWishlist,
  useDestroyWishlist as useDestroyWishlistMutation,
  getWishlistQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const { displayAlert, displayConfirm } = useAppNotifications();

const comlink = useComlink();

const mobile = useMobile();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const wishlistStore = useWishlistStore();

const { detailsVisible, gridView } = storeToRefs(wishlistStore);

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("wishlist"));

const { filters, isFilterSelected } = useHangarFilters(() => refetch());

const wishlistQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: filters.value,
}));

const wishlistQueryKey = computed(() => {
  return getWishlistQueryKey(wishlistQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(wishlistQueryKey);

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = useWishlistQuery(wishlistQueryParams);

const fetch = () => {
  refetch();
};

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
  // comlink.on("hangar-group-save", groupsCollection.findAll);
  comlink.on("hangar-sync-finished", fetch);
});

onUnmounted(() => {
  comlink.off("vehicle-save");
  comlink.off("vehicle-destroy");
  comlink.off("hangar-change");
  comlink.off("hangar-delete-all");
  comlink.off("hangar-group-delete");
  // comlink.off("hangar-group-save");
  comlink.off("hangar-sync-finished");
});

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("hangar");
};

const showNewModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/NewVehiclesModal/index.vue"),
    props: {
      wanted: true,
    },
  });
};

useSubscription({
  channelName: ChannelsEnum.HANGAR,
  received: () => debounce(fetch, 500),
});

const exportJson = async () => {
  if (!currentUser?.value) {
    return;
  }

  const exportedData = await exportWishlist();

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

const deleting = ref(false);

const destroyMutation = useDestroyWishlistMutation();

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

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Wishlist/DisplayOptionsModal/index.vue"),
  });
};
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="row">
        <div class="col-12">
          <BreadCrumbs
            :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar') }]"
          />
          <h1>{{ t("headlines.hangar.wishlist") }}</h1>
        </div>
      </div>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn data-test="fleetchart-link" @click="toggleFleetchart">
      <i class="fad fa-starship" />
      {{ t("labels.fleetchart") }}
    </Btn>
  </Teleport>

  <FilteredList
    key="wishlist"
    :hide-loading="fleetchartVisible || !gridView"
    :hide-empty-box="!gridView"
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
        <i class="fad fa-cog" />
      </Btn>
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <template v-if="mobile">
          <Btn
            data-test="fleetchart-link"
            :size="BtnSizesEnum.SMALL"
            @click="toggleFleetchart"
          >
            <i class="fad fa-starship" />
            <span>{{ t("labels.fleetchart") }}</span>
          </Btn>

          <hr />
        </template>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :aria-label="t('actions.export')"
          @click="exportJson"
        >
          <i class="fal fa-download" />
          <span>{{ t("actions.export") }}</span>
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

    <template #default="{ records, loading, filterVisible, emptyBoxVisible }">
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
          />
        </template>
      </Grid>

      <VehiclesTable
        v-else
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        :vehicles="vehicles?.items || []"
        :editable="true"
        wishlist
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

    <template #empty="{ hideEmptyBox, emptyBoxVisible }">
      <HangarEmpty
        v-if="!hideEmptyBox && emptyBoxVisible"
        :variant="EmptyVariantsEnum.BOX"
        wishlist
      />
    </template>
  </FilteredList>

  <PrimaryAction :label="t('actions.addVehicle')" :action="showNewModal" />
</template>
