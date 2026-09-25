<script lang="ts">
export default {
  name: "FleetSquadronFormDiscordPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import DiscordChannelSelect from "@/frontend/components/Fleets/DiscordChannelSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type SquadronFormFieldProps,
  type SquadronFormFields,
} from "@/frontend/composables/useSquadronForm";

type Props = {
  fields: SquadronFormFields;
  fieldProps: SquadronFormFieldProps;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const fleetSlug = computed(() => route.params.slug as string);
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.squadrons.formDiscord") }}</Heading>

  <div class="row">
    <div class="col-12 col-md-6">
      <DiscordChannelSelect
        v-model="props.fields.discordChannelId"
        v-bind="props.fieldProps.discordChannelId"
        :fleet-slug="fleetSlug"
        name="discordChannelId"
        :label="t('labels.fleet.squadrons.discordChannel')"
        :info="t('labels.fleet.squadrons.discordChannelHint')"
      />
    </div>
  </div>
</template>
