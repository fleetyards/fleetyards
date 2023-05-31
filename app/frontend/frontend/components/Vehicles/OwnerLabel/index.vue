<template>
  <div class="owner">
    <template v-if="modelSlug">
      <Btn
        variant="link"
        :text-inline="true"
        class="owner-more-action"
        @click="openOwnersModal"
      >
        {{ t("labels.vehicle.owner") }} <i class="fa fa-bars-staggered" />
      </Btn>
    </template>
    <template v-else-if="owner">
      {{ t("labels.vehicle.owner") }}
      <Btn :href="`/hangar/${owner}`" variant="link" :text-inline="true">
        {{ owner }}
      </Btn>
    </template>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  owner?: string;
  modelSlug?: string;
};

const props = defineProps<Props>();

const comlink = useComlink();

const openOwnersModal = () => {
  comlink.$emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/OwnersModal/index.vue"),
    props: {
      fleetSlug: props.fleetSlug,
      modelSlug: props.modelSlug,
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "VehiclesOwnerLabel",
};
</script>
