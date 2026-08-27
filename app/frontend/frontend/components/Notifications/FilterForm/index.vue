<script lang="ts">
export default {
  name: "NotificationsFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type NotificationQuery, NotificationTypeEnum } from "@/services/fyApi";
import { useNotificationFilters } from "@/frontend/composables/useNotificationFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    notificationTypeEq: filters.value.notificationTypeEq,
    readAtNull: filters.value.readAtNull,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useNotificationFilters(setupForm);

const form = ref<NotificationQuery>(prefillFormValues());

const typeOptions = Object.values(NotificationTypeEnum).map((value) => ({
  value,
  label: t(`labels.notificationTypes.${value}`),
}));

const unreadOptions = [
  {
    value: "true",
    label: t("labels.notifications.unreadOnly"),
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
        translation-key="filters.notifications.search"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <RadioList
      v-model="form.readAtNull"
      :label="t('labels.notifications.status')"
      :reset-label="t('labels.all')"
      :options="unreadOptions"
      name="readAtNull"
    />

    <FilterGroup
      v-model="form.notificationTypeEq"
      :label="t('labels.notifications.type')"
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
