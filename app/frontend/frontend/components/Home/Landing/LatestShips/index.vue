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
import { useMediaQuery, useResizeObserver, useWindowSize } from "@vueuse/core";
import { useModelsLatest } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // The most rows to show. Fewer when the screen is too short for them: full
  // rows only, so the section ends on a straight edge, and never more than fit
  // above the arrow to the next section.
  rows?: number;
};

const props = withDefaults(defineProps<Props>(), {
  rows: 2,
});

const { t } = useI18n();

const { data, isLoading } = useModelsLatest();

// The columns the grid below lays out at each width.
const wide = useMediaQuery("(min-width: 1200px)");
const narrow = useMediaQuery("(max-width: 575px)");

const columns = computed(() => {
  if (wide.value) return 4;
  if (narrow.value) return 1;

  return 2;
});

// Above and below the content of a landing section.
const SECTION_PADDING = 192;

const root = useTemplateRef<HTMLElement>("root");
const grid = useTemplateRef<HTMLElement>("grid");

const { height: windowHeight } = useWindowSize();

const fittingRows = ref(props.rows);

// Everything in the section but this grid stays as it is, so the rows that fit
// are the window less the padding and the rest of the content, card by card.
const fit = async () => {
  await nextTick();

  // A single column never fits a phone's screen, so it shows every row.
  if (columns.value === 1) {
    fittingRows.value = props.rows;
    return;
  }

  const content = root.value?.closest(".landing-section__content");
  if (!(content instanceof HTMLElement) || !grid.value) return;

  // The tallest card: a name that wraps makes its whole row taller.
  const cardHeight = Math.max(
    0,
    ...Array.from(grid.value.children).map(
      (card) => (card as HTMLElement).offsetHeight,
    ),
  );
  if (!cardHeight) return;

  const rest = content.offsetHeight - grid.value.offsetHeight;
  const available = windowHeight.value - SECTION_PADDING - rest;
  const gap = parseFloat(getComputedStyle(grid.value).rowGap) || 0;
  const fits = Math.floor((available + gap) / (cardHeight + gap));

  fittingRows.value = Math.max(1, Math.min(props.rows, fits));

  // Margins that collapse past the content box escape the estimate, so the
  // section itself has the last word.
  await nextTick();
  const section = content.closest(".landing-section");
  if (
    section instanceof HTMLElement &&
    section.offsetHeight > windowHeight.value &&
    fittingRows.value > 1
  ) {
    fittingRows.value -= 1;
  }
};

watch([windowHeight, columns, () => props.rows, data], fit);

// Fonts and wrapping names settle after the first measure.
useResizeObserver(grid, () => {
  void fit();
});

onMounted(fit);

const models = computed(() =>
  (data.value || []).slice(0, fittingRows.value * columns.value),
);
</script>

<template>
  <section ref="root" data-test="home-landing-latest-ships">
    <div class="home-landing-latest-ships__head">
      <Heading :level="HeadingLevelEnum.H2" hero>
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
        <div v-if="models.length" ref="grid" class="home-landing-latest-ships">
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

@media (max-width: 1199px) {
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
