<script lang="ts">
export default {
  name: "RaffleHomeBanner",
};
</script>

<script lang="ts" setup>
import { useHomeRaffle } from "@/frontend/components/Raffles/useHomeRaffle";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const raffle = useHomeRaffle();

const DAY = 24 * 60 * 60 * 1000;

// Whole days left, so the last day reads as "ends today" rather than "in 1
// day" an hour before the close.
const meta = computed(() => {
  if (!raffle.value) return "";

  const days = Math.floor(
    (new Date(raffle.value.endsAt).getTime() - Date.now()) / DAY,
  );

  return days < 1
    ? t("raffles.home.endsToday")
    : t("raffles.home.endsIn", { count: days });
});
</script>

<template>
  <router-link
    v-if="raffle"
    :to="{ name: 'raffles' }"
    class="raffle-pill"
    data-test="raffle-home-banner"
  >
    <span class="raffle-pill__tag">{{ t("raffles.home.pillTag") }}</span>
    <span class="raffle-pill__text">
      <span class="raffle-pill__title">{{ raffle.title }}</span>
      <span class="raffle-pill__meta">{{ meta }}</span>
    </span>
    <i class="fa-light fa-chevron-right raffle-pill__chevron" />
  </router-link>
</template>

<style lang="scss" scoped>
.raffle-pill {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  max-width: 100%;
  padding: 6px 12px 6px 6px;
  border: 1px solid rgba(92, 184, 92, 0.6);
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

.raffle-pill__tag {
  padding: 4px 10px;
  border-radius: 999px;
  flex-shrink: 0;
  background: var(--color-success, #5cb85c);
  color: #000;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

// On a phone the title and the countdown share a column beside the tag, so a
// long title wraps there instead of dropping the countdown under the tag.
.raffle-pill__text {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  column-gap: 10px;
  min-width: 0;
  text-align: left;
}

.raffle-pill__title {
  font-size: 0.875rem;
}

.raffle-pill__meta {
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.raffle-pill__chevron {
  flex-shrink: 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}
</style>
