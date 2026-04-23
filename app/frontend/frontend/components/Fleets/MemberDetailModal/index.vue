<script lang="ts">
export default {
  name: "MemberDetailModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import MemberLinks from "@/frontend/components/Fleets/MemberLinks/index.vue";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  member: FleetMember;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const joinedDate = computed(() => {
  if (props.member.status === "invited" && props.member.invitedAt) {
    return props.member.invitedAt;
  }
  if (props.member.status === "declined" && props.member.declinedAt) {
    return props.member.declinedAt;
  }
  if (props.member.status === "requested" && props.member.requestedAt) {
    return props.member.requestedAt;
  }
  if (props.member.acceptedAt) {
    return props.member.acceptedAt;
  }
  return null;
});

const joinedLabel = computed(() => {
  if (props.member.status === "invited") {
    return t("labels.fleet.members.invited");
  }
  if (props.member.status === "declined") {
    return t("labels.fleet.members.declined");
  }
  if (props.member.status === "requested") {
    return t("labels.fleet.members.requested");
  }
  return t("labels.fleet.members.joined");
});

const roleDisplay = computed(() => {
  if (props.member.status === "invited") {
    return t("labels.fleet.members.invited");
  }
  if (props.member.status === "requested") {
    return t("labels.fleet.members.requested");
  }
  if (props.member.status === "declined") {
    return t("labels.fleet.members.declined");
  }
  return props.member.fleetRole?.name;
});
</script>

<template>
  <Modal>
    <template #title>
      <div class="member-detail-header">
        <Avatar :avatar="props.member.avatar?.smallUrl" size="small" />
        {{ props.member.username }}
      </div>
    </template>

    <dl class="member-detail-list">
      <template v-if="props.member.rsiHandle">
        <dt>{{ t("labels.user.rsiHandle") }}</dt>
        <dd>
          <RsiProfileLink
            :handle="props.member.rsiHandle"
            :citizenid-profile-url="props.member.citizenidProfileUrl"
          />
        </dd>
      </template>

      <dt>{{ t("labels.fleet.members.role") }}</dt>
      <dd :class="{ 'text-danger': props.member.status === 'declined' }">
        {{ roleDisplay }}
      </dd>

      <template v-if="joinedDate">
        <dt>{{ joinedLabel }}</dt>
        <dd>{{ l(joinedDate) }}</dd>
      </template>

      <template v-if="props.member.lastActiveAt">
        <dt>{{ t("labels.user.lastActiveAt") }}</dt>
        <dd>{{ l(props.member.lastActiveAt) }}</dd>
      </template>
    </dl>

    <div class="member-detail-links">
      <MemberLinks :member="props.member" />
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.member-detail-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.member-detail-list {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 8px 16px;
  margin-bottom: 20px;

  dt {
    font-weight: 600;
    opacity: 0.7;
  }

  dd {
    margin: 0;
  }
}

.member-detail-links {
  display: flex;
  justify-content: center;
  font-size: 1.3em;
}
</style>
