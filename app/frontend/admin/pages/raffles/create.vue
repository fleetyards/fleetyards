<script lang="ts">
export default {
  name: "AdminRaffleCreatePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import RaffleForm from "@/admin/components/Raffles/Form/index.vue";
import {
  type RaffleInput,
  useCreateRaffle,
  getRafflesQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const submitting = ref(false);

const createMutation = useCreateRaffle({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getRafflesQueryKey(),
      });
    },
  },
});

const onSubmit = async (payload: RaffleInput) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: payload })
    .then(async () => {
      displaySuccess({ text: t("messages.raffle.created") });
      await router.push(extend({ name: "admin-raffles" }));
    })
    .catch((error) => {
      console.error("Error creating raffle:", error);
      displayAlert({ text: t("messages.raffle.createFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const handleCancel = async () => {
  await router.push(extend({ name: "admin-raffles" }));
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-raffles' },
        label: t('headlines.admin.raffles.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.raffles.new") }}</Heading>
  <RaffleForm
    form-id="admin-raffle-create-form"
    :submitting="submitting"
    @submit="onSubmit"
    @cancel="handleCancel"
  />
</template>
