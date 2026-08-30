<script lang="ts">
export default {
  name: "AdminFleetRolesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { BaseTableCol } from "@/shared/components/base/Table/types";
import { type Fleet, type AdminFleetRole } from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

// The fleet payload already carries its roles, so there is no query here and
// nothing to paginate: a fleet has a handful of them.
const roles = computed(() => props.fleet.fleetRoles || []);

const columns: BaseTableCol<AdminFleetRole>[] = [
  {
    name: "name",
    label: t("labels.fleet.roles.name"),
  },
  {
    name: "rank",
    label: t("labels.fleet.roles.rank"),
  },
  {
    name: "permanent",
    label: t("labels.fleet.roles.permanent"),
  },
];
</script>

<template>
  <Heading hero class="mb-4">
    {{ t("headlines.admin.fleets.roles") }}
    <HeadingSmall>{{ roles.length }}</HeadingSmall>
  </Heading>

  <BaseTable
    :records="roles"
    primary-key="id"
    :columns="columns"
    :empty-visible="roles.length === 0"
  >
    <template #col-name="{ record }">
      <router-link
        :to="{
          name: 'admin-fleet-role',
          params: { id: props.fleet.id, roleId: record.id },
        }"
      >
        {{ record.name }}
      </router-link>
    </template>
    <template #col-permanent="{ record }">
      <i
        v-if="record.permanent"
        v-tooltip="t('labels.fleet.roles.permanent')"
        class="fa-duotone fa-check"
      />
    </template>
  </BaseTable>
</template>
