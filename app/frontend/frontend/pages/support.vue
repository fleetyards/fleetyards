<script lang="ts">
export default {
  name: "SupportPage",
};
</script>

<script lang="ts" setup>
import SupportContent from "@/frontend/components/SupportContent/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <div class="row lg:justify-center">
    <div class="col-12 col-lg-8">
      <Heading hero>{{ t("headlines.support") }}</Heading>

      <Panel inset>
        <SupportContent class="support-page__content" />
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
/* An inset panel pads `20px 20px 0` and leaves the bottom to its content, which
   usually ends in a block carrying its own margin. The support body ends in a
   flex row that has none, so it would sit on the panel's edge. */
.support-page__content {
  padding-bottom: 20px;
}
</style>
