<script lang="ts">
export default {
  name: "AdminRaffleEditPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import RaffleForm from "@/admin/components/Raffles/Form/index.vue";
import {
  type Raffle,
  type RaffleInput,
  useUpdateRaffle,
  getRafflesQueryKey,
  getRaffleQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const submitting = ref(false);

const updateMutation = useUpdateRaffle({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({ queryKey: getRafflesQueryKey() }),
        queryClient.invalidateQueries({
          queryKey: getRaffleQueryKey(props.raffle.id),
        }),
      ]);
    },
  },
});

const onSubmit = async (payload: RaffleInput) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.raffle.id, data: payload })
    .then(() => {
      displaySuccess({ text: t("messages.raffle.updated") });
    })
    .catch((error) => {
      console.error("Error updating raffle:", error);
      displayAlert({ text: t("messages.raffle.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const handleCancel = async () => {
  await router.push(
    extend({ name: "admin-raffles", hash: `#${props.raffle.id}` }),
  );
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
  <Heading hero>{{ t("headlines.admin.raffles.edit") }}</Heading>
  <RaffleForm
    form-id="admin-raffle-edit-form"
    :raffle="raffle"
    :submitting="submitting"
    @submit="onSubmit"
    @cancel="handleCancel"
  />
</template>
