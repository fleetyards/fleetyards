<script lang="ts">
export default {
  name: "SubscriptionRequired",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Box from "@/shared/components/Box/index.vue";
import Text from "@/shared/components/base/Text/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

const router = useRouter();

// `support` is a route of the frontend app alone, and this block is shared:
// AsyncData and FilteredList render it and 46 admin surfaces use those. A
// named route the running app does not have throws while rendering, so the
// refusal would become a blank page. Where the name is missing the link falls
// back to a plain navigation -- which is what admin needs regardless, being a
// separate bundle the router cannot reach.
const supportRoute = computed(() =>
  router.hasRoute("support") ? { name: "support" } : undefined,
);

const supportHref = computed(() =>
  supportRoute.value ? undefined : "/support/",
);
</script>

<template>
  <!-- Deliberately not the ERROR tone that `Forbidden` carries. Nothing has
       gone wrong here and the reader has done nothing wrong: the fleet simply
       has no active subscription. Painting it red reads as a fault to fix. -->
  <Box
    :tone="PanelTonesEnum.HIGHLIGHT"
    :heading-size="HeadingSizeEnum.HERO"
    animated
    large
  >
    <template #heading>
      {{ t("headlines.subscriptionRequired") }}
    </template>
    <template #default>
      <Text>{{ t("texts.subscriptionRequired") }}</Text>
    </template>
    <template #footer>
      <!-- The first of these blocks to carry two buttons, so it brings its own
           row: the footer slot is unstyled because a single button never
           needed it. -->
      <div class="subscription-required__actions">
        <Btn :to="{ name: 'home' }" :variant="BtnVariantsEnum.GHOST">
          <i class="fa fa-chevron-left" />
          {{ t("actions.backToHome").toUpperCase() }}
        </Btn>
        <Btn :to="supportRoute" :href="supportHref">
          {{ t("actions.supportUs").toUpperCase() }}
        </Btn>
      </div>
    </template>
  </Box>
</template>

<style lang="scss" scoped>
.subscription-required__actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}
</style>
