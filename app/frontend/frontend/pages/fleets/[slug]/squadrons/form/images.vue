<script lang="ts">
export default {
  name: "FleetSquadronFormImagesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import SquadronImagesFields from "@/frontend/components/Fleets/Squadrons/SquadronImagesFields/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type SquadronFormFieldProps,
  type SquadronFormFields,
} from "@/frontend/composables/useSquadronForm";
import { type FleetSquadron } from "@/services/fyApi";

type Props = {
  fields: SquadronFormFields;
  fieldProps: SquadronFormFieldProps;
  squadron?: FleetSquadron;
};

const props = withDefaults(defineProps<Props>(), { squadron: undefined });

const { t } = useI18n();
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.squadrons.formImages") }}</Heading>

  <SquadronImagesFields
    :fields="props.fields"
    :field-props="props.fieldProps"
    :squadron="props.squadron"
  />
</template>
