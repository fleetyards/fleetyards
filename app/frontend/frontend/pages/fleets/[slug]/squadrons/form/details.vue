<script lang="ts">
export default {
  name: "FleetSquadronFormDetailsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import SquadronDetailsFields from "@/frontend/components/Fleets/Squadrons/SquadronDetailsFields/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
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
  <Heading hero>{{ t("headlines.fleets.squadrons.formDetails") }}</Heading>

  <SquadronDetailsFields
    :fields="props.fields"
    :field-props="props.fieldProps"
    :validation-schema="props.validationSchema"
  />
</template>
