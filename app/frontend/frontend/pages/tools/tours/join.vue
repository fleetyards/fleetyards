<script lang="ts">
export default {
  name: "TourJoinPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useFindTourByInvite,
  useJoinTour as useJoinTourMutation,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const token = computed(() => String(route.params.token));

const { data: tour } = useFindTourByInvite(token);

const joining = ref(false);

const joinMutation = useJoinTourMutation();

const onJoin = async () => {
  joining.value = true;

  await joinMutation
    .mutateAsync({ token: token.value })
    .then((joined) => {
      displaySuccess({ text: t("messages.payouts.tourJoined") });
      void router.push({ name: "tour", params: { slug: joined.slug } });
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      joining.value = false;
    });
};
</script>

<template>
  <section class="container">
    <Heading>{{ t("headlines.payouts.tours.join") }}</Heading>

    <Panel v-if="tour">
      <PanelBody>
        <p class="tour-join__title">{{ tour.title }}</p>
        <p v-if="tour.description" class="tour-join__description">
          {{ tour.description }}
        </p>

        <Btn :loading="joining" :size="BtnSizesEnum.LG" @click="onJoin">
          {{ t("actions.payouts.joinTour") }}
        </Btn>
      </PanelBody>
    </Panel>
  </section>
</template>

<style lang="scss" scoped>
.tour-join__title {
  font-size: 20px;
  margin-bottom: 4px;
}

.tour-join__description {
  color: var(--color-muted, #999);
  margin-bottom: 16px;
}
</style>
