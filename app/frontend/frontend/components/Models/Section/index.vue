<script lang="ts">
export default {
  name: "ModelSection",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useModelsStore } from "@/frontend/stores/models";

type Props = {
  anchor: string;
  // Whose section it is: a reader may close the modules of one ship and want
  // them open on the next.
  modelSlug: string;
  title: string;
};

const props = defineProps<Props>();

const route = useRoute();
const modelsStore = useModelsStore();

const expanded = computed(
  () => !modelsStore.sectionCollapsed(props.modelSlug, props.anchor),
);

// A link to the section opens it: landing on a closed one would look like the
// link went nowhere.
watch(
  () => route.hash,
  (hash) => {
    if (hash === `#${props.anchor}`) {
      modelsStore.expandSection(props.modelSlug, props.anchor);
    }
  },
  { immediate: true },
);

const bodyId = computed(() => `${props.anchor}-section-body`);
</script>

<template>
  <hr />
  <section :id="anchor" class="row model-section">
    <div class="col-12">
      <Heading :level="HeadingLevelEnum.H2" hero>
        <button
          type="button"
          class="model-section__toggle"
          :aria-expanded="expanded"
          :aria-controls="bodyId"
          :data-test="`model-section-toggle-${anchor}`"
          @click="modelsStore.toggleSection(modelSlug, anchor)"
        >
          {{ title }}
          <i
            class="fa-light fa-chevron-down model-section__chevron"
            :class="{ 'model-section__chevron--collapsed': !expanded }"
            aria-hidden="true"
          />
        </button>
      </Heading>
      <Collapsed :id="bodyId" :visible="expanded">
        <slot />
      </Collapsed>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.model-section {
  &__toggle {
    display: inline-flex;
    align-items: center;
    gap: 14px;
    padding: 0;
    border: 0;
    background: none;
    color: inherit;
    font: inherit;
    letter-spacing: inherit;
    text-align: left;
    cursor: pointer;

    &:hover .model-section__chevron,
    &:focus-visible .model-section__chevron {
      opacity: 1;
    }
  }

  &__chevron {
    font-size: 0.55em;
    opacity: 0.6;
    transition:
      transform 0.2s ease,
      opacity 0.2s ease;

    &--collapsed {
      transform: rotate(-90deg);
    }
  }
}
</style>
