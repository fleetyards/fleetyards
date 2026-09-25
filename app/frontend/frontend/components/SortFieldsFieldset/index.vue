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

// The sorts the list's sort bar offers, picked the same way as its columns.
const picked = defineModel<string[]>({ required: true });

const { t } = useI18n();
</script>

<template>
  <fieldset>
    <legend>
      <h3>{{ t("labels.sortOptions") }}:</h3>
    </legend>
    <div class="row">
      <div
        v-for="field in fields"
        :key="String(field.name)"
        class="col-12 col-md-6"
      >
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
