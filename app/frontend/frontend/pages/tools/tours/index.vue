<script lang="ts">
export default {
  name: "ToursPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ToursTable from "@/frontend/components/Payouts/ToursTable/index.vue";
import TourArchiveSwitch from "@/frontend/components/Payouts/TourArchiveSwitch/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useTours } from "@/services/fyApi";
import type { Tour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t } = useI18n();

const router = useRouter();
const route = useRoute();

// In the address, so the archive is a page somebody can come back to.
const archived = computed({
  get: () => route.query.archived === "1",
  set: (value: boolean) => {
    void router.replace({
      query: { ...route.query, archived: value ? "1" : undefined },
    });
  },
});

const tourParams = computed(() => ({
  archived: archived.value ? true : undefined,
}));

const { data: tours, isLoading } = useTours(tourParams);

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

    <Teleport to="#header-right">
      <Btn
        :size="BtnSizesEnum.MD"
        :to="{ name: 'tour-add' }"
        :aria-label="t('actions.payouts.createTour')"
        data-test="tour-add"
        mobile-icon-only
      >
        <i class="fa-light fa-plus" />
        <span>{{ t("actions.payouts.createTour") }}</span>
      </Btn>
    </Teleport>

    <Heading hero mb>{{ t("headlines.payouts.tours.index") }}</Heading>

    <TourArchiveSwitch v-model="archived" />

    <ToursTable
      :tours="tours?.items ?? []"
      :loading="isLoading"
      with-fleet
      @row-click="onRowClick"
    >
      <template v-if="archived" #empty>
        {{ t("empty.payouts.archivedTours") }}
      </template>
    </ToursTable>
  </section>
</template>
