<script lang="ts">
export default {
  name: "SupportPage",
};
</script>

<script lang="ts" setup>
import AllSupporters from "@/frontend/components/AllSupporters/index.vue";
import SupportContent from "@/frontend/components/SupportContent/index.vue";
import { useSupporters } from "@/services/fyApi";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data: overview } = useSupporters();

const hasSupporters = computed(
  () => !!overview.value?.supporters.length || !!overview.value?.anonymousCount,
);
</script>

<template>
  <div class="support-page">
    <Heading hero>{{ t("headlines.support") }}</Heading>

    <Panel inset>
      <SupportContent standalone class="support-page__content" />
    </Panel>

    <Panel v-if="overview && hasSupporters" inset>
      <AllSupporters
        :supporters="overview.supporters"
        :anonymous-count="overview.anonymousCount"
        class="support-page__content"
      />
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
/* A reading column rather than the full width. The panel holds two rows of
   buttons and a few lines of text, and stretched across a desktop they stand
   too far apart to read as one thing. */
.support-page {
  max-width: 960px;
  margin-inline: auto;
}

/* An inset panel pads `20px 20px 0` and leaves the bottom to its content, which
   usually ends in a block carrying its own margin. The support body ends in a
   flex row that has none, so it would sit on the panel's edge. */
.support-page__content {
  padding-bottom: 20px;
}
</style>
