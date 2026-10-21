<script lang="ts">
export default {
  name: "HomeDashboardInvitesAlert",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  getFleetInvitesQueryKey,
  getMyFleetSummariesQueryKey,
  useAcceptFleetMembership,
  useDeclineFleetMembership,
  useFleetInvites,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const comlink = useComlink();

const { data } = useFleetInvites();

// A request the reader sent is waiting on the fleet, not on them.
const invites = computed(() =>
  (data.value || []).filter((invite) => invite.status === "invited"),
);

const busy = ref<string | undefined>();

const refresh = () =>
  Promise.all([
    queryClient.invalidateQueries({ queryKey: getFleetInvitesQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getMyFleetSummariesQueryKey(),
    }),
  ]);

const acceptMutation = useAcceptFleetMembership();
const declineMutation = useDeclineFleetMembership();

const answer = async (fleetSlug: string, accept: boolean) => {
  busy.value = fleetSlug;

  try {
    if (accept) {
      await acceptMutation.mutateAsync({ fleetSlug });
      comlink.emit("fleet-update");
    } else {
      await declineMutation.mutateAsync({ fleetSlug });
    }
    await refresh();
  } catch {
    displayAlert({ text: t("home.dashboard.invites.failed") });
  } finally {
    busy.value = undefined;
  }
};
</script>

<template>
  <div v-if="invites.length" class="home-invites" data-test="home-invites">
    <Alert
      v-for="invite in invites"
      :key="invite.id"
      :variant="AlertVariantsEnum.INFO"
      icon="fa-duotone fa-envelope-open"
      :title="t('home.dashboard.invites.title', { fleet: invite.fleetName })"
    >
      {{ t("home.dashboard.invites.text") }}
      <template #actions>
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="busy === invite.fleetSlug"
          @click="answer(invite.fleetSlug, true)"
        >
          <i class="fa-light fa-check" />
          {{ t("home.dashboard.invites.accept") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="busy === invite.fleetSlug"
          @click="answer(invite.fleetSlug, false)"
        >
          {{ t("home.dashboard.invites.decline") }}
        </Btn>
      </template>
    </Alert>
  </div>
</template>

<style lang="scss" scoped>
.home-invites {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}
</style>
