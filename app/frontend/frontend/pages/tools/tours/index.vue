<script lang="ts">
export default {
  name: "ToursPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useTours } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

const { t, l } = useI18n();

const { data: tours } = useTours();

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { label: t("nav.tools.tours") },
]);
</script>

<template>
  <section class="container">
    <BreadCrumbs :crumbs="crumbs" />

    <Heading>
      {{ t("headlines.payouts.tours.index") }}
      <template #actions-right>
        <Btn :to="{ name: 'tour-add' }" data-test="tour-add">
          {{ t("actions.payouts.createTour") }}
        </Btn>
      </template>
    </Heading>

    <p v-if="!tours?.items?.length" class="tours-empty">
      {{ t("empty.payouts.tours") }}
    </p>

    <div class="tours-list">
      <Panel v-for="tour in tours?.items ?? []" :key="tour.id">
        <PanelBody>
          <router-link
            :to="{ name: 'tour', params: { slug: tour.slug } }"
            class="tours-list__row"
            data-test="tour-row"
          >
            <span class="tours-list__title">{{ tour.title }}</span>
            <span v-if="tour.startsAt" class="tours-list__date">
              {{ l(tour.startsAt) }}
            </span>
            <Pill>
              {{
                t(
                  `labels.payouts.${tour.status === "settled" ? "settled" : "open"}`,
                )
              }}
            </Pill>
          </router-link>
        </PanelBody>
      </Panel>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.tours-empty {
  color: var(--color-muted, #999);
}

.tours-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.tours-list__row {
  display: flex;
  align-items: center;
  gap: 12px;
  justify-content: space-between;
  flex-wrap: wrap;
}

.tours-list__title {
  flex: 1 1 auto;
  min-width: 0;
}

.tours-list__date {
  color: var(--color-muted, #999);
  font-size: 12px;
}
</style>
