<script lang="ts">
export default {
  name: "PublicWishlistPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarPublicHeading from "@/frontend/components/Hangar/PublicHeading/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { type UserPublic } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePublicWishlist as usePublicWishlistQuery } from "@/services/fyApi";

const { t } = useI18n();

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

const username = computed(() => {
  return props.user.username;
});

const usernamePlural = computed(() => {
  if (
    userTitle.value.endsWith("s") ||
    userTitle.value.endsWith("x") ||
    userTitle.value.endsWith("z")
  ) {
    return userTitle.value;
  }

  return `${userTitle.value}'s`;
});

const userTitle = computed(() => {
  return username.value[0].toUpperCase() + username.value.slice(1);
});

const mobile = useMobile();

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("wishlist"));

const route = useRoute();

const wishlistQuery = usePublicWishlistQuery(username);
const wishlist = wishlistQuery.data;
const refetch = wishlistQuery.refetch;
const asyncStatus = {
  fetchStatus: wishlistQuery.fetchStatus,
  isError: wishlistQuery.isError,
  isLoading: wishlistQuery.isLoading,
  isFetching: wishlistQuery.isFetching,
  isRefetching: wishlistQuery.isRefetching,
  error: wishlistQuery.error,
};

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("wishlist");
};

const router = useRouter();

onMounted(() => {
  if (!props.user.publicWishlist) {
    router.replace({
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
      <HangarPublicHeading :user="user" />
    </div>

    <div class="col-12 col-lg-4 hangar-profile-links">
      <a
        v-if="user.homepage"
        v-tooltip="t('labels.homepage')"
        :href="`//${user.homepage}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fal fa-globe globe-rotate" />
      </a>
      <a
        v-if="user.rsiHandle"
        v-tooltip="t('nav.rsiProfile')"
        :href="`https://robertsspaceindustries.com/citizens/${user.rsiHandle}`"
        target="_blank"
        rel="noopener"
      >
        <i class="icon icon-rsi" />
      </a>
      <a
        v-if="user.guilded"
        v-tooltip="t('labels.guilded')"
        :href="`//${user.guilded}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-guilded" />
      </a>
      <a
        v-if="user.discord"
        v-tooltip="t('labels.discord')"
        :href="`//${user.discord}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-discord" />
      </a>
      <a
        v-if="user.youtube"
        v-tooltip="t('labels.youtube')"
        :href="`//${user.youtube}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-youtube" />
      </a>
      <a
        v-if="user.twitch"
        v-tooltip="t('labels.twitch')"
        :href="`//${user.twitch}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-twitch" />
      </a>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn data-test="fleetchart-link" @click="toggleFleetchart">
      <i class="fad fa-starship" />
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
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <Btn
          data-test="fleetchart-link"
          :size="BtnSizesEnum.SMALL"
          @click="toggleFleetchart"
        >
          <i class="fad fa-starship" />
          <span>{{ t("labels.fleetchart") }}</span>
        </Btn>
      </BtnDropdown>
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
      >
        <template #filter>
          <FilterForm hide-quicksearch />
        </template>
        <template #pagination>
          <Paginator
            v-if="wishlist"
            :query-result-ref="wishlist"
            :per-page="wishlist?.meta?.pagination?.defaultPerPage || 20"
            :size="BtnSizesEnum.SMALL"
            :update-per-page="() => refetch()"
          />
        </template>
      </FleetchartApp>
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="wishlist"
        :query-result-ref="wishlist"
        :per-page="wishlist?.meta?.pagination?.defaultPerPage || 20"
        :update-per-page="() => refetch()"
      />
    </template>
  </FilteredList>
</template>
