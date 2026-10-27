<script lang="ts">
export default {
  name: "RaffleConditions",
};
</script>

<script lang="ts" setup>
import { type Raffle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const CONDITIONS = [
  "confirmedAccount",
  "publicEntrants",
  "publicWinner",
  "drawOrder",
  "claimDeadline",
  "deletedAccount",
  "noCash",
  "noLiability",
  "noRecourse",
  "notAffiliated",
] as const;
</script>

<template>
  <section class="raffle-conditions" data-test="raffle-conditions">
    <h2 class="raffle-conditions__title">
      {{ t("raffles.conditions.title") }}
    </h2>
    <ol class="raffle-conditions__list">
      <li v-for="condition in CONDITIONS" :key="condition">
        {{
          t(`raffles.conditions.${condition}`, {
            days: props.raffle.claimPeriodDays,
            discordHandle: props.raffle.contacts.discordHandle,
          })
        }}
      </li>
    </ol>
    <p class="raffle-conditions__contact">
      {{
        t("raffles.conditions.contact", {
          discordHandle: props.raffle.contacts.discordHandle,
        })
      }}
      <a
        :href="props.raffle.contacts.discordInvite"
        target="_blank"
        rel="noopener"
      >
        {{ t("raffles.conditions.discordServer") }}
      </a>
    </p>
    <p class="raffle-conditions__version">
      {{
        t("raffles.conditions.version", {
          version: props.raffle.conditionsVersion,
        })
      }}
    </p>
  </section>
</template>

<style lang="scss" scoped>
.raffle-conditions__title {
  font-size: 1.1rem;
}

.raffle-conditions__list {
  padding-left: 1.25rem;

  li + li {
    margin-top: 6px;
  }
}

.raffle-conditions__version {
  font-size: 0.85rem;
  opacity: 0.7;
}
</style>
