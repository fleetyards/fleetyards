<script lang="ts">
export default {
  name: "FleetShoppingListPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import AsyncData from "@/shared/components/AsyncData.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type CartLine,
  type Fleet,
  type FleetShoppingList,
  InventoryItemTypeEnum,
  type ItemPrice,
  useFleetShoppingList,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  list: FleetShoppingList;
  editable?: boolean;
  deletable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  deletable: false,
});

const emit = defineEmits<{
  delete: [list: FleetShoppingList];
}>();

const { t, toNumber } = useI18n();

const comlink = useComlink();

const uec = computed(() => t("number.units.uec"));

// The lines are asked for only once somebody opens the list: a fleet page of
// a dozen kits would otherwise price every one of them up front.
const expanded = ref(false);

const detailQuery = useFleetShoppingList(
  () => props.fleet.slug,
  () => props.list.id,
  { query: { enabled: expanded } },
);

const detail = computed(() => detailQuery.data.value);

const DETAIL_ROUTES: Record<InventoryItemTypeEnum, string> = {
  [InventoryItemTypeEnum.COMMODITY]: "commodity",
  [InventoryItemTypeEnum.COMPONENT]: "component",
  [InventoryItemTypeEnum.EQUIPMENT]: "equipment-item",
};

const itemRoute = (line: CartLine) => {
  const { item } = line;

  if (!item.listed || !item.slug || !item.type) return undefined;

  return { name: DETAIL_ROUTES[item.type], params: { slug: item.slug } };
};

const placeName = (price: ItemPrice) =>
  price.shop?.location.name ?? price.location;

const openCopy = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/ShoppingLists/CopyModal/index.vue"),
    props: { fleet: props.fleet, list: props.list },
  });
};

const openEdit = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/ShoppingLists/ListModal/index.vue"),
    props: { fleet: props.fleet, list: props.list },
  });
};
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="fleet-shopping-list"
    data-test="fleet-shopping-list"
  >
    <PanelHeading compact divider>
      {{ list.name }}
      <template #subtitle>
        <span class="fleet-shopping-list__meta">
          <span data-test="fleet-shopping-list-visibility">
            {{ t(`labels.logistics.visibilities.${list.visibility}`) }}
          </span>
          <span
            v-for="squadron in list.fleetSquadrons"
            :key="squadron.id"
            class="fleet-shopping-list__squadron"
          >
            <SquadronEmblem :squadron="squadron" :size="16" />
            {{ squadron.name }}
          </span>
          <span>
            · {{ t("cart.fleetLists.count", { count: list.itemsCount }) }}
          </span>
        </span>
      </template>
      <template #actions>
        <Btn
          :size="BtnSizesEnum.SM"
          :disabled="!list.linesCount"
          data-test="fleet-shopping-list-copy"
          @click="openCopy"
        >
          <i class="fa-light fa-cart-plus" />
          {{ t("cart.fleetLists.copy") }}
        </Btn>
        <BtnDropdown
          v-if="editable || deletable"
          expand-left
          :size="BtnSizesEnum.SM"
          data-test="fleet-shopping-list-menu"
        >
          <Btn
            v-if="editable"
            :size="BtnSizesEnum.SM"
            data-test="fleet-shopping-list-edit"
            @click="openEdit"
          >
            <i class="fa-light fa-pen" />
            {{ t("cart.fleetLists.edit") }}
          </Btn>
          <Btn
            v-if="deletable"
            :size="BtnSizesEnum.SM"
            :tone="BtnTonesEnum.DANGER"
            data-test="fleet-shopping-list-delete"
            @click="emit('delete', list)"
          >
            <i class="fa-light fa-trash" />
            {{ t("cart.fleetLists.delete") }}
          </Btn>
        </BtnDropdown>
      </template>
    </PanelHeading>
    <PanelBody>
      <p v-if="list.description" class="fleet-shopping-list__description">
        {{ list.description }}
      </p>

      <Btn
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.SM"
        :aria-expanded="expanded"
        data-test="fleet-shopping-list-toggle"
        @click="expanded = !expanded"
      >
        <i
          :class="
            expanded ? 'fa-light fa-chevron-up' : 'fa-light fa-chevron-down'
          "
        />
        {{
          expanded
            ? t("cart.fleetLists.hideItems")
            : t("cart.fleetLists.showItems")
        }}
      </Btn>

      <AsyncData v-if="expanded" :async-status="detailQuery">
        <template #resolved>
          <ul v-if="detail" class="fleet-shopping-list__lines">
            <li
              v-for="line in detail.items"
              :key="line.id"
              class="fleet-shopping-list__line"
              data-test="fleet-shopping-list-line"
            >
              <span class="fleet-shopping-list__quantity">
                {{ line.quantity }}×
              </span>
              <span class="fleet-shopping-list__name">
                <router-link v-if="itemRoute(line)" :to="itemRoute(line)!">
                  {{ line.item.name }}
                </router-link>
                <template v-else>{{ line.item.name }}</template>
                <small v-if="line.price" class="fleet-shopping-list__place">
                  {{ placeName(line.price) }}
                </small>
                <small v-else class="fleet-shopping-list__place">
                  {{ t("cart.totals.unavailable") }}
                </small>
              </span>
              <span class="fleet-shopping-list__price">
                <template v-if="line.total">
                  {{ toNumber(line.total, "integer") }} <small>{{ uec }}</small>
                </template>
                <template v-else>–</template>
              </span>
            </li>
            <li class="fleet-shopping-list__line fleet-shopping-list__total">
              <span />
              <span>{{ t("cart.totals.total") }}</span>
              <span
                class="fleet-shopping-list__price"
                data-test="fleet-shopping-list-total"
              >
                {{ toNumber(detail.totals.total, "integer") }}
                <small>{{ uec }}</small>
              </span>
            </li>
          </ul>
        </template>
      </AsyncData>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.fleet-shopping-list__meta {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
}

.fleet-shopping-list__squadron {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.fleet-shopping-list__description {
  margin-bottom: 8px;
  white-space: pre-line;
}

.fleet-shopping-list__lines {
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}

.fleet-shopping-list__line {
  display: grid;
  grid-template-columns: 4em 1fr auto;
  gap: 12px;
  align-items: baseline;
  padding: 6px 0;
  border-bottom: 1px solid var(--color-edge-soft);
}

.fleet-shopping-list__quantity {
  font-variant-numeric: tabular-nums;
  text-align: right;
}

.fleet-shopping-list__name {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.fleet-shopping-list__place {
  color: var(--color-text-dim);
}

.fleet-shopping-list__price {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  text-align: right;
}

.fleet-shopping-list__total {
  border-bottom: 0;
  font-weight: 600;
}
</style>
