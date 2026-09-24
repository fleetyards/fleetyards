<script lang="ts">
export default {
  name: "FleetSquadronAppearanceFields",
};
</script>

<script lang="ts" setup>
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { VSwatches } from "vue3-swatches";
import { keyColorsFromFile } from "@/shared/utils/KeyColors";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type SquadronFormFieldProps,
  type SquadronFormFields,
} from "@/frontend/composables/useSquadronForm";
import { type FleetSquadron } from "@/services/fyApi";

type Props = {
  fields: SquadronFormFields;
  fieldProps: SquadronFormFieldProps;
  // Absent while the squadron is being created, when there is nothing attached
  // yet -- the upload itself works either way, since it hands back a signed id
  // of its own before any record exists.
  squadron?: FleetSquadron;
};

const props = withDefaults(defineProps<Props>(), { squadron: undefined });

const { t } = useI18n();

const suggestions = ref<string[]>([]);

const suggestColors = async (file: File) => {
  try {
    suggestions.value = await keyColorsFromFile(file);
  } catch {
    // A format the browser cannot decode still uploads; it just suggests nothing.
    suggestions.value = [];
  }
};

watch(
  () => props.fields.icon,
  (icon) => {
    if (!icon) suggestions.value = [];
  },
);
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="props.fields.icon"
        v-bind="props.fieldProps.icon"
        :file="props.squadron?.icon"
        name="icon"
        :label="t('labels.fleet.squadrons.icon')"
        :info="t('labels.fleet.squadrons.iconHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
        avatar
        @uploaded="suggestColors"
      />
    </div>
    <div class="col-12 col-md-8">
      <FormInput
        v-model="props.fields.color"
        v-bind="props.fieldProps.color"
        name="color"
        :type="InputTypesEnum.COLOR"
        :label="t('labels.fleet.squadrons.color')"
      />
      <div
        v-if="suggestions.length"
        class="squadron-color-suggestions"
        data-test="color-suggestions"
      >
        <span>{{ t("labels.fleet.squadrons.colorSuggestions") }}</span>
        <button
          v-for="suggestion in suggestions"
          :key="suggestion"
          type="button"
          class="squadron-color-suggestion"
          :class="{
            'squadron-color-suggestion--active':
              props.fields.color?.toLowerCase() === suggestion,
          }"
          :style="{ backgroundColor: suggestion }"
          :aria-label="suggestion"
          :title="suggestion"
          @click="props.fields.color = suggestion"
        />
      </div>
      <VSwatches v-model="props.fields.color" :inline="true" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.squadron-color-suggestions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  color: var(--color-text-dim);
}

.squadron-color-suggestion {
  width: 28px;
  height: 28px;
  padding: 0;
  border: 2px solid transparent;
  border-radius: 50%;
  box-shadow: inset 0 0 0 1px rgb(0 0 0 / 0.25);
  cursor: pointer;

  &--active,
  &:focus-visible {
    border-color: var(--color-text, #fff);
  }
}
</style>
