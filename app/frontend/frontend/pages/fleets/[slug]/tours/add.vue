<script lang="ts">
export default {
  name: "FleetTourAddPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import TourForm from "@/frontend/components/Payouts/TourForm/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCreateFleetTour as useCreateFleetTourMutation } from "@/services/fyApi";
import type { Fleet, TourCreateInput } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const createMutation = useCreateFleetTourMutation();

const onSubmit = async (data: TourCreateInput) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ fleetSlug: props.fleet.slug, data })
    .then((tour) => {
      displaySuccess({ text: t("messages.payouts.tourCreated") });
      void router.push({
        name: "fleet-tour",
        params: { slug: props.fleet.slug, tour: tour.slug },
      });
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
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-tours", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.tours"),
  },
  { label: t("headlines.payouts.tours.create") },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.payouts.tours.create") }}
  </Heading>

  <TourForm :submitting="submitting" @submit="onSubmit" />
</template>
