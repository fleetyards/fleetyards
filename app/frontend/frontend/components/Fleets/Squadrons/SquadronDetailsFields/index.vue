<script lang="ts">
export default {
  name: "FleetSquadronDetailsFields",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { VSwatches } from "vue3-swatches";
import { useI18n } from "@/shared/composables/useI18n";
import {
  DESCRIPTION_MAX,
  SHORT_DESCRIPTION_MAX,
  type SquadronFormFieldProps,
  type SquadronFormFields,
} from "@/frontend/composables/useSquadronForm";

type Props = {
  fields: SquadronFormFields;
  fieldProps: SquadronFormFieldProps;
  validationSchema: Record<string, string>;
};

const props = defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormInput
        v-model="props.fields.name"
        v-bind="props.fieldProps.name"
        name="name"
        :rules="props.validationSchema.name"
        :label="t('labels.fleet.squadrons.name')"
      />
    </div>
  </div>

  <!-- The picker beside the field it writes into rather than under it: the
       swatches are the quick way to answer the input, not a second question. -->
  <div class="row">
    <div class="col-12 col-md-6">
      <FormInput
        v-model="props.fields.color"
        v-bind="props.fieldProps.color"
        name="color"
        :type="InputTypesEnum.COLOR"
        :label="t('labels.fleet.squadrons.color')"
      />
    </div>
    <div class="col-12 col-md-6">
      <VSwatches v-model="props.fields.color" :inline="true" />
    </div>
  </div>

  <hr />

  <!-- The exception, not the rule: a member belongs to one squadron, and a team
       is what that member can be on as well. The hint carries it, because a
       lone toggle reading "Team" says nothing about what it changes. -->
  <div class="row">
    <div class="col-12 col-md-6">
      <FormToggle
        v-model="props.fields.team"
        v-bind="props.fieldProps.team"
        name="team"
        :label="t('labels.fleet.squadrons.team')"
        :info="t('labels.fleet.squadrons.teamHint')"
      />
    </div>
  </div>

  <hr />

  <div class="row">
    <div class="col-12">
      <FormTextarea
        v-model="props.fields.shortDescription"
        v-bind="props.fieldProps.shortDescription"
        name="shortDescription"
        :rules="props.validationSchema.shortDescription"
        :maxlength="SHORT_DESCRIPTION_MAX"
        :label="t('labels.fleet.squadrons.shortDescription')"
        :info="t('labels.fleet.squadrons.shortDescriptionHint')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 squadron-description-field">
      <FormTextarea
        v-model="props.fields.description"
        v-bind="props.fieldProps.description"
        name="description"
        :rules="props.validationSchema.description"
        :maxlength="DESCRIPTION_MAX"
        :label="t('labels.fleet.squadrons.description')"
        :info="t('labels.fleet.squadrons.descriptionHint')"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
// Taller than the default textarea: this is the page's prose, and the
// description of a squadron opening at the same three lines as its one-line
// card subtitle read as though it wanted the same answer.
.squadron-description-field :deep(textarea) {
  min-height: 260px;
}
</style>
