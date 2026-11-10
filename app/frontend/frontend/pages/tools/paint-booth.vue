<script lang="ts">
export default {
  name: "ToolsPaintBoothPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import ModelPickerSelect from "@/frontend/components/Models/PickerSelect/index.vue";
import PaintBooth from "@/frontend/components/PaintBooth/index.vue";
import { useModel } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const PICKER_QUERY = { withTexturedHolo: true };

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const queryValue = (key: string) => {
  const value = [route.query[key]].flat()[0];

  return typeof value === "string" && value ? value : undefined;
};

const shipSlug = computed(() => queryValue("ship"));

const paintSlug = computed(() => queryValue("paint"));

type BoothQuery = {
  ship?: string;
  paint?: string;
};

const navigate = (next: BoothQuery) => {
  const query: BoothQuery = {
    ship: shipSlug.value,
    paint: paintSlug.value,
    ...next,
  };

  return router.replace({ name: "paint-booth", query });
};

// Another ship's paints do not fit this one.
const pickShip = (slug?: string) => {
  void navigate({ ship: slug, paint: undefined });
};

const {
  data: model,
  isLoading,
  isError,
} = useModel(
  computed(() => shipSlug.value ?? ""),
  {
    query: { enabled: computed(() => !!shipSlug.value) },
  },
);

// The query keeps its last answer after a clear. Its slug is not compared to
// the address's: an old or differently cased one answers with the current.
const shownModel = computed(() => (shipSlug.value ? model.value : undefined));
</script>

<template>
  <div class="paint-booth-page">
    <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

    <PaintBooth
      v-if="shownModel"
      :key="shownModel.slug"
      :model="shownModel"
      :paint="paintSlug"
      @update:paint="navigate({ paint: $event })"
    >
      <template #controls>
        <ModelPickerSelect
          name="paint-booth-ship"
          :label="t('labels.selectModel')"
          :model-value="shipSlug"
          :query="PICKER_QUERY"
          no-label
          :clearable="false"
          inline
          class="paint-booth-page__picker"
          @update:model-value="pickShip"
        />
      </template>
    </PaintBooth>
    <div v-else class="paint-booth-page__empty" data-test="paint-booth-empty">
      <i class="fa-duotone fa-spray-can-sparkles" />
      <ModelPickerSelect
        name="paint-booth-ship"
        :label="t('labels.selectModel')"
        :model-value="shipSlug"
        :query="PICKER_QUERY"
        no-label
        :clearable="false"
        class="paint-booth-page__picker"
        @update:model-value="pickShip"
      />
      <p v-if="shipSlug && isLoading">{{ t("labels.loading") }}</p>
      <p v-else-if="shipSlug && isError">{{ t("paintBooth.notFound") }}</p>
      <p v-else>{{ t("paintBooth.empty") }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// A width rather than a flex-basis: the stage's bar is only as wide as what it
// holds, and that is measured from the width, so a basis the picker grows to
// afterwards pushes the button beside it onto a second row.
.paint-booth-page__picker {
  flex: 0 1 auto;
  width: 12rem;
  min-width: 0;

  @media (min-width: $desktop-breakpoint) {
    width: 18rem;
  }
}

.paint-booth-page__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  min-height: 20rem;
  padding: 1rem;
  color: $gray-lighter;
  text-align: center;

  i {
    font-size: 4rem;
    opacity: 0.4;
  }
}
</style>
