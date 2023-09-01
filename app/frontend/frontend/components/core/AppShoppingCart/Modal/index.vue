<template>
  <Modal :title="t('headlines.shoppingCart')">
    <div class="shopping-cart">
      <div v-if="cartItems.length" class="item-list">
        <div class="item-list-item item-list-header">
          <div class="item-name"></div>

          <div class="item-amount"></div>

          <div class="item-sold-at">
            {{ t("labels.shoppingCart.perItem") }}
          </div>

          <div class="item-price">
            {{ t("labels.shoppingCart.itemTotal") }}
          </div>

          <div class="item-actions"></div>
        </div>
        <div
          v-for="cartItem in sortedItems"
          :key="cartItem.id"
          class="item-list-item"
        >
          <div class="item-name">{{ cartItem.name }}</div>

          <ItemAmount v-if="!mobile" :cart-item="cartItem" />

          <div class="item-sold-at">
            <ul class="list-unstyled">
              <li
                v-for="soldAt in cartItem.soldAt"
                :key="`${cartItem.id}-${soldAt.id}`"
              >
                <div>
                  {{ soldAt.stationName }}
                  <span class="text-muted">{{ soldAt.shopName }}</span>
                </div>
                <span class="price-label" v-html="toUEC(soldAt.price)" />
              </li>
            </ul>
            <ul class="list-unstyled">
              <li
                v-for="listedAt in cartItem.listedAt"
                :key="`${cartItem.id}-${listedAt.id}`"
              >
                <div>
                  {{ listedAt.stationName }}
                  <span class="text-muted">{{ listedAt.shopName }}</span>
                </div>
                <span class="price-label">-</span>
              </li>
            </ul>
          </div>

          <div
            v-if="cartItem.soldAt.length"
            class="item-price price-label"
            v-html="toUEC(sum(cartItem))"
          />

          <div v-else class="item-price unavailable">
            {{ t("labels.unavailable") }}
          </div>

          <div class="item-actions">
            <ItemAmount v-if="mobile" :cart-item="cartItem" />
            <Btn
              :inline="true"
              size="small"
              variant="link"
              @click="shoppingCartStore.remove(cartItem.id)"
            >
              <i class="fal fa-trash" />
            </Btn>
          </div>
        </div>
        <div key="total" class="item-list-item item-list-total">
          <div class="text-muted">{{ t("labels.shoppingCart.total") }}</div>
          <div class="price-label" v-html="toUEC(total)" />
        </div>
      </div>
      <div v-else class="item-list-empty">
        {{ t("labels.blank.shoppingCart") }}
      </div>
    </div>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :inline="true"
          :disabled="!cartItems.length || loading"
          :loading="loading"
          :aria-label="t('actions.shoppingCart.refresh')"
          @click="refresh"
        >
          <i class="fad fa-sync" />
        </Btn>
        <Btn
          :inline="true"
          :disabled="!cartItems.length"
          :aria-label="t('actions.shoppingCart.clear')"
          @click="shoppingCartStore.clear"
        >
          <i class="fad fa-trash" />
        </Btn>
        <Btn
          :inline="true"
          :aria-label="t('actions.close')"
          @click="closeModal"
        >
          {{ t("actions.close") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { sum as sumArray, sortBy } from "@/shared/utils/Array";
import ItemAmount from "@/frontend/components/core/AppShoppingCart/ItemAmount/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useShoppingCartStore } from "@/frontend/stores/shoppingCart";
import type {
  ShoppingCartItem,
  ShoppingCartItemType,
} from "@/frontend/stores/shoppingCart";
import { storeToRefs } from "pinia";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { SearchResultTypeEnum } from "@/services/fyAdminApi";

const { t, toUEC } = useI18n();

const mobile = useMobile();

const shoppingCartStore = useShoppingCartStore();

const { items: cartItems } = storeToRefs(shoppingCartStore);

const loading = ref(false);

const sortedItems = computed(() => {
  return sortBy(cartItems.value, "name");
});

const total = computed(() => {
  return sumArray(
    cartItems.value.map((item) => sum(item)).filter((item) => item),
  );
});

const sum = (cartItem: ShoppingCartItem) => {
  return parseFloat(
    String((cartItem.bestSoldAt?.price || 0) * cartItem.amount),
  );
};

const comlink = useComlink();

const closeModal = () => {
  comlink.emit("close-modal");
};

const {
  components: componentsService,
  commodities: commoditiesService,
  equipment: equipmentService,
  models: modelsService,
  // modelPaints: modelPaintsService,
  // modelModules: modelModulesService,
} = useApiClient();

const refreshComponents = async () => {
  try {
    const response = await componentsService.components({
      q: {
        idIn: cartItems.value
          .filter((item) => item.type === SearchResultTypeEnum.COMPONENT)
          .map((item) => item.id),
      },
    });

    response.forEach((item: ShoppingCartItemType) =>
      shoppingCartStore.update(item, SearchResultTypeEnum.COMPONENT),
    );
  } catch (error) {
    console.error(error);
  }
};

const refreshCommodity = async () => {
  try {
    const response = await commoditiesService.commodities({
      q: {
        idIn: cartItems.value
          .filter((item) => item.type === SearchResultTypeEnum.COMMODITY)
          .map((item) => item.id),
      },
    });

    response.forEach((item: ShoppingCartItemType) =>
      shoppingCartStore.update(item, SearchResultTypeEnum.COMMODITY),
    );
  } catch (error) {
    console.error(error);
  }
};

const refreshEquipment = async () => {
  try {
    const response = await equipmentService.equipment({
      q: {
        idIn: cartItems.value
          .filter((item) => item.type === SearchResultTypeEnum.EQUIPMENT)
          .map((item) => item.id),
      },
    });

    response.forEach((item: ShoppingCartItemType) =>
      shoppingCartStore.update(item, SearchResultTypeEnum.EQUIPMENT),
    );
  } catch (error) {
    console.error(error);
  }
};

const refreshModels = async () => {
  try {
    const response = await modelsService.models({
      q: {
        idIn: cartItems.value
          .filter((item) => item.type === SearchResultTypeEnum.MODEL)
          .map((item) => item.id),
      },
    });

    response.items.forEach((item: ShoppingCartItemType) =>
      shoppingCartStore.update(item, SearchResultTypeEnum.MODEL),
    );
  } catch (error) {
    console.error(error);
  }
};

// const refreshModelPaints = async () => {
//   try {
//     const response = await modelPaintsService.paints({
//       q: {
//         idIn: cartItems.value
//           .filter((item) => item.type === SearchResultTypeEnum.MODEL_PAINT)
//           .map((item) => item.id),
//       },
//     });

//     response.forEach((item: ShoppingCartItemType) =>
//       shoppingCartStore.update(item, SearchResultTypeEnum.MODEL_PAINT),
//     );
//   } catch (error) {
//     console.error(error);
//   }
// };

// const refreshModelModules = async () => {
//   try {
//     const response = await modelModulesService.modules({
//       q: {
//         idIn: cartItems.value
//           .filter((item) => item.type === SearchResultTypeEnum.MODEL_MODULE)
//           .map((item) => item.id),
//       },
//     });

//     response.forEach((item: ShoppingCartItemType) =>
//       shoppingCartStore.update(item, SearchResultTypeEnum.MODEL_MODULE),
//     );
//   } catch (error) {
//     console.error(error);
//   }
// };

const refresh = () => {
  loading.value = true;

  refreshComponents();
  refreshCommodity();
  refreshEquipment();
  refreshModels();
  // refreshModelPaints();
  // refreshModelModules()

  loading.value = false;
};
</script>

<script lang="ts">
export default {
  name: "AppShoppingCartModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
