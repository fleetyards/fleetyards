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
      <VSwatches v-model="props.fields.color" :inline="true" />
    </div>
  </div>
</template>
