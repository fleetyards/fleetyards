<script lang="ts">
export default {
  name: "AdminModelEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended } from "@/services/fyAdminApi";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = [
  {
    to: { name: "admin-models", hash: `#${props.model.id}` },
    label: t("nav.admin.models.index"),
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>{{ t("headlines.admin.models.edit") }}</Heading>
  {{ model }}
</template>
