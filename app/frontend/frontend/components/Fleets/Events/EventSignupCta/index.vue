<script lang="ts">
export default {
  name: "FleetEventsSignupCta",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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

const signup = async (status: FleetEventSignupCreateInputStatus) => {
  submitting.value = true;
  try {
    await signupFleetEvent(props.fleetSlug, props.event.slug, { status });
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
  <section class="event-signup-cta">
    <header class="event-signup-cta__head">
      <div class="event-signup-cta__title">
        <i class="fa-light fa-bullhorn" />
        <span>{{ t("headlines.fleets.events.signupTitle") }}</span>
      </div>
      <p class="event-signup-cta__hint text-muted">
        {{ t("labels.fleets.events.signupCtaHint") }}
      </p>
    </header>
    <div class="event-signup-cta__actions">
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        :disabled="signupsLocked"
        :loading="submitting"
        :title="signupsLocked ? t('labels.fleets.events.signupsLockedHint') : ''"
        @click="signup(FleetEventSignupCreateInputStatus.confirmed)"
      >
        <i class="fa-light fa-check" />
        {{ t("labels.fleets.events.signupStatuses.confirmed") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        variant="link"
        :disabled="signupsLocked"
        :loading="submitting"
        @click="signup(FleetEventSignupCreateInputStatus.tentative)"
      >
        <i class="fa-light fa-circle-question" />
        {{ t("labels.fleets.events.signupStatuses.tentative") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        inline
        variant="link"
        :disabled="signupsLocked"
        :loading="submitting"
        @click="signup(FleetEventSignupCreateInputStatus.interested)"
      >
        <i class="fa-light fa-eye" />
        {{ t("labels.fleets.events.signupStatuses.interested") }}
      </Btn>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.event-signup-cta {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 6px;
  padding: 0.85rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
.event-signup-cta__head {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}
.event-signup-cta__title {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;

  i {
    color: var(--accent, #4aa);
  }
}
.event-signup-cta__hint {
  margin: 0;
  font-size: 0.85rem;
}
.event-signup-cta__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}
</style>
