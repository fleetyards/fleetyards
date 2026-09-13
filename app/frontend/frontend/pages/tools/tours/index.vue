<script lang="ts">
export default {
  name: "ToursPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useTours } from "@/services/fyApi";
import type { Tour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t, l } = useI18n();

const router = useRouter();

const { data: tours, isLoading } = useTours();

const tableColumns = computed<BaseTableCol<Tour>[]>(() => [
  { name: "title", label: t("labels.payouts.title"), flexGrow: 2 },
  { name: "startsAt", label: t("labels.payouts.startsAt") },
  { name: "status", label: t("labels.status"), width: "120px" },
]);

const onRowClick = (tour: Tour) => {
  void router.push({ name: "tour", params: { slug: tour.slug } });
};

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { label: t("nav.tools.tours") },
]);
</script>

<template>
  <section>
    <BreadCrumbs :crumbs="crumbs" />

    <div class="tours-header">
      <Heading hero>{{ t("headlines.payouts.tours.index") }}</Heading>

      <Btn :to="{ name: 'tour-add' }" data-test="tour-add">
        {{ t("actions.payouts.createTour") }}
      </Btn>
    </div>

    <BaseTable
      :records="tours?.items ?? []"
      primary-key="id"
      :columns="tableColumns"
      :loading="isLoading"
      :empty-visible="!tours?.items?.length && !isLoading"
      row-clickable
      @row-click="onRowClick"
    >
      <template #col-startsAt="{ record }">
        <span v-if="record.startsAt">{{
          l(record.startsAt, "datetime.formats.dateTime")
        }}</span>
      </template>
      <template #col-status="{ record }">
        <Pill>
          {{
            t(
              `labels.payouts.${record.status === "settled" ? "settled" : "open"}`,
            )
          }}
        </Pill>
      </template>
      <template #empty>
        {{ t("empty.payouts.tours") }}
      </template>
    </BaseTable>
  </section>
</template>

<style lang="scss" scoped>
.tours-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}
</style>
