<script lang="ts">
export default {
  name: "SquadronMembersFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import type { FleetSquadronMemberQuery } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";

const { t } = useI18n();
const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetSquadronMemberQuery>();

const form = ref<FleetSquadronMemberQuery>({});

const setupForm = () => {
  form.value = {
    usernameCont: filters.value.usernameCont,
    roleIn: undefined,
    acceptedAtGteq: undefined,
    acceptedAtLteq: undefined,
    squadronMembershipCreatedAtGteq:
      filters.value.squadronMembershipCreatedAtGteq,
    squadronMembershipCreatedAtLteq:
      filters.value.squadronMembershipCreatedAtLteq,
    sorts: filters.value.sorts,
  };
};

watch(filters, setupForm, { deep: true, immediate: true });

watch(form, () => filter(form.value), { deep: true });
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      id="squadron-member-username"
      v-model="form.usernameCont"
      name="username"
      :size="InputSizesEnum.MEDIUM"
      :label="t('labels.username')"
      :placeholder="t('placeholders.filters.fleets.members.username')"
      :clearable="true"
    />

    <div class="row squadron-member-date-range">
      <div class="col-6">
        <FormDatePicker
          v-model="form.squadronMembershipCreatedAtGteq"
          name="squadron-membership-created-at-gteq"
          translation-key="filters.fleets.members.acceptedAtGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormDatePicker
          v-model="form.squadronMembershipCreatedAtLteq"
          name="squadron-membership-created-at-lteq"
          translation-key="filters.fleets.members.acceptedAtLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<style lang="scss" scoped>
.squadron-member-date-range > * {
  min-width: 0;
}

.squadron-member-date-range :deep(.form-date-picker),
.squadron-member-date-range :deep(.dp__main),
.squadron-member-date-range :deep(.dp__input_wrap) {
  width: 100%;
  min-width: 0;
  max-width: 100%;
}
</style>
