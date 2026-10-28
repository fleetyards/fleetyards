<script lang="ts">
export default {
  name: "RaffleEntrants",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useRaffleEntrants } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffleId: string;
  count: number;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const PREVIEW = 10;
// Every entrant is public, so "all" is a page large enough for any raffle
// rather than a paginator in a narrow column.
const ALL = 1000;

const showAll = ref(false);

const params = computed(() => ({
  page: "1",
  perPage: String(showAll.value ? ALL : PREVIEW),
}));

const { data: entrants } = useRaffleEntrants(() => props.raffleId, params);
</script>

<template>
  <Panel :variant="PanelVariantsEnum.SLIM" data-test="raffle-entrants">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("raffles.entrants.titleCount", { count: props.count }) }}
    </PanelHeading>
    <PanelBody>
      <p v-if="entrants && !entrants.items.length" class="raffle-entrants__dim">
        {{ t("raffles.entrants.empty") }}
      </p>
      <ul v-else class="raffle-entrants">
        <li
          v-for="entrant in entrants?.items || []"
          :key="entrant.username"
          class="raffle-entrants__row"
        >
          {{ entrant.username }}
          <span class="raffle-entrants__dim">
            {{ l(entrant.enteredAt, "date.formats.short") }}
          </span>
        </li>
      </ul>
      <Btn
        v-if="!showAll && props.count > PREVIEW"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        data-test="raffle-entrants-all"
        @click="showAll = true"
      >
        {{ t("raffles.entrants.showAll", { count: props.count }) }}
      </Btn>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-entrants {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.raffle-entrants__row {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  padding: 8px 0;
  border-bottom: 1px solid var(--color-edge-faint, rgba(122, 130, 136, 0.16));

  &:last-child {
    border-bottom: 0;
  }
}

.raffle-entrants__dim {
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}
</style>
