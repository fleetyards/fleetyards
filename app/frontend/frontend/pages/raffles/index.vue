<script lang="ts">
export default {
  name: "RafflesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RaffleCard from "@/frontend/components/Raffles/Card/index.vue";
import { useRaffles } from "@/services/fyApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { perPage, page, updatePerPage } = usePagination();

const params = computed(() => ({ page: page.value, perPage: perPage.value }));

const { data: raffles, ...asyncStatus } = useRaffles(params);
</script>

<template>
  <Heading hero>{{ t("raffles.title") }}</Heading>
  <p class="raffles-lead">{{ t("raffles.lead") }}</p>

  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <p v-if="!raffles?.items.length" data-test="raffles-empty">
        {{ t("raffles.empty") }}
      </p>
      <div v-else class="raffles-grid">
        <RaffleCard
          v-for="raffle in raffles.items"
          :key="raffle.id"
          :raffle="raffle"
        />
      </div>
      <Paginator
        v-if="raffles"
        :query-result-ref="raffles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.raffles-lead {
  max-width: 60ch;
}

.raffles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}
</style>
