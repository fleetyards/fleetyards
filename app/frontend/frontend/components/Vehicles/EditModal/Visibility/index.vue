<script lang="ts">
export default {
  name: "VehicleEditModalVisibility",
};
</script>

<script lang="ts" setup>
import { useFormValues } from "vee-validate";
import type { VehicleEditValues } from "../types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  wishlist?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();
const values = useFormValues<VehicleEditValues>();

type Setting = {
  name: "public" | "nameVisible" | "saleNotify" | "logEntriesPublicByDefault";
  label: string;
};

// Sale alerts only ever go out for a ship on the wishlist, and a wishlist ship
// is never in the public hangar and keeps no log, so each ship is offered the
// switches that do something for it.
const settings = computed<Setting[]>(() =>
  props.wishlist
    ? [{ name: "saleNotify", label: t("labels.vehicle.saleNotify") }]
    : [
        { name: "public", label: t("labels.vehicleOverview.showPublic") },
        { name: "nameVisible", label: t("labels.vehicleOverview.showName") },
        {
          name: "logEntriesPublicByDefault",
          label: t("labels.vehicleLog.publicByDefault"),
        },
      ],
);
</script>

<template>
  <div>
    <FormToggle
      v-for="setting in settings"
      :key="setting.name"
      :name="setting.name"
      :model-value="values[setting.name]"
      :label="setting.label"
    />
  </div>
</template>
