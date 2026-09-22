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
  <!-- The icon and the logo are the same mark at two shapes, and choosing one
       wants sight of the other. -->
  <div class="row">
    <div class="col-12 col-md-6">
      <FormFileInput
        v-model="props.fields.icon"
        v-bind="props.fieldProps.icon"
        :file="props.squadron?.icon"
        name="icon"
        :label="t('labels.fleet.squadrons.icon')"
        :info="t('labels.fleet.squadrons.iconHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
    </div>
    <div class="col-12 col-md-6">
      <FormFileInput
        v-model="props.fields.logo"
        v-bind="props.fieldProps.logo"
        :file="props.squadron?.logo"
        name="logo"
        :label="t('labels.fleet.squadrons.logo')"
        :info="t('labels.fleet.squadrons.logoHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
    </div>
  </div>

  <hr />

  <div class="row">
    <div class="col-12">
      <FormFileInput
        v-model="props.fields.header"
        v-bind="props.fieldProps.header"
        :file="props.squadron?.header"
        name="header"
        :label="t('labels.fleet.squadrons.header')"
        :info="t('labels.fleet.squadrons.headerHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
    </div>
  </div>
</template>
