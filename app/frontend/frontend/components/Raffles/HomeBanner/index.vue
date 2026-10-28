<script lang="ts">
export default {
  name: "RaffleHomeBanner",
};
</script>

<script lang="ts" setup>
import { RaffleStatusEnum } from "@/services/fyApi";
import { useHomeRaffle } from "@/frontend/components/Raffles/useHomeRaffle";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const raffle = useHomeRaffle();

const DAY = 24 * 60 * 60 * 1000;

const isOpen = computed(() => raffle.value?.status === RaffleStatusEnum.OPEN);

// Whole days left, so the last day reads as "ends today" rather than "in 1
// day" an hour before the close.
const meta = computed(() => {
  if (!raffle.value) return "";

  const target = new Date(
    isOpen.value ? raffle.value.endsAt : raffle.value.startsAt,
  ).getTime();
  const days = Math.floor((target - Date.now()) / DAY);

  if (isOpen.value) {
    return days < 1
      ? t("raffles.home.endsToday")
      : t("raffles.home.endsIn", { count: days });
  }

  return days < 1
    ? t("raffles.home.opensToday")
    : t("raffles.home.opensIn", { count: days });
});
</script>

<template>
  <router-link
    v-if="raffle"
    :to="{ name: 'raffles' }"
    class="raffle-pill"
    :class="{ 'raffle-pill--open': isOpen }"
    data-test="raffle-home-banner"
  >
    <span class="raffle-pill__tag">{{ t("raffles.home.pillTag") }}</span>
    <span class="raffle-pill__title">{{ raffle.title }}</span>
    <span class="raffle-pill__meta">{{ meta }}</span>
    <i class="fa-light fa-chevron-right raffle-pill__chevron" />
  </router-link>
</template>

<style lang="scss" scoped>
.raffle-pill {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  max-width: 100%;
  padding: 6px 12px 6px 6px;
  border: 1px solid var(--color-edge, rgba(122, 130, 136, 0.5));
  border-radius: 999px;
  background: var(--color-control, rgba(39, 43, 48, 0.9));
  color: var(--color-lifted, #eee);
  text-decoration: none;
  transition: background 150ms ease;

  &:hover {
    background: var(--color-control-hover, rgba(52, 58, 64, 0.95));
    color: var(--color-lifted, #eee);
  }
}

.raffle-pill--open {
  border-color: rgba(92, 184, 92, 0.6);
}

.raffle-pill__tag {
  padding: 4px 10px;
  border-radius: 999px;
  background: var(--color-primary, #428bca);
  color: #000;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.raffle-pill--open .raffle-pill__tag {
  background: var(--color-success, #5cb85c);
}

.raffle-pill__title {
  font-size: 0.875rem;
}

.raffle-pill__meta {
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.raffle-pill__chevron {
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}
</style>
