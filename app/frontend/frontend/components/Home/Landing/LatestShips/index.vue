<script lang="ts">
export default {
  name: "HomeLandingLatestShips",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useModelsLatest } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data, isLoading } = useModelsLatest();

// Two full rows of four.
const models = computed(() => (data.value || []).slice(0, 8));
</script>

<template>
  <section data-test="home-landing-latest-ships">
    <div class="home-landing-latest-ships__head">
      <Heading :level="HeadingLevelEnum.H2">
        {{ t("home.landing.latestShips.title") }}
      </Heading>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :to="{ name: 'ships' }"
      >
        {{ t("home.landing.latestShips.all") }}
        <i class="fa-light fa-chevron-right" />
      </Btn>
    </div>
    <div class="home-landing-latest-ships__slot relative">
      <Transition name="fade-quick" appear>
        <div v-if="models.length" class="home-landing-latest-ships">
          <ModelPanel
            v-for="model in models"
            :key="model.id"
            :model="model"
            :level="HeadingLevelEnum.H3"
          />
        </div>
      </Transition>
      <Loader :loading="isLoading" />
    </div>
  </section>
</template>

<style lang="scss" scoped>
.home-landing-latest-ships__head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 12px;
}

// Holds the loader's room until the ships fade in.
.home-landing-latest-ships__slot {
  min-height: 200px;
}

.home-landing-latest-ships {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1499px) {
  .home-landing-latest-ships {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 575px) {
  .home-landing-latest-ships {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
