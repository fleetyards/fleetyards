<script lang="ts">
export default {
  name: "HangarBlueprintsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import BlueprintsList from "@/frontend/components/Blueprints/List/index.vue";
import FilterForm from "@/frontend/components/Blueprints/FilterForm/index.vue";
import { useBlueprintSortFields } from "@/frontend/composables/useBlueprintSortFields";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import { useBlueprintsTab } from "@/frontend/composables/useBlueprintsTab";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useBlueprints as useBlueprintsQuery } from "@/services/fyApi";

const { t } = useI18n();

const { activeTab } = useBlueprintsTab();

const { perPage, page, updatePerPage } = usePagination();

const { isFilterSelected, getQuery } = useBlueprintFilters(async () => {
  await refetch();
});

// The tab decides which marker is asked for, so the form's own owned filter
// is not offered here and anything left of it in the URL is dropped.
const queryParams = computed(() => {
  const { owned: _owned, wanted: _wanted, ...query } = getQuery();

  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...query,
      // Everything held or wanted, not only the build we are on: a patch
      // dropping a recipe does not take it out of anybody's hands.
      currentVersion: false,
      ...(activeTab.value === "wanted" ? { wanted: true } : { owned: true }),
    },
  };
});

const {
  data: blueprints,
  refetch,
  ...asyncStatus
} = useBlueprintsQuery(queryParams);

const sortFields = useBlueprintSortFields();
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />

  <Heading hero>
    {{ t("headlines.hangar.blueprints") }}
    <HeadingSmall data-test="hangar-blueprints-count">
      <template v-if="blueprints">
        {{
          t("headlines.pagination.count", {
            current: blueprints.items.length,
            total: blueprints.meta.pagination?.totalCount,
          })
        }}
      </template>
      <template v-else>&nbsp;</template>
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="hangar-blueprints"
    :records="blueprints?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm hide-owned />
    </template>

    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          :active="activeTab === 'owned'"
          mobile-icon-only
          data-test="hangar-blueprints-tab-owned"
          @click="activeTab = 'owned'"
        >
          <i class="fa-duotone fa-bookmark" />
          {{ t("labels.hangarBlueprints.owned") }}
        </Btn>
        <Btn
          :active="activeTab === 'wanted'"
          mobile-icon-only
          data-test="hangar-blueprints-tab-wanted"
          @click="activeTab = 'wanted'"
        >
          <i class="fa-duotone fa-wand-sparkles" />
          {{ t("labels.hangarBlueprints.wanted") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <BlueprintsList :blueprints="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
