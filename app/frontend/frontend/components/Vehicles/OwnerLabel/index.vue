<script lang="ts">
export default {
  name: "OwnerLabel",
};
</script>

<script lang="ts" setup>
import PanelTag from "@/frontend/components/base/PanelTag/index.vue";
import PanelUserTag from "@/frontend/components/base/PanelUserTag/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  owner?: MemberContact;
  modelSlug?: string;
};

const props = withDefaults(defineProps<Props>(), {
  owner: undefined,
  modelSlug: undefined,
});

const comlink = useComlink();

const openOwnersModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/OwnersModal/index.vue"),
    props: {
      fleetSlug: props.fleetSlug,
      modelSlug: props.modelSlug,
    },
  });
};
</script>

<template>
  <PanelTag v-if="modelSlug" @click="openOwnersModal">
    {{ t("labels.vehicle.owner") }}
    <i class="fa fa-bars-staggered" />
  </PanelTag>
  <PanelUserTag
    v-else-if="owner"
    :label="t('labels.vehicle.owner')"
    :member="owner"
  />
</template>
