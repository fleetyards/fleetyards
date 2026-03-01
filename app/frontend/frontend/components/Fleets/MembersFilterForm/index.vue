<script lang="ts">
export default {
  name: "FleetMembersFilterForm",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { FleetMemberQuery, type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetMemberQuery>({ updateCallback: setupForm });

function setupForm() {
  form.value = {
    usernameCont: filters.value.usernameCont,
    roleIn: filters.value.roleIn || [],
    sorts: filters.value.sorts,
  };
}

const form = ref<FleetMemberQuery>({});

const roleOptions: FilterOption[] = [
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

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      id="username"
      name="username"
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
