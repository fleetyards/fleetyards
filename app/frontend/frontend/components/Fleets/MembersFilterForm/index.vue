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
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";

type Props = {
  variant?: "members" | "invites";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "members",
});

const { t } = useI18n();

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetMemberQuery>({
    updateCallback: setupForm,
  });

function setupForm() {
  form.value = {
    usernameCont: filters.value.usernameCont,
    roleIn: filters.value.roleIn || [],
    sorts: filters.value.sorts,
    ...(props.variant === "members" && {
      acceptedAtGteq: filters.value.acceptedAtGteq,
      acceptedAtLteq: filters.value.acceptedAtLteq,
    }),
    ...(props.variant === "invites" && {
      stateIn: filters.value.stateIn || [],
      invitedAtGteq: filters.value.invitedAtGteq,
      invitedAtLteq: filters.value.invitedAtLteq,
      requestedAtGteq: filters.value.requestedAtGteq,
      requestedAtLteq: filters.value.requestedAtLteq,
      declinedAtGteq: filters.value.declinedAtGteq,
      declinedAtLteq: filters.value.declinedAtLteq,
    }),
  };
}

const form = ref<FleetMemberQuery>({});

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

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

const stateOptions: FilterOption[] = [
  {
    label: t("labels.fleet.members.invited"),
    value: "invited",
  },
  {
    label: t("labels.fleet.members.requested"),
    value: "requested",
  },
  {
    label: t("labels.fleet.members.declined"),
    value: "declined",
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

    <template v-if="variant === 'members'">
      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.acceptedAtGteq"
            name="accepted-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.acceptedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.acceptedAtLteq"
            name="accepted-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.acceptedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>
    </template>

    <template v-if="variant === 'invites'">
      <FilterGroup
        v-model="form.stateIn"
        :options="stateOptions"
        :label="t('labels.filters.fleets.members.state')"
        name="state"
        :multiple="true"
        :no-label="true"
      />

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.invitedAtGteq"
            name="invited-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.invitedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.invitedAtLteq"
            name="invited-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.invitedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.requestedAtGteq"
            name="requested-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.requestedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.requestedAtLteq"
            name="requested-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.requestedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="form.declinedAtGteq"
            name="declined-at-gteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.declinedAtGt"
            :no-placeholder="true"
          />
        </div>
        <div class="col-6">
          <FormInput
            v-model="form.declinedAtLteq"
            name="declined-at-lteq"
            :type="InputTypesEnum.DATE"
            translation-key="filters.fleets.members.declinedAtLt"
            :no-placeholder="true"
          />
        </div>
      </div>
    </template>

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
