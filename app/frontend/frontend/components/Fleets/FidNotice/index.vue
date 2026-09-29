<script lang="ts">
export default {
  name: "FleetFidNotice",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { fidAtRisk } from "@/frontend/utils/rsiSid";
import { type Fleet, useFleetFidClaim } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const slots = useSlots();

const { t, l } = useI18n();

const { data: claimStatus } = useFleetFidClaim(() => props.fleet.slug);

const incomingClaim = computed(() => claimStatus.value?.incoming);

const showFidWarning = computed(
  () => !incomingClaim.value && fidAtRisk(props.fleet),
);
</script>

<template>
  <Alert
    v-if="incomingClaim"
    :variant="AlertVariantsEnum.DANGER"
    :title="
      t('labels.fleet.fidClaim.incomingTitle', {
        claimant: incomingClaim.claimantName,
      })
    "
    data-test="fleet-fid-claim-incoming"
  >
    <!-- Markdown, like the notification about the same claim: the date, what
         happens on it, and how to keep the ID, rather than one paragraph. -->
    <Markdown
      :source="
        t('labels.fleet.fidClaim.incoming', {
          claimant: incomingClaim.claimantName,
          fid: incomingClaim.fid,
          date: l(incomingClaim.endsAt, 'datetime.formats.date'),
        })
      "
    />
    <template v-if="slots.actions" #actions>
      <slot name="actions" />
    </template>
  </Alert>
  <Alert
    v-else-if="showFidWarning"
    :variant="AlertVariantsEnum.WARNING"
    :title="t('labels.fleet.rsiVerification.fidAtRiskTitle')"
    data-test="fleet-fid-at-risk"
  >
    {{ t("labels.fleet.rsiVerification.fidAtRisk", { fid: fleet.fid }) }}
    <template v-if="slots.actions" #actions>
      <slot name="actions" />
    </template>
  </Alert>
</template>
