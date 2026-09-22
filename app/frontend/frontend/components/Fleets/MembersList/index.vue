<script lang="ts">
export default {
  name: "MembersList",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import MemberActions from "@/frontend/components/Fleets/MemberActions/index.vue";
import MemberName from "@/frontend/components/Fleets/MemberName/index.vue";
import MemberLinks from "@/frontend/components/Fleets/MemberLinks/index.vue";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMemberPresence } from "@/frontend/composables/useMemberPresence";
import { useMobile } from "@/shared/composables/useMobile";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import type {
  FleetMember,
  FleetMembershipCapabilities,
} from "@/services/fyApi";

type Props = {
  members: FleetMember[];
  capabilities?: FleetMembershipCapabilities;
  emptyVisible?: boolean;
  loading?: boolean;
  // Off on a squadron's own page, where every row carries the same badge and
  // it would say nothing.
  showSquadrons?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  capabilities: undefined,
  showSquadrons: true,
});

const { t, l, timeDistance } = useI18n();

const { onlineFor, lastActiveAtFor } = useMemberPresence();

const comlink = useComlink();

const mobile = useMobile();

const onRowClick = (member: FleetMember) => {
  if (!mobile.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/MemberDetailModal/index.vue"),
    props: { member },
  });
};

const squadronNames = (member: FleetMember) =>
  (member.squadrons ?? []).map((squadron) => squadron.name).join(", ");

const tableColumns = computed<BaseTableCol<FleetMember>[]>(() => [
  {
    name: "username",
    label: t("labels.username"),
    width: "30%",
    sortable: true,
  },
  {
    name: "rsiHandle",
    label: t("labels.user.rsiHandle"),
    width: "15%",
    mobile: false,
    sortable: true,
  },
  {
    name: "role",
    label: "",
    width: "10%",
  },
  {
    name: "acceptedAt",
    label: t("labels.fleet.members.joined"),
    width: "15%",
    mobile: false,
    sortable: true,
  },
  {
    name: "lastActiveAt",
    label: t("labels.user.lastActiveAt"),
    width: "15%",
    mobile: false,
    sortable: true,
  },
  {
    name: "links",
    label: "",
    mobile: false,
    alignment: "right",
  },
]);
</script>

<template>
  <BaseTable
    :records="members"
    primary-key="id"
    :columns="tableColumns"
    :row-clickable="mobile"
    :empty-visible="emptyVisible"
    :loading="loading"
    @row-click="onRowClick"
  >
    <template #col-username="{ record }">
      <div class="member-username">
        <span class="member-avatar">
          <Avatar
            :avatar="record.avatar?.smallUrl"
            size="small"
            :online="onlineFor(record)"
          />
          <SquadronEmblem
            v-if="props.showSquadrons && record.squadrons?.length"
            v-tooltip="squadronNames(record)"
            :squadron="record.squadrons[0]"
            :size="18"
            class="member-avatar-squadron"
          />
        </span>
        <div class="member-username-inner">
          <MemberName :member="record" />
          <div v-if="mobile && record.rsiHandle" class="rsi-handle-inline">
            (<RsiProfileLink
              :handle="record.rsiHandle"
              :citizenid-profile-url="record.citizenidProfileUrl"
            />)
          </div>
        </div>
      </div>
    </template>

    <template #col-rsiHandle="{ record }">
      <RsiProfileLink
        v-if="record.rsiHandle"
        :handle="record.rsiHandle"
        :citizenid-profile-url="record.citizenidProfileUrl"
      />
    </template>

    <template #col-role="{ record }">
      {{ record.fleetRole?.name }}
    </template>

    <template #col-acceptedAt="{ record }">
      <span v-if="record.acceptedAt" v-tooltip="l(record.acceptedAt)">
        {{ l(record.acceptedAt, "datetime.formats.short") }}
      </span>
    </template>

    <template #col-lastActiveAt="{ record }">
      <span
        v-if="lastActiveAtFor(record)"
        v-tooltip="l(lastActiveAtFor(record) as string)"
      >
        {{ timeDistance(lastActiveAtFor(record) as string) }}
      </span>
    </template>

    <template #col-links="{ record }">
      <MemberLinks :member="record" />
    </template>

    <template #actions="{ record }">
      <MemberActions :member="record" :capabilities="props.capabilities" />
    </template>
    <template #empty>
      <Empty :name="t('labels.fleet.members.accepted')" inline />
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
.member-username {
  display: flex;
  align-items: center;
  gap: 10px;
}

.member-username-inner {
  display: flex;
  flex-direction: column;
}

.rsi-handle-inline {
  font-size: 0.85em;
  opacity: 0.8;
}

.member-avatar {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
}

// Overhangs the frame the way the presence dot does, on the corner it leaves
// free.
.member-avatar-squadron {
  position: absolute;
  left: -4px;
  bottom: -4px;
}
</style>
