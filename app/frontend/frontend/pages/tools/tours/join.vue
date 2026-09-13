<script lang="ts">
export default {
  name: "TourJoinPage",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import InviteInvalid from "@/shared/components/InviteInvalid/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useFindTourByInvite,
  useJoinTour as useJoinTourMutation,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

const { t, l } = useI18n();
const route = useRoute();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const token = computed(() => String(route.params.token));

// A link that does not resolve is a property of the link itself, so it stays on
// the page the way a fleet invite does rather than becoming a toast the reader
// is redirected away from.
const { data: tour, isError, isLoading } = useFindTourByInvite(token);

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
  <InviteInvalid v-if="isError" :token="token" />

  <Box v-else-if="tour" large animated>
    <template #heading>
      {{ t("headlines.payouts.tours.join") }}
    </template>

    <!-- Who is asking comes before what they are asking for, the way the
         authorize page names the application above its scopes. -->
    <div class="tour-join__organiser">
      <Avatar :avatar="tour.createdBy?.avatar?.smallUrl" size="large" />
    </div>

    <Text class="tour-join__info">
      {{
        t("texts.payouts.tourInvite", {
          username: tour.createdBy?.username,
        })
      }}
    </Text>

    <Text class="tour-join__title" no-spacing>{{ tour.title }}</Text>
    <Text v-if="tour.startsAt" muted>{{
      l(tour.startsAt, "datetime.formats.dateTime")
    }}</Text>
    <Text v-if="tour.description" muted no-spacing>
      {{ tour.description }}
    </Text>

    <template #footer>
      <div class="tour-join__actions">
        <Btn
          :tone="BtnTonesEnum.DANGER"
          :disabled="joining"
          :block="true"
          :to="{ name: 'tours' }"
        >
          {{ t("actions.cancel") }}
        </Btn>
        <Btn
          :loading="joining"
          :block="true"
          data-test="tour-join"
          @click="onJoin"
        >
          {{ t("actions.payouts.joinTour") }}
        </Btn>
      </div>
    </template>
  </Box>

  <Loader v-else :loading="isLoading" :fixed="true" />
</template>

<style lang="scss" scoped>
.tour-join__organiser {
  display: flex;
  justify-content: center;
  margin-bottom: 1rem;
}

.tour-join__info {
  margin-bottom: 15px;
  text-align: center;
}

.tour-join__title {
  font-size: 20px;
}

.tour-join__actions {
  display: flex;
  gap: 10px;
}
</style>
