<template>
  <form
    @submit.prevent="
      () => {
        filter;
      }
    "
  >
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

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilters } from "@/frontend/composables/useFilters";

type TFleetMembersFilterForm = {
  usernameCont?: string;
  roleIn?: string[];
};

const { t } = useI18n();

const route = useRoute();

const query = computed(() => (route.query.q || {}) as TFleetMembersFilterForm);

const { resetFilter, isFilterSelected, filter, form, updateFilter } =
  useFilters({
    usernameCont: query.value.usernameCont,
    roleIn: query.value.roleIn || [],
  });

const roleOptions = computed(() => [
  {
    name: t("labels.fleet.members.roles.admin"),
    value: "admin",
  },
  {
    name: t("labels.fleet.members.roles.officer"),
    value: "officer",
  },
  {
    name: t("labels.fleet.members.roles.member"),
    value: "member",
  },
]);

watch(
  () => route.query,
  () => {
    updateFilter({
      usernameCont: query.value.usernameCont,
      roleIn: query.value.roleIn || [],
    });
  },
  { deep: true }
);
</script>

<script lang="ts">
export default {
  name: "MembersFilterForm",
};
</script>
