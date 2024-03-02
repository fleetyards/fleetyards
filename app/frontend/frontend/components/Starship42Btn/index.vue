<template>
  <Btn
    v-if="items && items.length"
    v-tooltip="tooltip"
    :variant="variant"
    :size="size"
    :inline="inline"
    :block="block"
    @click="openStarship42"
  >
    <template v-if="withIcon">
      <i class="fad fa-cube" /> {{ t("labels.exportStarship42") }}
    </template>
    <span v-else>
      {{ t("labels.3dView") }}
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import type {
  BtnVariants,
  BtnSizes,
} from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Vehicle, Model, VehiclePublic } from "@/services/fyApi";
import { useMobile } from "@/shared/composables/useMobile";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouteLocationRaw } from "vue-router";

type Props = {
  items: (Vehicle | Model | VehiclePublic)[];
  withIcon?: boolean;
  block?: boolean;
  inline?: boolean;
  variant?: BtnVariants;
  size?: BtnSizes;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  exact?: boolean;
  mobileBlock?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withIcon: false,
  block: false,
  inline: false,
  variant: "default",
  size: "default",
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  exact: false,
  mobileBlock: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
});

const basePath = "https://starship42.com/fleetview/";

const { t } = useI18n();

const mobile = useMobile();

const tooltip = computed(() => {
  if (mobile.value) {
    return null;
  }

  return t("labels.poweredByStarship42");
});

const openStarship42 = () => {
  const form = document.createElement("form");
  form.method = "post";
  form.action = basePath;
  form.target = "_blank";

  const typeField = document.createElement("input");
  typeField.type = "hidden";
  typeField.name = "type";
  typeField.value = "matrix";
  form.appendChild(typeField);

  props.items.forEach((item) => {
    const model = (item as Vehicle).model || item;
    const shipField = document.createElement("input");
    shipField.type = "hidden";
    shipField.name = "s[]";
    shipField.value = model.rsiName || model.name;

    form.appendChild(shipField);
  });

  document.body.appendChild(form);

  form.submit();

  document.body.removeChild(form);
};
</script>

<script lang="ts">
export default {
  name: "Starship42Btn",
};
</script>
