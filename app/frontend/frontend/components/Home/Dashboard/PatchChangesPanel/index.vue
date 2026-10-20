<script lang="ts">
export default {
  name: "HomeDashboardPatchChangesPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type MyPatchChange, useMyPatchChanges } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

// Five is what fits beside the agenda without the column running away.
const SHOWN = 5;

const { data, isLoading, isFetching, isLoadingError } = useMyPatchChanges({
  query: liveQuery,
});

const items = computed(() => (data.value?.items || []).slice(0, SHOWN));

const title = computed(() =>
  data.value
    ? t("home.dashboard.changes.title", { version: data.value.version })
    : t("home.dashboard.changes.titleWithoutVersion"),
);

const ownershipFor = (item: MyPatchChange) => {
  if (item.ownedCount) {
    return t("home.dashboard.changes.owned", { count: item.ownedCount });
  }

  return t("home.dashboard.changes.wanted");
};
</script>

<template>
  <DashboardPanel
    :title="title"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!items.length"
    :more="{ name: 'hangar' }"
    :more-label="t('home.dashboard.changes.hangar')"
    data-test="home-patch-changes"
  >
    <div class="home-patch-changes">
      <RowListItem
        v-for="item in items"
        :key="item.model.id"
        :to="{ name: 'ship', params: { slug: item.model.slug } }"
        :badges="[
          {
            key: 'changes',
            label: t('home.dashboard.changes.changes'),
            value: String(item.changeCount),
          },
        ]"
      >
        <template #name>{{ item.model.name }}</template>
        <template #sub>
          <span v-if="item.model.manufacturerName">
            {{ item.model.manufacturerName }}
          </span>
          <span>{{ ownershipFor(item) }}</span>
        </template>
      </RowListItem>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-code-compare"
        :title="t('home.dashboard.changes.empty.title')"
        :hint="t('home.dashboard.changes.empty.hint')"
      />
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-patch-changes {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>
