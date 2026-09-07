<script lang="ts">
export default {
  name: "ModuleItemModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { type ModelModule } from "@/services/fyApi";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Props = {
  modules: ModelModule[];
  selectedModuleSlug?: string;
  // Null is the stock slot: the caller reads it as "leave it as delivered".
  onSelect: (mod: ModelModule | null) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const { contents } = useModuleContents();

const isSelected = (mod: ModelModule) => mod.slug === props.selectedModuleSlug;

// Its fittings are the whole reason to pick one module over another here, so
// they lead; a module with none says so outright rather than falling back to
// its store paragraph, because "what is in this slot" is the question asked.
const summary = (mod: ModelModule) =>
  contents(mod) || t("addon.contentsUnknown");

/**
 * Only a status worth a warning is shown. Most modules are flight ready, and a
 * pill on every row would say nothing while crowding the figures that do.
 */
const badges = (mod: ModelModule): AddonBadge[] => {
  const list: AddonBadge[] = [];

  if (isSelected(mod)) {
    list.push({
      key: "fitted",
      label: t("addon.fitted"),
      variant: PillVariantsEnum.SUCCESS,
    });
  }

  const cargo = mod.metrics?.cargo || 0;

  if (cargo) {
    list.push({ key: "cargo", label: t("addon.cargo", { cargo }) });
  }

  if (mod.productionStatus && mod.productionStatus !== "flight-ready") {
    list.push({
      key: "status",
      label: t(`labels.model.productionStatus.${mod.productionStatus}`),
      variant: PillVariantsEnum.WARNING,
    });
  }

  return list;
};

const stockBadges = computed((): AddonBadge[] =>
  props.selectedModuleSlug
    ? []
    : [
        {
          key: "fitted",
          label: t("addon.fitted"),
          variant: PillVariantsEnum.SUCCESS,
        },
      ],
);

const selectModule = (mod: ModelModule) => {
  props.onSelect(mod);
  comlink.emit("close-modal");
};

const clearModule = () => {
  props.onSelect(null);
  comlink.emit("close-modal");
};
</script>

<template>
  <Modal :title="t('labels.hardpoint.selectModule')">
    <div class="addon-options">
      <AddonOption
        :name="t('labels.hardpoint.moduleStock')"
        :contents="t('labels.hardpoint.moduleStockHint')"
        icon="fa-duotone fa-layer-minus"
        :badges="stockBadges"
        :selected="!selectedModuleSlug"
        test-id="module-option-stock"
        @toggle="clearModule"
      />

      <AddonOption
        v-for="mod in modules"
        :key="mod.id"
        :name="mod.name"
        :image="mod.media.storeImage?.smallUrl"
        :contents="summary(mod)"
        :badges="badges(mod)"
        :selected="isSelected(mod)"
        test-id="module-option"
        @toggle="selectModule(mod)"
      />
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddonOption/list";
</style>
