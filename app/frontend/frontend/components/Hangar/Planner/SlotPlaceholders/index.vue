<script lang="ts">
export default {
  name: "HangarPlannerSlotPlaceholders",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

const emit = defineEmits<{
  add: [label: string];
}>();

const { t } = useI18n();

const roles = ["starter", "cargo", "exploration"];
</script>

<template>
  <div class="plan-placeholders" data-test="hangar-plan-placeholders">
    <p class="plan-placeholders__hint">{{ t("hangarPlanner.noSlots") }}</p>
    <ul class="plan-placeholders__list">
      <li
        v-for="role in roles"
        :key="role"
        class="plan-placeholders__slot"
        :data-test="`hangar-plan-placeholder-${role}`"
      >
        <span class="plan-placeholders__label">
          <i class="fa-light fa-circle-dashed" aria-hidden="true" />
          {{ t(`hangarPlanner.placeholderRoles.${role}`) }}
        </span>
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="hangar-plan-placeholder-add"
          @click="emit('add', t(`hangarPlanner.placeholderRoles.${role}`))"
        >
          <i class="fa-light fa-plus" />
          {{ t("hangarPlanner.useAsFirstSlot") }}
        </Btn>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.plan-placeholders {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.plan-placeholders__hint {
  margin: 0;
  color: var(--color-text-dim);
}

.plan-placeholders__list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.plan-placeholders__slot {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  border: 1px dashed var(--color-edge);
  border-radius: 12px;
}

.plan-placeholders__label {
  display: flex;
  gap: 10px;
  align-items: center;
  font-weight: 600;
  color: var(--color-text-dim);

  > i {
    font-size: 1.2rem;
    color: var(--color-muted);
  }
}
</style>
