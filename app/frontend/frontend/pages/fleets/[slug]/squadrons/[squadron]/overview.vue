<script lang="ts">
export default {
  name: "FleetSquadronOverviewPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FleetSquadron } from "@/services/fyApi";

type Props = {
  squadron: FleetSquadron;
};

const props = defineProps<Props>();
const { t } = useI18n();
</script>

<template>
  <Panel fill-height>
    <PanelBody
      class="squadron-description-body"
      :class="{
        'squadron-description-body--empty': !props.squadron.description,
      }"
    >
      <p v-if="props.squadron.description" class="squadron-description">
        {{ props.squadron.description }}
      </p>
      <p v-else class="squadron-description-placeholder">
        {{ t("labels.fleet.squadrons.noDescription") }}
      </p>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.squadron-description-body {
  padding: 18px;
}

.squadron-description {
  margin: 0;
  white-space: pre-line;
}

.squadron-description-placeholder {
  margin: 0;
  color: var(--color-text-muted, #8a8f95);
  font-style: italic;
}

.squadron-description-body--empty {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 180px;
  text-align: center;
}
</style>
