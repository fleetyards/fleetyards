<script lang="ts">
export default {
  name: "TourPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import DetailSkeleton from "@/shared/components/DetailSkeleton/index.vue";
import TourDetails from "@/frontend/components/Payouts/TourDetails/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useTour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t } = useI18n();
const route = useRoute();

const slug = computed(() => String(route.params.slug));

const { data: tour, refetch, isLoading } = useTour(slug);

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { to: { name: "tours" }, label: t("nav.tools.tours") },
  // Dropped rather than left blank while the tour loads: an empty crumb is a
  // separator with nothing after it.
  ...(tour.value ? [{ label: tour.value.title }] : []),
]);

const { updateMetaInfo } = useMetaInfo();

watch(
  () => tour.value?.title,
  (title) => {
    if (title) {
      updateMetaInfo({ title });
    }
  },
  { immediate: true },
);
</script>

<template>
  <section>
    <BreadCrumbs :crumbs="crumbs" />

    <template v-if="tour">
      <Heading hero mb>{{ tour.title }}</Heading>

      <TourDetails :tour="tour" @reload="refetch" />
    </template>

    <!-- The ledger's four figures and its three panels; a tour opens on those
         rather than on a cover. -->
    <DetailSkeleton
      v-else-if="isLoading"
      :hero="false"
      :figures="4"
      :panels="3"
    />
  </section>
</template>
