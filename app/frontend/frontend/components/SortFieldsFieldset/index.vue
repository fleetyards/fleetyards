<script lang="ts">
export default {
  name: "SortFieldsFieldset",
};
</script>

<script lang="ts" setup>
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
type Props = {
  fields: { name: unknown; label?: string }[];
};

defineProps<Props>();

// The sorts the list's toolbar offers as chips, picked the same way as its columns.
const picked = defineModel<string[]>({ required: true });

const { t } = useI18n();
</script>

<template>
  <fieldset>
    <legend>
      <h3>{{ t("labels.sortOptions") }}:</h3>
    </legend>
    <div class="grid grid-cols-2 gap-x-4 sm:grid-cols-3">
      <div v-for="field in fields" :key="String(field.name)">
        <FormCheckbox
          v-model="picked"
          :checkbox-value="String(field.name)"
          :name="`sort-${String(field.name)}`"
          :label="field.label"
        />
      </div>
    </div>
  </fieldset>
</template>
