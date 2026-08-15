<script lang="ts">
export default {
  name: "OwnerLabel",
};
</script>

<script lang="ts" setup>
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

<template>
  <button v-if="modelSlug" type="button" class="owner" @click="openOwnersModal">
    {{ t("labels.vehicle.owner") }}
    <i class="fa fa-bars-staggered" />
  </button>
  <a
    v-else-if="owner"
    class="owner"
    :href="`/hangar/${owner}`"
    target="_blank"
    rel="noopener"
  >
    {{ t("labels.vehicle.owner") }}
    <span class="owner__name">{{ owner }}</span>
  </a>
</template>

<style lang="scss" scoped>
/*
 * The tag is the control, rather than a div wrapping a Btn: Btn is sized for a
 * toolbar - 43px tall with a fixed 15px label - so it, not the tag, was setting
 * the height, and its hover tint painted a second, inset box inside the blue.
 * Restyling that from here meant reaching into another component with :deep.
 */
.owner {
  position: absolute;
  bottom: 10px;
  right: 0;
  display: flex;
  align-items: center;
  gap: 6px;
  // Same box as .model-panel-on-sale, the other tag pinned to this panel, so the
  // two read as one family rather than two sizes of badge.
  height: 40px;
  margin: 0;
  padding: 0 12px;
  background-color: $primary;
  border: 0;
  border-radius: 10px 0 0 10px;
  color: #fff;
  font-size: 13px;
  line-height: 1.4;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
  transition: background-color 0.15s ease-in-out;
}

.owner:hover {
  background-color: color.adjust($primary, $lightness: 8%);
  color: #fff;
}

.owner:focus-visible {
  outline: 2px solid #fff;
  outline-offset: -4px;
}

.owner__name {
  font-weight: 600;
}
</style>
