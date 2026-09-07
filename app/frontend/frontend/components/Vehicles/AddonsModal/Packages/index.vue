<script lang="ts">
export default {
  name: "AddonsModalPackages",
};
</script>

<script lang="ts" setup>
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
import { useI18n } from "@/shared/composables/useI18n";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { type ModelModulePackage } from "@/services/fyApi";

type Props = {
  packages: ModelModulePackage[];
  modelValue?: string[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  editable: false,
});

const emit = defineEmits<{
  "update:modelValue": [ids: string[]];
}>();

const { t } = useI18n();

const moduleIds = (item: ModelModulePackage) =>
  item.modules.map((mod) => mod.id);

const fingerprint = (ids: string[]) => [...ids].sort().join(",");

const applied = (item: ModelModulePackage) =>
  fingerprint(props.modelValue) === fingerprint(moduleIds(item));

/**
 * A package is a preset, so applying one *replaces* the module selection with
 * exactly what it contains. It used to add its modules on top of whatever was
 * already chosen, which could not agree with the tick beside it: that was only
 * ever drawn on an exact match, so applying a package to a ship that already
 * carried a module left a selection no package claimed.
 *
 * Duplicates are carried through rather than collapsed — the Endeavor's Olympic
 * Class is two Bio Domes.
 */
const apply = (item: ModelModulePackage) => {
  if (!props.editable) {
    return;
  }

  emit("update:modelValue", moduleIds(item));
};

// What the preset actually fits, which is the only thing separating one package
// from the next; the count matters because a package may hold a module twice.
const contents = (item: ModelModulePackage) => {
  const counts = new Map<string, number>();

  item.modules.forEach((mod) => {
    counts.set(mod.name, (counts.get(mod.name) || 0) + 1);
  });

  return [...counts.entries()]
    .map(([name, count]) => (count > 1 ? `${count} × ${name}` : name))
    .join(" · ");
};

// Read-only the list holds only the package that is applied, so the pill saying
// so would be the only row's only badge.
const badges = (item: ModelModulePackage): AddonBadge[] =>
  applied(item) && props.editable
    ? [
        {
          key: "applied",
          label: t("addon.packages.applied"),
          variant: PillVariantsEnum.SUCCESS,
        },
      ]
    : [];

const rows = computed(() =>
  props.editable ? props.packages : props.packages.filter(applied),
);
</script>

<template>
  <div class="addon-options">
    <AddonOption
      v-for="item in rows"
      :key="item.id"
      :name="item.name"
      :image="item.media.storeImage?.smallUrl"
      :contents="contents(item)"
      :badges="badges(item)"
      :selected="editable && applied(item)"
      :editable="editable"
      test-id="vehicle-addon-package"
      @toggle="apply(item)"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddonOption/list";
</style>
