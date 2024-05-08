<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type UserQuery } from "@/services/fyAdminApi";
import { Form } from "vee-validate";
import { useUserFilters } from "@/admin/composables/useUserFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    usernameCont: filters.value.usernameCont,
    emailCont: filters.value.emailCont,
    rsiHandleCont: filters.value.rsiHandleCont,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useUserFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<UserQuery>(prefillFormValues());

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
        name="search"
        translation-key="filters.users.search"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <FormInput
      v-model="form.usernameCont"
      name="username"
      translation-key="filters.users.username"
      :no-label="true"
      :clearable="true"
    />

    <FormInput
      v-model="form.emailCont"
      name="email"
      translation-key="filters.users.email"
      :no-label="true"
      :clearable="true"
    />

    <FormInput
      v-model="form.rsiHandleCont"
      name="rsiHandle"
      translation-key="filters.users.rsiHandle"
      :no-label="true"
      :clearable="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
