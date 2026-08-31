<script lang="ts">
export default {
  name: "ImportsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import AdminUserSelect from "@/admin/components/base/AdminUserSelect/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ImportQuery,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const formatTypeLabel = (type: string) =>
  type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();

const typeOptions = Object.values(ImportTypeEnum).map((value) => ({
  label: formatTypeLabel(value),
  value,
}));

const statusOptions = Object.values(ImportStatusEnum).map((value) => ({
  label: t(`labels.imports.statuses.${value}`),
  value,
}));

const normalizeIncludeSystem = (value: unknown): boolean => {
  return value === true || value === "true";
};

const prefillFormValues = (): ImportQuery => ({
  typeIn: filters.value.typeIn || [],
  aasmStateIn: filters.value.aasmStateIn || [],
  adminUserUsernameIn: filters.value.adminUserUsernameIn || [],
  userUsernameIn: filters.value.userUsernameIn || [],
  includeSystem: normalizeIncludeSystem(filters.value.includeSystem),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<ImportQuery>({
    updateCallback: setupForm,
  });

const form = ref<ImportQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent>
    <BaseSelect
      v-model="form.typeIn"
      :label="t('labels.imports.type')"
      :options="typeOptions"
      :multiple="true"
      name="type"
    />
    <BaseSelect
      v-model="form.aasmStateIn"
      :label="t('labels.imports.status')"
      :options="statusOptions"
      :multiple="true"
      name="status"
    />
    <AdminUserSelect
      v-model="form.adminUserUsernameIn"
      name="admin-user"
      multiple
    />
    <UserSelect v-model="form.userUsernameIn" name="user" multiple />
    <FormCheckbox
      v-model="form.includeSystem"
      :label="t('labels.imports.includeSystem')"
      name="include-system"
    />
    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
