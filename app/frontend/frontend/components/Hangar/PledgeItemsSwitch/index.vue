<script lang="ts">
export default {
  name: "HangarPledgeItemsSwitch",
};
</script>

<script lang="ts" setup>
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const route = useRoute();
</script>

<template>
  <BtnGroup segmented>
    <Btn
      :to="{ name: 'hangar-paints' }"
      :active="route.name === 'hangar-paints'"
      route-active-class=""
      mobile-icon-only
      data-test="pledge-items-switch-paints"
    >
      <i class="fa-light fa-paintbrush" />
      {{ t("nav.hangar.paints") }}
    </Btn>
    <Btn
      :to="{ name: 'hangar-flair' }"
      :active="route.name === 'hangar-flair'"
      route-active-class=""
      mobile-icon-only
      data-test="pledge-items-switch-flair"
    >
      <i class="fa-light fa-trophy-star" />
      {{ t("nav.hangar.flair") }}
    </Btn>
    <Btn
      :to="{ name: 'hangar-buybacks' }"
      :active="route.name === 'hangar-buybacks'"
      route-active-class=""
      mobile-icon-only
      data-test="pledge-items-switch-buybacks"
    >
      <i class="fa-light fa-rotate-left" />
      {{ t("nav.hangar.buybacks") }}
    </Btn>
  </BtnGroup>
</template>
