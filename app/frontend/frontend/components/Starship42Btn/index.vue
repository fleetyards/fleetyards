<template>
  <Btn
    v-if="items && items.length"
    v-tooltip="tooltip"
    :variant="variant"
    :size="size"
    :inline="inline"
    :block="block"
    @click.native="openStarship42"
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
import Btn from "@/frontend/core/components/Btn/index.vue";
import type {
  Props as BtnProps,
  BtnVariants,
  BtnSizes,
} from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";

interface Props extends BtnProps {
  items: Vehicle[] | Model[];
  withIcon?: boolean;
  block?: boolean;
  inline?: boolean;
  variant?: BtnVariants;
  size?: BtnSizes;
}

const props = withDefaults(defineProps<Props>(), {
  withIcon: false,
  block: false,
  inline: false,
  variant: "default",
  size: "default",
});

const mobile = computed(() => Store.getters["app/mobile"]);

const basePath = "https://starship42.com/fleetview/";

const { t } = useI18n();

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
    shipField.value = model.rsiName;

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
