<script lang="ts">
export default {
  name: "RaffleCard",
};
</script>

<script lang="ts" setup>
import { type Raffle } from "@/services/fyApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const image = computed(() => props.raffle.prize?.storeImage?.mediumUrl);
</script>

<template>
  <router-link
    :to="{ name: 'raffle', params: { id: props.raffle.id } }"
    class="raffle-card"
    :data-test="`raffle-${props.raffle.id}`"
  >
    <Panel :bg-image="image" fill-height>
      <div class="raffle-card__body">
        <span class="raffle-card__status">
          {{ t(`raffles.statuses.${props.raffle.status}`) }}
        </span>
        <h2 class="raffle-card__title">{{ props.raffle.title }}</h2>
        <p v-if="props.raffle.prize" class="raffle-card__prize">
          {{ props.raffle.prize.name }}
        </p>
        <p class="raffle-card__meta">
          {{
            t("raffles.endsAt", {
              date: l(props.raffle.endsAt, "datetime.formats.short"),
            })
          }}
          ·
          {{ t("raffles.entriesCount", { count: props.raffle.entriesCount }) }}
        </p>
        <p v-if="props.raffle.entered" class="raffle-card__entered">
          <i class="fa-duotone fa-ticket" />
          {{ t("raffles.entered") }}
        </p>
      </div>
    </Panel>
  </router-link>
</template>

<style lang="scss" scoped>
.raffle-card {
  display: block;
  height: 100%;
  color: inherit;
  text-decoration: none;
}

.raffle-card__body {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-height: 180px;
  justify-content: flex-end;
}

.raffle-card__status {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  opacity: 0.8;
}

.raffle-card__title {
  margin: 0;
  font-size: 1.25rem;
}

.raffle-card__prize,
.raffle-card__meta,
.raffle-card__entered {
  margin: 0;
}
</style>
