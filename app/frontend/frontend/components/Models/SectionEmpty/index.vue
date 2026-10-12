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
  <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
    <p class="model-section-empty">
      <i class="fa-light fa-circle-info" aria-hidden="true" />
      {{ t("texts.model.sectionEmpty", { model: modelName, section }) }}
    </p>
  </Panel>
</template>

<style lang="scss" scoped>
.model-section-empty {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 14px 20px;
  color: var(--color-text-dim);
}
</style>
