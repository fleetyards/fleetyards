<script lang="ts">
export default {
  name: "HangarPledgeItemsSwitch",
};
</script>

<script lang="ts" setup>
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";

const { t } = useI18n();

const route = useRoute();

const mobile = useMobile();

const sections = [
  {
    key: "paints",
    route: "hangar-paints",
    icon: "fa-light fa-paintbrush",
    label: "nav.hangar.paints",
  },
  {
    key: "flair",
    route: "hangar-flair",
    icon: "fa-light fa-trophy-star",
    label: "nav.hangar.flair",
  },
  {
    key: "equipment",
    route: "hangar-equipment",
    icon: "fa-light fa-shirt",
    label: "nav.hangar.equipment",
  },
  {
    key: "upgrades",
    route: "hangar-upgrades",
    icon: "fa-light fa-arrow-up",
    label: "nav.hangar.upgrades",
  },
  {
    key: "buybacks",
    route: "hangar-buybacks",
    icon: "fa-light fa-rotate-left",
    label: "nav.hangar.buybacks",
  },
];

const current = computed(() =>
  sections.find((section) => section.route === route.name),
);
</script>

<template>
  <!-- One button on a phone: the segments took the toolbar's row from the
       paginator. The list's icon alone, as on the segments, because the page
       title right above already names it. -->
  <BtnDropdown v-if="mobile" data-test="pledge-items-switch-menu">
    <template #label>
      <i v-if="current" :class="current.icon" />
      <span v-if="current" class="sr-only">{{ t(current.label) }}</span>
      <i class="fa-light fa-chevron-down" />
    </template>
    <Btn
      v-for="section in sections"
      :key="section.key"
      :to="{ name: section.route }"
      :active="route.name === section.route"
      route-active-class=""
      :data-test="`pledge-items-switch-${section.key}`"
    >
      <i :class="section.icon" />
      <span>{{ t(section.label) }}</span>
    </Btn>
  </BtnDropdown>
  <BtnGroup v-else segmented>
    <Btn
      v-for="section in sections"
      :key="section.key"
      :to="{ name: section.route }"
      :active="route.name === section.route"
      route-active-class=""
      mobile-icon-only
      :data-test="`pledge-items-switch-${section.key}`"
    >
      <i :class="section.icon" />
      {{ t(section.label) }}
    </Btn>
  </BtnGroup>
</template>
