<script lang="ts">
export default {
  name: "TourAddPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import TourForm from "@/frontend/components/Payouts/TourForm/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCreateTour as useCreateTourMutation } from "@/services/fyApi";
import type { TourCreateInput } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import type { ApiError } from "@/shared/types/api-error";

const { t } = useI18n();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const createMutation = useCreateTourMutation();

const onSubmit = async (data: TourCreateInput) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data })
    .then((tour) => {
      displaySuccess({ text: t("messages.payouts.tourCreated") });
      void router.push({ name: "tour", params: { slug: tour.slug } });
    })
    .catch((error: ApiError) => {
      displayAlert({
        text:
          error.response?.data?.message ??
          t("messages.payouts.tourCreateFailure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { to: { name: "tours" }, label: t("nav.tools.tours") },
  { label: t("headlines.payouts.tours.create") },
]);
</script>

<template>
  <section>
    <BreadCrumbs :crumbs="crumbs" />

    <Heading hero mb>{{ t("headlines.payouts.tours.create") }}</Heading>

    <TourForm :submitting="submitting" @submit="onSubmit" />
  </section>
</template>
