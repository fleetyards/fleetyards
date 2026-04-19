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
import MemberLinks from "@/frontend/components/Fleets/MemberLinks/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import type { FleetMember } from "@/services/fyApi";

type Props = {
  members: FleetMember[];
  resourceAccess?: string[];
  emptyVisible?: boolean;
};

const props = defineProps<Props>();

const { t, l, timeDistance } = useI18n();

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
    @row-click="onRowClick"
  >
    <template #col-username="{ record }">
      <div class="member-username">
        <Avatar :avatar="record.avatar?.smallUrl" size="small" />
        <div class="member-username-inner">
          {{ record.username }}
          <div
            v-if="mobile && record.rsiHandle"
            v-tooltip="t('nav.rsiProfile')"
            class="rsi-handle-inline"
          >
            (<a
              :href="`https://robertsspaceindustries.com/citizens/${record.rsiHandle}`"
              target="_blank"
              rel="noopener"
              >{{ record.rsiHandle }}</a
            >)
          </div>
        </div>
      </div>
    </template>

    <template #col-rsiHandle="{ record }">
      <a
        v-if="record.rsiHandle"
        v-tooltip="t('nav.rsiProfile')"
        :href="`https://robertsspaceindustries.com/citizens/${record.rsiHandle}`"
        target="_blank"
        rel="noopener"
      >
        {{ record.rsiHandle }}
      </a>
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
      <span v-if="record.lastActiveAt" v-tooltip="l(record.lastActiveAt)">
        {{ timeDistance(record.lastActiveAt) }}
      </span>
    </template>

    <template #col-links="{ record }">
      <MemberLinks :member="record" />
    </template>

    <template #actions="{ record }">
      <MemberActions :member="record" :resource-access="props.resourceAccess" />
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
</style>
