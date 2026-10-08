<script lang="ts">
export default {
  name: "PublicWishlistPage",
};
</script>

<script lang="ts" setup>
import { possessiveUsername } from "@/frontend/utils/possessiveUsername";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import { useWishlistSortFields } from "@/frontend/composables/useWishlistSortFields";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarPublicHeading from "@/frontend/components/Hangar/PublicHeading/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { useFleetchartShareUrl } from "@/frontend/composables/useFleetchartShareUrl";
import Paginator from "@/shared/components/Paginator/index.vue";
import { type UserPublic } from "@/services/fyApi";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { handleVerifiedViaProfile } from "@/frontend/utils/rsiHandle";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePagination } from "@/shared/composables/usePagination";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import {
  usePublicWishlist as usePublicWishlistQuery,
  getPublicWishlistQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const fleetchartShareUrl = useFleetchartShareUrl();

const route = useRoute();

// The chips picked in the display options, plus whichever sort the list is in
// right now so the toolbar never hides the one that is chosen.
const sortFields = useWishlistSortFields({
  include: () =>
    typeof route.query.s === "string" ? route.query.s : undefined,
});

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

const username = computed(() => {
  return props.user.username;
});

const usernamePlural = computed(() => possessiveUsername(username.value));

const mobile = useMobile();

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("wishlist"));

const { getQuery } = useHangarFilters(async () => {
  await refetch();
});

const wishlistQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const wishlistQueryKey = computed(() => {
  return getPublicWishlistQueryKey(username.value, wishlistQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(wishlistQueryKey);

const wishlistQuery = usePublicWishlistQuery(username, wishlistQueryParams);
const wishlist = wishlistQuery.data;
const refetch = wishlistQuery.refetch;
const asyncStatus = {
  fetchStatus: wishlistQuery.fetchStatus,
  isError: wishlistQuery.isError,
  isPending: wishlistQuery.isPending,
  isLoading: wishlistQuery.isLoading,
  isFetching: wishlistQuery.isFetching,
  isRefetching: wishlistQuery.isRefetching,
  error: wishlistQuery.error,
};

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("wishlist");
};

const router = useRouter();

onMounted(async () => {
  if (!props.user.publicWishlist) {
    await router.replace({
      name: "hangar-public",
      params: { username: username.value },
    });
  }
});
</script>

<template>
  <Teleport to="#header-left">
    <BreadCrumbs
      :crumbs="[
        {
          to: { name: 'hangar-public', params: { username: username } },
          label: t('headlines.hangar.public', { user: usernamePlural }),
        },
      ]"
    />
  </Teleport>
  <div class="row hangar-public">
    <div class="col-12 col-lg-8">
      <HangarPublicHeading
        :user="user"
        headline-key="headlines.hangar.publicWishlist"
      />
    </div>

    <div class="col-12 col-lg-4 hangar-profile-links">
      <a
        v-if="user.homepage"
        v-tooltip="t('labels.homepage')"
        :aria-label="t('labels.homepage')"
        :href="`//${user.homepage}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-light fa-globe globe-rotate" />
      </a>
      <RsiProfileLink
        v-if="user.rsiHandle"
        :handle="user.rsiHandle"
        :citizenid-profile-url="user.citizenidProfileUrl"
        :verified="handleVerifiedViaProfile(user)"
        icon-only
      />
      <a
        v-if="user.guilded"
        v-tooltip="t('labels.guilded')"
        :aria-label="t('labels.guilded')"
        :href="`//${user.guilded}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-guilded" />
      </a>
      <a
        v-if="user.discord"
        v-tooltip="t('labels.discord')"
        :aria-label="t('labels.discord')"
        :href="`//${user.discord}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-discord" />
      </a>
      <a
        v-if="user.youtube"
        v-tooltip="t('labels.youtube')"
        :aria-label="t('labels.youtube')"
        :href="`//${user.youtube}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-youtube" />
      </a>
      <a
        v-if="user.twitch"
        v-tooltip="t('labels.twitch')"
        :aria-label="t('labels.twitch')"
        :href="`//${user.twitch}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-twitch" />
      </a>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      data-test="fleetchart-link"
      @click="toggleFleetchart"
    >
      <DuotoneGlyph :glyph="SHIP_GLYPH" />
      {{ t("labels.fleetchart") }}
    </Btn>
  </Teleport>

  <FilteredList
    :key="`public-wishlist-${username}`"
    :hide-loading="fleetchartVisible"
    :records="wishlist?.items || []"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
  >
    <template v-if="mobile" #actions-right>
      <BtnDropdown>
        <Btn data-test="fleetchart-link" @click="toggleFleetchart">
          <DuotoneGlyph :glyph="SHIP_GLYPH" />
          <span>{{ t("labels.fleetchart") }}</span>
        </Btn>
      </BtnDropdown>
    </template>

    <template #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #sort>
      <!-- A public hangar is only ever cards, so this is the whole
      sort control rather than a second way to reach one. -->
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, loading }">
      <Grid :records="records" :filter-visible="false" primary-key="id">
        <template #default="{ record }">
          <VehiclePanel :vehicle="record" :details="false" :editable="false" />
        </template>
      </Grid>

      <FleetchartApp
        :items="wishlist?.items || []"
        namespace="wishlist"
        :loading="loading"
        download-name="my-wishlist-fleetchart"
        :share-url="fleetchartShareUrl"
        :share-title="
          t('headlines.hangar.publicWishlist', { user: usernamePlural })
        "
      >
        <template #filter>
          <FilterForm hide-quicksearch />
        </template>
        <template #pagination>
          <Paginator
            :query-result-ref="wishlist"
            :per-page="perPage"
            :size="BtnSizesEnum.SM"
            :update-per-page="updatePerPage"
          />
        </template>
      </FleetchartApp>
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="wishlist"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="wishlist"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
