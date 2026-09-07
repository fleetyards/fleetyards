<script lang="ts">
export default {
  name: "VehicleAddonsModalAddons",
};
</script>

<script lang="ts" setup>
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { type ModelModule, type ModelUpgrade } from "@/services/fyApi";

type Addon = ModelModule | ModelUpgrade;

type Props = {
  addons: Addon[];
  modelValue?: string[];
  editable?: boolean;
  emptyLabel: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  editable: false,
});

const emit = defineEmits<{
  "update:modelValue": [ids: string[]];
}>();

const { t } = useI18n();

const { contents } = useModuleContents();

// Only a module carries a slug, and with it the hardpoints, cargo figure and
// production status that an upgrade kit has nothing to say about.
const isModule = (addon: Addon): addon is ModelModule => "slug" in addon;

/**
 * The list is a bag rather than a set: 3,754 hangar entries hold the same module
 * more than once, and a package like the Endeavor's Olympic Class is two Bio
 * Domes. So a row's state is a count, not a checkbox.
 */
const countFor = (id: string) =>
  props.modelValue.filter((item) => item === id).length;

/**
 * Emits a whole new array rather than mutating one in place. The list this
 * replaced pushed and spliced a local copy behind a `watch(() => ref.value)`,
 * which Vue 3 never fires for an in-place mutation — so every click showed a
 * tick and saved nothing.
 */
const setCount = (id: string, count: number) => {
  const others = props.modelValue.filter((item) => item !== id);

  emit("update:modelValue", [
    ...others,
    ...Array.from({ length: Math.max(0, count) }, () => id),
  ]);
};

const toggle = (id: string) => setCount(id, countFor(id) ? 0 : 1);

// Read-only, this is a report of what the ship has; offering the rest of the
// catalogue to a reader who cannot pick any of it only buries the answer.
const rows = computed(() =>
  props.editable
    ? props.addons
    : props.addons.filter((addon) => countFor(addon.id) > 0),
);

/**
 * The module's own description leads here, where the hardpoint summary leads in
 * the slot picker: this list is about recording what a ship carries rather than
 * comparing what two modules would fit, and most modules in the catalogue have
 * no hardpoints to summarise at all.
 */
const summary = (addon: Addon) => {
  if (addon.description) {
    return addon.description;
  }

  return isModule(addon) ? contents(addon) : undefined;
};

/*
 * Read-only, every row on screen is one the ship carries, so a "fitted" pill on
 * each of them says nothing — the same reason a production-status pill is only
 * drawn where it is a warning. What is worth saying there is how many copies,
 * which editing reads off the stepper instead.
 */
const badges = (addon: Addon): AddonBadge[] => {
  const list: AddonBadge[] = [];
  const count = countFor(addon.id);

  if (count && props.editable) {
    list.push({
      key: "fitted",
      label: t("addon.fitted"),
      variant: PillVariantsEnum.SUCCESS,
    });
  }

  if (count > 1 && !props.editable) {
    list.push({ key: "copies", label: t("addon.copies", { count }) });
  }

  if (!isModule(addon)) {
    return list;
  }

  const cargo = addon.metrics?.cargo || 0;

  if (cargo) {
    list.push({ key: "cargo", label: t("addon.cargo", { cargo }) });
  }

  if (addon.productionStatus && addon.productionStatus !== "flight-ready") {
    list.push({
      key: "status",
      label: t(`labels.model.productionStatus.${addon.productionStatus}`),
      variant: PillVariantsEnum.WARNING,
    });
  }

  return list;
};
</script>

<template>
  <div class="addon-options">
    <AddonOption
      v-for="addon in rows"
      :key="addon.id"
      :name="addon.name"
      :image="addon.media?.storeImage?.smallUrl"
      :contents="summary(addon)"
      :badges="badges(addon)"
      :selected="editable && countFor(addon.id) > 0"
      :count="countFor(addon.id)"
      :editable="editable"
      quantities
      test-id="vehicle-addon"
      @toggle="toggle(addon.id)"
      @increase="setCount(addon.id, countFor(addon.id) + 1)"
      @decrease="setCount(addon.id, countFor(addon.id) - 1)"
    />

    <p v-if="!rows.length" class="addon-options__empty">
      {{ emptyLabel }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddonOption/list";
@import "index";
</style>
