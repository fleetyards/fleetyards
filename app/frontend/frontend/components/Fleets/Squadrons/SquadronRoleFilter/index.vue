<script lang="ts">
export default {
  name: "SquadronRoleFilter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FilterOption,
  type FleetSquadron,
  useModelClassificationsFilters,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const { data: classificationFilters } = useModelClassificationsFilters();

const classificationLabels = computed(() => {
  const options =
    (classificationFilters.value as FilterOption[] | undefined) ?? [];

  return props.squadron.classifications.map(
    (key) => options.find((option) => option.value === key)?.label ?? key,
  );
});

const labels = computed(() => [
  ...classificationLabels.value,
  ...props.squadron.fociLabels,
]);

const editable = computed(
  () => !!props.squadron.capabilities?.manageRoleFilter,
);

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronRoleFilterModal/index.vue"),
    props: { fleetSlug: props.fleetSlug, squadron: props.squadron },
  });
};
</script>

<template>
  <div class="squadron-role-filter" data-test="squadron-role-filter">
    <span class="squadron-role-filter__label">
      {{ t("labels.fleet.squadrons.roleFilter") }}
    </span>
    <span class="squadron-role-filter__values">
      <template v-if="labels.length">
        <Pill v-for="label in labels" :key="label">{{ label }}</Pill>
      </template>
      <span v-else class="squadron-role-filter__none">
        {{ t("labels.fleet.squadrons.roleFilterNone") }}
      </span>
    </span>
    <Btn
      v-if="editable"
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.GHOST"
      data-test="squadron-role-filter-edit"
      @click="openModal"
    >
      {{ t("actions.edit") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.squadron-role-filter {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 12px;
  padding: 12px 18px;
  border-bottom: 1px solid var(--color-edge-faint);
}

.squadron-role-filter__label {
  color: var(--color-text-dim);
  font-size: 0.875rem;
}

.squadron-role-filter__values {
  display: flex;
  flex: 1;
  flex-wrap: wrap;
  gap: 6px;
}

.squadron-role-filter__none {
  font-size: 0.875rem;
}
</style>
