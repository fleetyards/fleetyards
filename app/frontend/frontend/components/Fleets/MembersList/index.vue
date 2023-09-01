<template>
  <Panel v-if="members.length">
    <transition-group
      name="fade"
      class="flex-list flex-list-users"
      tag="div"
      :appear="true"
    >
      <MembersListHead key="heading" :actions-visible="actionsVisible" />
      <MembersListItem
        v-for="(member, index) in members"
        :key="`members-${index}`"
        :member="member"
        :actions-visible="actionsVisible"
        :role="role"
      />
    </transition-group>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import MembersListHead from "./MembersListHead/index.vue";
import MembersListItem from "./MembersListItem/index.vue";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  members: FleetMember[];
  role: "admin" | "officer" | "member";
};

const props = defineProps<Props>();

const actionsVisible = computed(() =>
  ["admin", "officer"].includes(props.role),
);
</script>

<script lang="ts">
export default {
  name: "MembersList",
};
</script>
