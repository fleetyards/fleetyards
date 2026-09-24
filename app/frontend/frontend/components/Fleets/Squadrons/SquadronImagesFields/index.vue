<script lang="ts">
export default {
  name: "FleetSquadronImagesFields",
};
</script>

<script lang="ts" setup>
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
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
  </div>
</template>
