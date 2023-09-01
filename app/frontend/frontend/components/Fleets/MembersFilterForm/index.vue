<template>
  <form @submit.prevent="filter">
    <FormInput
      id="username"
      v-model="form.usernameCont"
      translation-key="filters.fleets.members.username"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.roleIn"
      :options="roleOptions"
      :label="t('labels.filters.fleets.members.role')"
      name="role"
      :multiple="true"
      :no-label="true"
    />

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import type { FilterGroupOption } from "@/shared/components/base/FilterGroup/Option/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { FleetMemberQuery } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const setupForm = () => {
  form.value = {
    usernameCont: routeQuery.value.usernameCont,
    roleIn: routeQuery.value.roleIn || [],
    sorts: routeQuery.value.sorts,
  };
};

const { filter, resetFilter, isFilterSelected, routeQuery } =
  useFilters<FleetMemberQuery>(setupForm);

const form = ref<FleetMemberQuery>({});

const roleOptions: FilterGroupOption[] = [
  {
    label: t("labels.fleet.members.roles.admin"),
    value: "admin",
  },
  {
    label: t("labels.fleet.members.roles.officer"),
    value: "officer",
  },
  {
    label: t("labels.fleet.members.roles.member"),
    value: "member",
  },
];
</script>

<script lang="ts">
export default {
  name: "FleetMembersFilterForm",
};
</script>
