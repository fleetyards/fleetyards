<script lang="ts">
export default {
  name: "RafflePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import RaffleConditions from "@/frontend/components/Raffles/Conditions/index.vue";
import RaffleEntrants from "@/frontend/components/Raffles/Entrants/index.vue";
import {
  RaffleStatusEnum,
  raffleCode,
  useRaffle,
  useEnterRaffle,
  useWithdrawFromRaffle,
  useClaimRaffle,
  getRaffleQueryKey,
  getRafflesQueryKey,
  getRaffleEntrantsQueryKey,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t, l } = useI18n();
const route = useRoute();
const queryClient = useQueryClient();
const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();

const { isAuthenticated } = storeToRefs(useSessionStore());

const raffleId = computed(() => route.params.id as string);

const { data: raffle, ...asyncStatus } = useRaffle(raffleId);

const invalidate = () =>
  Promise.all([
    queryClient.invalidateQueries({
      queryKey: getRaffleQueryKey(raffleId.value),
    }),
    queryClient.invalidateQueries({ queryKey: getRafflesQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getRaffleEntrantsQueryKey(raffleId.value),
    }),
  ]);

const enterMutation = useEnterRaffle({ mutation: { onSettled: invalidate } });
const withdrawMutation = useWithdrawFromRaffle({
  mutation: { onSettled: invalidate },
});
const claimMutation = useClaimRaffle({ mutation: { onSettled: invalidate } });

const conditionsAccepted = ref(false);
const giftCode = ref<string>();

const errorText = (error: {
  response?: { status?: number; data?: { message?: string } };
}) => {
  if (error.response?.status === 403) return t("raffles.messages.forbidden");

  return error.response?.data?.message || t("raffles.messages.failed");
};

const enter = async () => {
  await enterMutation
    .mutateAsync({
      raffleId: raffleId.value,
      data: { conditionsAccepted: conditionsAccepted.value },
    })
    .then(() => {
      displaySuccess({ text: t("raffles.messages.entered") });
    })
    .catch((error) => {
      displayAlert({ text: errorText(error) });
    });
};

const withdraw = () => {
  displayConfirm({
    text: t("raffles.messages.confirmWithdraw"),
    onConfirm: async () => {
      await withdrawMutation
        .mutateAsync({ raffleId: raffleId.value })
        .then(() => {
          conditionsAccepted.value = false;
          displaySuccess({ text: t("raffles.messages.withdrawn") });
        })
        .catch((error) => {
          displayAlert({ text: errorText(error) });
        });
    },
  });
};

const claim = async () => {
  await claimMutation
    .mutateAsync({ id: raffleId.value })
    .then((response) => {
      giftCode.value = response.code;
    })
    .catch((error) => {
      displayAlert({ text: errorText(error) });
    });
};

const showCode = async () => {
  await raffleCode(raffleId.value)
    .then((response) => {
      giftCode.value = response.code;
    })
    .catch((error) => {
      displayAlert({ text: errorText(error) });
    });
};

const isOpen = computed(() => raffle.value?.status === RaffleStatusEnum.OPEN);
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'raffles' }, label: t('raffles.title') }]"
  />
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="raffle">
        <Heading hero>{{ raffle.title }}</Heading>

        <div class="raffle">
          <div class="raffle__main">
            <img
              v-if="raffle.prize?.storeImage?.largeUrl"
              :src="raffle.prize.storeImage.largeUrl"
              :alt="raffle.prize.name"
              class="raffle__image"
            />
            <p v-if="raffle.prize" class="raffle__prize">
              {{ t("raffles.prize", { name: raffle.prize.name }) }}
            </p>
            <p v-if="raffle.description" class="raffle__description">
              {{ raffle.description }}
            </p>
            <dl class="raffle__facts">
              <dt>{{ t("raffles.status") }}</dt>
              <dd>{{ t(`raffles.statuses.${raffle.status}`) }}</dd>
              <dt>{{ t("raffles.runs") }}</dt>
              <dd>
                {{ l(raffle.startsAt, "datetime.formats.short") }} –
                {{ l(raffle.endsAt, "datetime.formats.short") }}
              </dd>
              <dt>{{ t("raffles.entrants.count") }}</dt>
              <dd>{{ raffle.entriesCount }}</dd>
            </dl>

            <Alert
              v-if="giftCode"
              :title="t('raffles.code.title')"
              :variant="AlertVariantsEnum.SUCCESS"
              data-test="raffle-gift-code"
            >
              <code class="raffle__code">{{ giftCode }}</code>
              <p>{{ t("raffles.code.hint") }}</p>
            </Alert>

            <Alert
              v-else-if="raffle.claimable"
              :title="t('raffles.won.title')"
              :variant="AlertVariantsEnum.SUCCESS"
            >
              <p>
                {{
                  t("raffles.won.deadline", {
                    date: l(
                      raffle.currentWinner?.claimDeadlineAt as string,
                      "datetime.formats.short",
                    ),
                  })
                }}
              </p>
              <Btn
                :loading="claimMutation.isPending.value"
                data-test="raffle-claim"
                @click="claim"
              >
                <i class="fa-duotone fa-gift" />
                {{ t("raffles.actions.claim") }}
              </Btn>
            </Alert>

            <Alert
              v-else-if="raffle.claimed"
              :title="t('raffles.won.claimed')"
              :variant="AlertVariantsEnum.SUCCESS"
            >
              <Btn data-test="raffle-show-code" @click="showCode">
                <i class="fa-duotone fa-eye" />
                {{ t("raffles.actions.showCode") }}
              </Btn>
            </Alert>

            <template v-if="raffle.currentWinner">
              <h2 class="raffle__section-title">
                {{ t("raffles.winner.title") }}
              </h2>
              <p data-test="raffle-winner">
                {{
                  t(
                    raffle.currentWinner.claimedAt
                      ? "raffles.winner.claimed"
                      : "raffles.winner.pending",
                    {
                      username: raffle.currentWinner.username,
                      date: l(
                        raffle.currentWinner.claimDeadlineAt,
                        "datetime.formats.short",
                      ),
                    },
                  )
                }}
              </p>
            </template>
            <template v-if="raffle.forfeitedWinners.length">
              <h3 class="raffle__section-title">
                {{ t("raffles.winner.forfeited") }}
              </h3>
              <ul>
                <li
                  v-for="winner in raffle.forfeitedWinners"
                  :key="winner.drawPosition"
                >
                  {{ winner.username }}
                </li>
              </ul>
            </template>

            <RaffleEntrants :raffle-id="raffle.id" />
          </div>

          <aside class="raffle__aside">
            <RaffleConditions :raffle="raffle" />

            <template v-if="isOpen">
              <p v-if="!isAuthenticated">
                <router-link
                  :to="{ name: 'login', query: { redirect: route.fullPath } }"
                >
                  {{ t("raffles.actions.signInToEnter") }}
                </router-link>
              </p>
              <template v-else-if="raffle.entered">
                <Alert :variant="AlertVariantsEnum.SUCCESS">
                  {{ t("raffles.entered") }}
                </Alert>
                <Btn
                  :loading="withdrawMutation.isPending.value"
                  data-test="raffle-withdraw"
                  @click="withdraw"
                >
                  {{ t("raffles.actions.withdraw") }}
                </Btn>
              </template>
              <form
                v-else
                class="raffle__enter"
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
                  :disabled="!conditionsAccepted"
                  :loading="enterMutation.isPending.value"
                  data-test="raffle-enter"
                >
                  <i class="fa-duotone fa-ticket" />
                  {{ t("raffles.actions.enter") }}
                </Btn>
              </form>
            </template>
          </aside>
        </div>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.raffle {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  gap: 24px;

  @media (width <= 991px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.raffle__image {
  width: 100%;
  border-radius: 8px;
}

.raffle__prize {
  font-size: 1.1rem;
  font-weight: 600;
}

.raffle__description {
  white-space: pre-line;
}

.raffle__facts {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 4px 16px;

  dd {
    margin: 0;
  }
}

.raffle__code {
  display: block;
  margin-bottom: 8px;
  font-size: 1.25rem;
  letter-spacing: 0.1em;
  user-select: all;
}

.raffle__section-title {
  font-size: 1.1rem;
}

.raffle__enter {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
</style>
