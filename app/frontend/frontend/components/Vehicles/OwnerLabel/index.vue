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
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  owner?: string;
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

<script lang="ts">
export default {
  name: "OwnerLabel",
};
</script>
