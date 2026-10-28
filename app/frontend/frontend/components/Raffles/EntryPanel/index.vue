<script lang="ts">
export default {
  name: "RaffleEntryPanel",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Raffle,
  RaffleStatusEnum,
  useEnterRaffle,
  useWithdrawFromRaffle,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  changed: [];
}>();

const { t, l } = useI18n();
const route = useRoute();
const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();
const { isAuthenticated } = storeToRefs(useSessionStore());

const enterMutation = useEnterRaffle({
  mutation: { onSettled: () => emit("changed") },
});
const withdrawMutation = useWithdrawFromRaffle({
  mutation: { onSettled: () => emit("changed") },
});

const conditionsAccepted = ref(false);

const isOpen = computed(() => props.raffle.status === RaffleStatusEnum.OPEN);

const errorText = (error: {
  response?: { status?: number; data?: { message?: string } };
}) => {
  if (error.response?.status === 403) return t("raffles.messages.forbidden");

  return error.response?.data?.message || t("raffles.messages.failed");
};

const enter = async () => {
  await enterMutation
    .mutateAsync({
      raffleId: props.raffle.id,
      data: { conditionsAccepted: conditionsAccepted.value },
    })
    .then(() => displaySuccess({ text: t("raffles.messages.entered") }))
    .catch((error) => displayAlert({ text: errorText(error) }));
};

const withdraw = () => {
  displayConfirm({
    text: t("raffles.messages.confirmWithdraw"),
    onConfirm: async () => {
      await withdrawMutation
        .mutateAsync({ raffleId: props.raffle.id })
        .then(() => {
          conditionsAccepted.value = false;
          displaySuccess({ text: t("raffles.messages.withdrawn") });
        })
        .catch((error) => displayAlert({ text: errorText(error) }));
    },
  });
};

const title = computed(() => {
  if (props.raffle.won || props.raffle.entered) return t("raffles.entry.yours");

  return t("raffles.entry.title");
});
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="raffle-entry"
    data-test="raffle-entry-panel"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ title }}
    </PanelHeading>
    <PanelBody>
      <div class="metrics-card__rows">
        <div class="metrics-card__row">
          <div class="metrics-card__row__label">
            {{ t(isOpen ? "raffles.entry.closes" : "raffles.entry.closed") }}
          </div>
          <div class="metrics-card__row__value">
            {{ l(raffle.endsAt, "datetime.formats.short") }}
          </div>
        </div>
        <div class="metrics-card__row">
          <div class="metrics-card__row__label">
            {{ t("raffles.entrants.count") }}
          </div>
          <div class="metrics-card__row__value">{{ raffle.entriesCount }}</div>
        </div>
        <div class="metrics-card__row">
          <div class="metrics-card__row__label">
            {{ t("raffles.entry.claimPeriod") }}
          </div>
          <div class="metrics-card__row__value">
            {{ t("raffles.entry.days", { days: raffle.claimPeriodDays }) }}
          </div>
        </div>
      </div>

      <div class="raffle-entry__actions">
        <Alert
          v-if="raffle.claimable"
          :title="t('raffles.won.title')"
          :variant="AlertVariantsEnum.SUCCESS"
          data-test="raffle-won"
        >
          {{
            t("raffles.won.checkMail", {
              date: l(
                raffle.currentWinner?.claimDeadlineAt as string,
                "datetime.formats.short",
              ),
            })
          }}
        </Alert>
        <Alert
          v-else-if="raffle.claimed"
          :title="t('raffles.won.claimed')"
          :variant="AlertVariantsEnum.SUCCESS"
        >
          {{ t("raffles.won.codeSent") }}
        </Alert>

        <template v-else-if="isOpen">
          <p v-if="!isAuthenticated">
            <router-link
              :to="{ name: 'login', query: { redirect: route.fullPath } }"
            >
              {{ t("raffles.actions.signInToEnter") }}
            </router-link>
          </p>
          <template v-else-if="raffle.entered">
            <Alert
              :variant="AlertVariantsEnum.SUCCESS"
              :size="AlertSizesEnum.COMPACT"
            >
              {{
                t("raffles.entry.entered", {
                  date: l(raffle.endsAt, "datetime.formats.short"),
                })
              }}
            </Alert>
            <p class="raffle-entry__hint">
              {{
                t("raffles.entry.enteredHint", { days: raffle.claimPeriodDays })
              }}
            </p>
            <Btn
              :size="BtnSizesEnum.MD"
              :loading="withdrawMutation.isPending.value"
              data-test="raffle-withdraw"
              @click="withdraw"
            >
              {{ t("raffles.actions.withdraw") }}
            </Btn>
          </template>
          <form
            v-else
            class="raffle-entry__form"
            data-test="raffle-enter-form"
            @submit.prevent="enter"
          >
            <FormCheckbox
              v-model="conditionsAccepted"
              name="conditionsAccepted"
              :label="t('raffles.conditions.accept')"
              data-test="raffle-accept-conditions"
            />
            <Btn
              type="submit"
              :size="BtnSizesEnum.LG"
              :disabled="!conditionsAccepted"
              :loading="enterMutation.isPending.value"
              block
              data-test="raffle-enter"
            >
              <i class="fa-light fa-ticket" />
              {{ t("raffles.actions.enter") }}
            </Btn>
          </form>
        </template>

        <p v-else-if="raffle.status === RaffleStatusEnum.UPCOMING">
          {{
            t("raffles.entry.opensAt", {
              date: l(raffle.startsAt, "datetime.formats.short"),
            })
          }}
        </p>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.raffle-entry__actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 12px;
}

.raffle-entry__form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.raffle-entry__hint {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
