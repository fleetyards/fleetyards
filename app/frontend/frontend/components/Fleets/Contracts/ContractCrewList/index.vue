<script lang="ts">
export default {
  name: "FleetContractsCrewList",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  type FleetContractCrewMember,
  FleetContractCrewRoleEnum,
  FleetContractCrewStateEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  crew: FleetContractCrewMember[];
  // Whether the viewer may answer the people waiting — the lead, or somebody
  // holding fleet:contracts:manage.
  canAnswer?: boolean;
  currentUserId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  canAnswer: false,
  currentUserId: undefined,
});

const emit = defineEmits<{
  accept: [id: string];
  decline: [id: string];
  remove: [id: string];
}>();

const { t } = useI18n();

const pending = computed(() =>
  props.crew.filter(
    (member) => member.state === FleetContractCrewStateEnum.REQUESTED,
  ),
);

const accepted = computed(() =>
  props.crew.filter(
    (member) => member.state === FleetContractCrewStateEnum.ACCEPTED,
  ),
);
</script>

<template>
  <div class="contract-crew" data-test="contract-crew">
    <ul class="contract-crew__list">
      <li
        v-for="member in accepted"
        :key="member.id"
        class="contract-crew__member"
        data-test="contract-crew-member"
      >
        <img
          v-if="member.user?.avatar?.smallUrl"
          :src="member.user.avatar.smallUrl"
          :alt="member.user?.username ?? ''"
          class="contract-crew__avatar"
        />
        <span class="contract-crew__name">{{ member.user?.username }}</span>
        <Pill
          v-if="member.role === FleetContractCrewRoleEnum.LEAD"
          :variant="PillVariantsEnum.DEFAULT"
        >
          {{ t("labels.fleets.contracts.lead") }}
        </Pill>

        <Btn
          v-if="member.user?.id === props.currentUserId"
          size="xs"
          @click="emit('remove', member.id)"
        >
          {{ t("actions.fleets.contracts.leave") }}
        </Btn>
        <Btn
          v-else-if="
            props.canAnswer && member.role !== FleetContractCrewRoleEnum.LEAD
          "
          size="xs"
          @click="emit('remove', member.id)"
        >
          {{ t("actions.fleets.contracts.remove") }}
        </Btn>
      </li>
    </ul>

    <template v-if="props.canAnswer && pending.length">
      <p class="contract-crew__pending-label">
        {{ t("labels.fleets.contracts.pendingCrew") }}
      </p>
      <ul class="contract-crew__list">
        <li
          v-for="member in pending"
          :key="member.id"
          class="contract-crew__member"
          data-test="contract-crew-request"
        >
          <span class="contract-crew__name">{{ member.user?.username }}</span>
          <Btn size="xs" @click="emit('accept', member.id)">
            {{ t("actions.fleets.contracts.acceptCrew") }}
          </Btn>
          <Btn size="xs" @click="emit('decline', member.id)">
            {{ t("actions.fleets.contracts.declineCrew") }}
          </Btn>
        </li>
      </ul>
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
