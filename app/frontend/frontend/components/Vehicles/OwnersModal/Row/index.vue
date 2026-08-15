<script lang="ts">
export default {
  name: "VehicleOwnersModalRow",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Owner } from "@/frontend/components/Vehicles/OwnersModal/types";

type Props = {
  owner: Owner;
  as?: "button" | "div";
};

withDefaults(defineProps<Props>(), {
  as: "div",
});

const { t } = useI18n();
</script>

<template>
  <component
    :is="as"
    :type="as === 'button' ? 'button' : undefined"
    class="owner"
    :class="{ 'owner--anonymous': !owner.member }"
  >
    <Avatar :avatar="owner.avatar" size="small" />
    <span class="owner__body">
      <span class="owner__name">
        {{ owner.member?.username || t("labels.anonymous") }}
        <span v-if="owner.count > 1" class="owner__count">
          {{ owner.count }}&times;
        </span>
      </span>
      <span
        v-if="owner.ships.length"
        :title="owner.ships.join(', ')"
        class="owner__ships"
      >
        {{ owner.ships.join(", ") }}
      </span>
    </span>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
