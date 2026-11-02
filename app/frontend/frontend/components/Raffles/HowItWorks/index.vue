<script lang="ts">
export default {
  name: "RaffleHowItWorks",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { type Raffle } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const STEPS = ["enter", "draw", "claim", "code"] as const;
</script>

<template>
  <Panel :variant="PanelVariantsEnum.SLIM" data-test="raffle-how-it-works">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("raffles.howItWorks.title") }}
    </PanelHeading>
    <PanelBody>
      <ol class="raffle-steps">
        <li
          v-for="(step, index) in STEPS"
          :key="step"
          class="raffle-steps__step"
        >
          <span class="raffle-steps__number">{{ index + 1 }}</span>
          <div>
            <div class="raffle-steps__title">
              {{
                t(`raffles.howItWorks.${step}.title`, {
                  date: l(props.raffle.endsAt, "datetime.formats.short"),
                  days: props.raffle.claimPeriodDays,
                })
              }}
            </div>
            <div class="raffle-steps__text">
              {{
                t(`raffles.howItWorks.${step}.text`, {
                  days: props.raffle.claimPeriodDays,
                })
              }}
            </div>
          </div>
        </li>
      </ol>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-steps {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.raffle-steps__step {
  display: grid;
  grid-template-columns: 32px 1fr;
  gap: 12px;
  align-items: start;
}

.raffle-steps__number {
  border: 1px solid var(--color-edge, rgba(122, 130, 136, 0.5));
  border-radius: var(--radius-control, 8px);
  color: var(--color-lifted, #eee);
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 13px;
  line-height: 30px;
  text-align: center;
}

.raffle-steps__title {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.raffle-steps__text {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
