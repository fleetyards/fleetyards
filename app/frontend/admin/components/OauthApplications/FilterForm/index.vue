<script lang="ts">
export default {
  name: "AdminOauthApplicationsFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import {
  type OauthApplicationQuery,
  OauthApplicationQueryAasmStateEq,
} from "@/services/fyAdminApi";

const { t } = useI18n();

// The owner is set by clicking an owner in the list rather than typed here,
// but it still has to round-trip through the form: a key missing from what the
// form writes back would be dropped from the URL on the next edit.
const prefillFormValues = (): OauthApplicationQuery => ({
  nameCont: filters.value.nameCont,
  aasmStateEq: filters.value.aasmStateEq,
  ownerIdEq: filters.value.ownerIdEq,
});

const { filter, filters, isFilterSelected, resetFilter } =
  useFilters<OauthApplicationQuery>({
    updateCallback: () => {
      form.value = prefillFormValues();
    },
  });

const form = ref<OauthApplicationQuery>(prefillFormValues());

const stateLabels: Record<OauthApplicationQueryAasmStateEq, string> = {
  pending: t("labels.oauthApplications.statePending"),
  approved: t("labels.oauthApplications.stateApproved"),
  rejected: t("labels.oauthApplications.stateRejected"),
};

const stateOptions = Object.values(OauthApplicationQueryAasmStateEq).map(
  (state) => ({ value: state, label: stateLabels[state] }),
);

const clearOwner = () => {
  form.value = { ...form.value, ownerIdEq: undefined };
};

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="filter(form)">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        :label="t('labels.oauthApplications.search')"
        :placeholder="t('labels.oauthApplications.search')"
        no-label
        clearable
        inline
      />
    </Teleport>
    <BaseSelect
      v-model="form.aasmStateEq"
      name="state"
      :label="t('labels.oauthApplications.state')"
      :options="stateOptions"
    />
    <Btn
      v-if="form.ownerIdEq"
      :block="true"
      data-test="clear-owner"
      @click="clearOwner"
    >
      <i class="fa-light fa-user-xmark" />
      {{ t("labels.oauthApplications.clearOwner") }}
    </Btn>
    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
