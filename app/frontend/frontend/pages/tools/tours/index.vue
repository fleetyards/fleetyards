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
import { useI18n } from "@/shared/composables/useI18n";
import { useTours } from "@/services/fyApi";
import type { Tour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t } = useI18n();

const router = useRouter();

const { data: tours, isLoading } = useTours();

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

    <ToursTable
      :tours="tours?.items ?? []"
      :loading="isLoading"
      with-fleet
      @row-click="onRowClick"
    />
  </section>
</template>
