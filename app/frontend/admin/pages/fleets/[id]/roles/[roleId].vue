<script lang="ts">
export default {
  name: "AdminFleetRolePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import DetailList from "@/admin/components/DetailList/index.vue";
import VersionHistory from "@/admin/components/VersionHistory/index.vue";
import { type Fleet } from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();

const roleId = computed(() => route.params.roleId as string);

const role = computed(() =>
  (props.fleet.fleetRoles || []).find((entry) => entry.id === roleId.value),
);

const details = computed(() =>
  role.value
    ? [
        { label: t("labels.fleet.roles.name"), value: role.value.name },
        { label: t("labels.fleet.roles.rank"), value: role.value.rank },
        {
          label: t("labels.fleet.roles.permanent"),
          value: role.value.permanent ? t("labels.true") : t("labels.false"),
        },
      ]
    : [],
);
</script>

<template>
  <Empty v-if="!role" />

  <template v-else>
    <Heading hero class="mb-4">{{ role.name }}</Heading>

    <DetailList :details="details" />

    <Heading class="mt-8 mb-4">
      {{ t("headlines.admin.fleets.history") }}
    </Heading>

    <VersionHistory :item-id="roleId" item-type="FleetRole" />
  </template>
</template>
