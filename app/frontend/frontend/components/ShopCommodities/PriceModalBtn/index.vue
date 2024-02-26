<template>
  <Btn @click="openPriceModal">
    {{ t("actions.openPriceModal") }}
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();
const { displayWarning } = useNoty(t);

type Props = {
  stationSlug?: string;
  shopId?: string;
  shopTypes?: string[];
  commodityItemType?: string;
  withoutRental?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  stationSlug: undefined,
  shopId: undefined,
  shopTypes: undefined,
  commodityItemType: undefined,
  withoutRental: false,
});

const pathOptions: FilterGroupItem[] = [
  {
    value: "sell",
    name: t("labels.shop.sellPrice"),
  },
  {
    value: "buy",
    name: t("labels.shop.buyPrice"),
  },
  {
    value: "rental",
    name: t("labels.shop.rentalPrice"),
  },
];

const sessionStore = useSessionStore();

const comlink = useComlink();

const openPriceModal = () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({
      text: t("messages.error.commodityPrice.accountRequired"),
    });
    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/ShopCommodities/PriceModal/index.vue"),
    props: {
      stationSlug: props.stationSlug,
      shopId: props.shopId,
      commodityItemType: props.commodityItemType,
      shopTypes: props.shopTypes,
      pathOptions: pathOptions.filter(
        (item) => item.value !== "rental" || props.withoutRental,
      ),
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "PriceModalBtn",
};
</script>
