<script lang="ts">
export default {
  name: "FleetSquadronRequestsList",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Empty from "@/shared/components/Empty/index.vue";
import MemberAvatar from "@/frontend/components/Fleets/MemberAvatar/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { handleVerifiedViaProfile } from "@/frontend/utils/rsiHandle";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import {
  useFleetSquadronRequests,
  useAcceptFleetSquadronRequest,
  useDestroyFleetSquadronRequest,
  type FleetSquadronRequest,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const {
  data: requests,
  isLoading,
  refetch,
} = useFleetSquadronRequests(
  () => props.fleetSlug,
  () => props.squadronSlug,
);

const items = computed(() => requests.value ?? []);

const answering = ref<string>();

const acceptMutation = useAcceptFleetSquadronRequest();
const declineMutation = useDestroyFleetSquadronRequest();

const answer = async (request: FleetSquadronRequest, accept: boolean) => {
  const username = request.member.username;
  const kind = accept ? "accept" : "decline";

  answering.value = username;

  try {
    const mutation = accept ? acceptMutation : declineMutation;
    await mutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      username,
    });
    displaySuccess({
      text: t(`messages.fleet.squadrons.requests.${kind}.success`, {
        username,
      }),
    });
    comlink.emit("fleet-squadron-members-updated");
  } catch (error) {
    displayAlert({
      text:
        firstErrorMessageFrom(error) ??
        t(`messages.fleet.squadrons.requests.${kind}.failure`),
    });
  } finally {
    answering.value = undefined;
    await refetch();
  }
};

const columns = computed<BaseTableCol<FleetSquadronRequest>[]>(() => [
  { name: "username", label: t("labels.username"), width: "40%" },
  {
    name: "rsiHandle",
    label: t("labels.user.rsiHandle"),
    width: "25%",
    mobile: false,
  },
  {
    name: "createdAt",
    label: t("labels.fleet.squadrons.requestedAt"),
    width: "20%",
    mobile: false,
  },
]);
</script>

<template>
  <BaseTable
    :records="items"
    primary-key="id"
    :columns="columns"
    :loading="isLoading"
    :empty-visible="!isLoading && !items.length"
  >
    <template #col-username="{ record }">
      <div class="request-member">
        <MemberAvatar :member="record.member" />
        <MemberName :member="record.member" :org-badge="false" />
      </div>
    </template>

    <template #col-rsiHandle="{ record }">
      <RsiProfileLink
        v-if="record.member.rsiHandle"
        :handle="record.member.rsiHandle"
        :citizenid-profile-url="record.member.citizenidProfileUrl"
        :verified="handleVerifiedViaProfile(record.member)"
      />
    </template>

    <template #col-createdAt="{ record }">
      <span v-tooltip="l(record.createdAt)">
        {{ l(record.createdAt, "datetime.formats.short") }}
      </span>
    </template>

    <template #actions="{ record }">
      <BtnGroup>
        <Btn
          v-tooltip="t('actions.fleet.squadrons.acceptRequest')"
          :aria-label="t('actions.fleet.squadrons.acceptRequest')"
          :disabled="answering === record.member.username"
          :data-test="`squadron-request-accept-${record.member.username}`"
          @click="answer(record, true)"
        >
          <i class="fa-light fa-check" />
        </Btn>
        <Btn
          v-tooltip="t('actions.fleet.squadrons.declineRequest')"
          :aria-label="t('actions.fleet.squadrons.declineRequest')"
          :tone="BtnTonesEnum.DANGER"
          :disabled="answering === record.member.username"
          :data-test="`squadron-request-decline-${record.member.username}`"
          @click="answer(record, false)"
        >
          <i class="fa-light fa-times" />
        </Btn>
      </BtnGroup>
    </template>

    <template #empty>
      <Empty :name="t('labels.fleet.squadrons.requests')" inline />
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
.request-member {
  display: flex;
  align-items: center;
  gap: 10px;
}
</style>
