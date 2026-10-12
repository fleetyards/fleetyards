<script lang="ts">
export default {
  name: "StatsCardContactLinks",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  rsiHandle?: string | null;
  discordUrl?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  rsiHandle: undefined,
  discordUrl: undefined,
});

const { t } = useI18n();

const spectrumDmUrl = computed(() =>
  props.rsiHandle
    ? `https://robertsspaceindustries.com/spectrum/messages/member/${props.rsiHandle}`
    : undefined,
);
</script>

<template>
  <div
    v-if="spectrumDmUrl || discordUrl"
    class="stats-card-contact"
    data-test="stats-card-contact"
  >
    <span class="stats-card-contact__label">
      {{ t("labels.fleet.members.contact") }}
    </span>
    <span class="stats-card-contact__links">
      <a
        v-if="spectrumDmUrl"
        :href="spectrumDmUrl"
        target="_blank"
        rel="noopener"
        class="stats-card-contact__link"
      >
        <i class="icon icon-rsi" aria-hidden="true" />
        {{ t("labels.fleet.members.spectrumDm") }}
      </a>
      <a
        v-if="discordUrl"
        :href="discordUrl"
        target="_blank"
        rel="noopener"
        class="stats-card-contact__link"
      >
        <i class="fa-brands fa-discord" aria-hidden="true" />
        {{ t("labels.fleet.members.discordContact") }}
      </a>
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "../label";

// A labelled line of its own under the card's figures: the label above, the
// ways to reach the person side by side, wrapping before they squeeze.
.stats-card-contact {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 12px;
}

.stats-card-contact__label {
  @include stats-card-label;
}

.stats-card-contact__links {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
}

.stats-card-contact__link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 28px;
  color: var(--color-primary, #428bca);
  font-size: 0.85rem;
  font-weight: 600;
  white-space: nowrap;

  &:hover,
  &:focus-visible {
    color: var(--color-lifted, #eee);
    text-decoration: none;
  }
}
</style>
