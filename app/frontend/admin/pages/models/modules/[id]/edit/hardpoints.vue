<script lang="ts">
export default {
  name: "AdminModelModuleEditHardpointsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import { type ModelModule, type Hardpoint } from "@/services/fyAdminApi";
import BasePill from "@/shared/components/base/Pill/index.vue";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();

const hardpoints = computed(() => props.modelModule.hardpoints ?? []);
</script>

<template>
  <Heading hero>{{ t("headlines.admin.modelModules.hardpoints") }}</Heading>

  <InlineEditableList
    empty-name="Hardpoints"
    :items="hardpoints as Hardpoint[]"
    hide-edit
    hide-destroy
  >
    <template #display="{ item }">
      <div class="hardpoint-display">
        <div class="hardpoint-display__main">
          <BasePill v-if="item.group" uppercase margin-right>{{
            item.group
          }}</BasePill>
          <BasePill v-if="item.category" margin-right>{{
            item.category
          }}</BasePill>
          <BasePill v-if="item.maxSize" margin-right
            >S{{ item.maxSize }}</BasePill
          >
          <span v-if="item.name" class="hardpoint-display__name">{{
            item.name
          }}</span>
        </div>
        <div v-if="item.component" class="hardpoint-display__meta">
          <span class="text-muted">
            {{ item.component.name }}
            <template v-if="item.component.size">
              &middot; S{{ item.component.size }}
            </template>
          </span>
        </div>
      </div>
    </template>
  </InlineEditableList>
</template>

<style lang="scss" scoped>
.hardpoint-display {
  display: flex;
  flex-direction: column;
  gap: 4px;

  &__main {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 4px;
  }

  &__meta {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 4px;
  }

  &__name {
    font-weight: 500;
  }
}
</style>
