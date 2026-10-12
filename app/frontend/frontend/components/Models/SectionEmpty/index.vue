<script lang="ts">
export default {
  name: "ModelSectionEmpty",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  modelName: string;
  section: string;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <!-- A slim note rather than the boxed empty state: a ship without modules is
       a fact about the ship, not a search that came back empty. -->
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :outer-spacing="false"
    class="model-section-empty-panel"
  >
    <p class="model-section-empty">
      <i class="fa-light fa-circle-info" aria-hidden="true" />
      {{ t("texts.model.sectionEmpty", { model: modelName, section }) }}
    </p>
  </Panel>
</template>

<style lang="scss" scoped>
// As wide as its sentence and centred under the heading: a note, not a list.
.model-section-empty-panel {
  width: fit-content;
  max-width: 100%;
  margin: 0 auto;
}

.model-section-empty {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 14px 20px;
  color: var(--color-text-dim);
}
</style>
