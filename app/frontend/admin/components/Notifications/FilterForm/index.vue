<script lang="ts">
export default {
  name: "AdminNotificationsFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type AdminNotificationQuery,
  AdminNotificationSeverityEnum,
  AdminNotificationTypeEnum,
} from "@/services/fyAdminApi";
import { useAdminNotificationFilters } from "@/admin/composables/useAdminNotificationFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    notificationTypeEq: filters.value.notificationTypeEq,
    severityEq: filters.value.severityEq,
    readAtNull: filters.value.readAtNull,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useAdminNotificationFilters(setupForm);

const form = ref<AdminNotificationQuery>(prefillFormValues());

const typeOptions = Object.values(AdminNotificationTypeEnum).map((value) => ({
  value,
  label: t(`labels.adminNotifications.types.${value}`),
}));

const severityOptions = Object.values(AdminNotificationSeverityEnum).map(
  (value) => ({
    value,
    label: t(`labels.adminNotifications.severities.${value}`),
  }),
);

const unreadOptions = [
  {
    value: "true",
    label: t("labels.adminNotifications.unreadOnly"),
  },
];

const handleSubmit = () => {
  filter(form.value);
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
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.searchCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.adminNotifications.search"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <RadioList
      v-model="form.readAtNull"
      :label="t('labels.adminNotifications.status')"
      :reset-label="t('labels.all')"
      :options="unreadOptions"
      name="readAtNull"
    />

    <RadioList
      v-model="form.severityEq"
      :label="t('labels.adminNotifications.severity')"
      :reset-label="t('labels.all')"
      :options="severityOptions"
      name="severityEq"
    />

    <BaseSelect
      v-model="form.notificationTypeEq"
      :label="t('labels.adminNotifications.type')"
      :options="typeOptions"
      name="notificationTypeEq"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
