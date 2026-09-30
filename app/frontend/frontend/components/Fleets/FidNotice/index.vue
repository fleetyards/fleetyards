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
import { useFleetStore } from "@/frontend/stores/fleet";

type Props = {
  fleet: Fleet;
  dismissible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  dismissible: false,
});

const slots = useSlots();

const { t, l } = useI18n();

const fleetStore = useFleetStore();

const { data: claimStatus } = useFleetFidClaim(() => props.fleet.slug);

const incomingClaim = computed(() => claimStatus.value?.incoming);

// An incoming claim has a deadline, so only the standing at-risk warning can
// be put away -- and only where the caller allows it. Keyed by id: the slug
// follows the FID, which another fleet can take over.
const fidWarningDismissed = computed(
  () =>
    props.dismissible &&
    fleetStore.dismissedFidWarnings.includes(props.fleet.id),
);

const showFidWarning = computed(
  () =>
    !incomingClaim.value &&
    !fidWarningDismissed.value &&
    fidAtRisk(props.fleet),
);

const dismissFidWarning = () => {
  fleetStore.dismissFidWarning(props.fleet.id);
};
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
    :dismissible="dismissible"
    data-test="fleet-fid-at-risk"
    @dismiss="dismissFidWarning"
  >
    {{ t("labels.fleet.rsiVerification.fidAtRisk", { fid: fleet.fid }) }}
    <template v-if="slots.actions" #actions>
      <slot name="actions" />
    </template>
  </Alert>
</template>
