<script lang="ts">
export default {
  name: "RaffleEntrants",
};
</script>

<script lang="ts" setup>
import { useRaffleEntrants } from "@/services/fyApi";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffleId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { perPage, page, updatePerPage } = usePagination();

const params = computed(() => ({ page: page.value, perPage: perPage.value }));

const { data: entrants } = useRaffleEntrants(() => props.raffleId, params);
</script>

<template>
  <section class="raffle-entrants" data-test="raffle-entrants">
    <h2 class="raffle-entrants__title">
      {{ t("raffles.entrants.title") }}
    </h2>
    <p v-if="entrants && !entrants.items.length">
      {{ t("raffles.entrants.empty") }}
    </p>
    <ul v-else class="raffle-entrants__list">
      <li v-for="entrant in entrants?.items || []" :key="entrant.username">
        {{ entrant.username }}
      </li>
    </ul>
    <Paginator
      v-if="entrants"
      :query-result-ref="entrants"
      :per-page="perPage"
      :update-per-page="updatePerPage"
    />
  </section>
</template>

<style lang="scss" scoped>
.raffle-entrants__title {
  font-size: 1.1rem;
}

.raffle-entrants__list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  padding: 0;
  list-style: none;
}
</style>
