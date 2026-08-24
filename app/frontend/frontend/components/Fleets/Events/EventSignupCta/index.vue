<script lang="ts">
export default {
  name: "FleetEventsSignupCta",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import VehiclePicker from "@/frontend/components/Fleets/Events/VehiclePicker/index.vue";
import {
  type FleetEvent,
  FleetEventSignupCreateInputStatus,
  signupFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleetSlug: string;
  event: FleetEvent;
  signupsLocked: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const submitting = ref(false);
const vehicleId = ref<string | null>(null);

const signup = async (status: FleetEventSignupCreateInputStatus) => {
  submitting.value = true;
  try {
    await signupFleetEvent(props.fleetSlug, props.event.slug, {
      status,
      vehicleId: vehicleId.value ?? undefined,
    });
    displaySuccess({ text: t("messages.fleets.eventSignup.create.success") });
    comlink.emit("fleet-event-signup-changed");
  } catch {
    displayAlert({ text: t("messages.fleets.eventSignup.create.failure") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="event-signup-cta"
    data-test="signup-cta"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("headlines.fleets.events.signupTitle") }}
    </PanelHeading>
    <PanelBody>
      <p class="event-signup-cta__hint">
        {{ t("labels.fleets.events.signupCtaHint") }}
      </p>
      <VehiclePicker v-model="vehicleId" />
      <!--
        A plain group, not a segmented one. The three are peers, which is what
        the group fixes - the old markup made confirmed a solid button and the
        other two links - but they are actions that submit, not a mode switch:
        nothing is chosen when this renders, so radio semantics would be
        claiming a selection that does not exist.
      -->
      <BtnGroup class="event-signup-cta__actions">
        <Btn
          mobile-icon-only
          :disabled="signupsLocked"
          :loading="submitting"
          :title="
            signupsLocked ? t('labels.fleets.events.signupsLockedHint') : ''
          "
          @click="signup(FleetEventSignupCreateInputStatus.confirmed)"
        >
          <i class="fa-light fa-check" />
          {{ t("labels.fleets.events.signupStatuses.confirmed") }}
        </Btn>
        <Btn
          mobile-icon-only
          :disabled="signupsLocked"
          :loading="submitting"
          @click="signup(FleetEventSignupCreateInputStatus.tentative)"
        >
          <i class="fa-light fa-circle-question" />
          {{ t("labels.fleets.events.signupStatuses.tentative") }}
        </Btn>
        <Btn
          mobile-icon-only
          :disabled="signupsLocked"
          :loading="submitting"
          @click="signup(FleetEventSignupCreateInputStatus.interested)"
        >
          <i class="fa-light fa-eye" />
          {{ t("labels.fleets.events.signupStatuses.interested") }}
        </Btn>
      </BtnGroup>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
/*
 * The frame is Panel's now. What was here - a hand-mixed rgba(255,255,255,.03)
 * fill inside a .08 edge at radius 6 - is the slim panel, and the heading with
 * its gold status dot replaces the bullhorn icon that was the only thing
 * carrying the app's invented second accent on this surface.
 */
.event-signup-cta__hint {
  margin: 4px 0 14px;
  font-size: 14px;
  color: var(--color-muted, #7a8288);
}

.event-signup-cta__actions {
  margin-top: 14px;
}
</style>
