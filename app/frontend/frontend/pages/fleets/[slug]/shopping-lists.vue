<script lang="ts">
export default {
  name: "FleetShoppingListsPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import PageActions from "@/shared/components/PageActions/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import FleetShoppingListPanel from "@/frontend/components/Fleets/ShoppingLists/Panel/index.vue";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type FleetMember,
  type FleetShoppingList,
  getFleetShoppingListsQueryKey,
  useDestroyFleetShoppingList,
  useFleetShoppingLists,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const comlink = useComlink();
const queryClient = useQueryClient();
const { displayConfirm, displayAlert, displaySuccess } = useAppNotifications();

const listsQuery = useFleetShoppingLists(() => props.fleet.slug);

const lists = computed(() => listsQuery.data.value ?? []);

const capabilities = computed(() => props.membership?.capabilities);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);

const openPublish = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/ShoppingLists/ListModal/index.vue"),
    props: { fleet: props.fleet },
  });
};

const { mutate: destroy } = useDestroyFleetShoppingList({
  mutation: {
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: getFleetShoppingListsQueryKey(props.fleet.slug),
      });
      displaySuccess({ text: t("cart.fleetLists.messages.deleted") });
    },
    onError: () =>
      displayAlert({ text: t("cart.fleetLists.messages.deleteFailed") }),
  },
});

const confirmDelete = (list: FleetShoppingList) => {
  displayConfirm({
    text: t("cart.fleetLists.confirmDelete", { name: list.name }),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: () => destroy({ fleetSlug: props.fleet.slug, id: list.id }),
  });
};

watch(
  () => props.fleet,
  (fleet) => {
    if (!fleet) return;

    updateMetaInfo({
      title: t("title.fleets.shoppingLists", { fleet: fleet.name }),
    });
  },
  { immediate: true },
);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <div class="row">
    <div class="col-12">
      <Heading size="hero" hero>{{ t("cart.fleetLists.title") }}</Heading>
      <p class="fleet-shopping-lists__lead">{{ t("cart.fleetLists.lead") }}</p>
    </div>
  </div>

  <PageActions>
    <Btn
      v-if="capabilities?.createShoppingLists"
      data-test="fleet-shopping-list-publish"
      @click="openPublish"
    >
      <i class="fa-light fa-plus" />
      {{ t("cart.fleetLists.publish") }}
    </Btn>
  </PageActions>

  <AsyncData :async-status="listsQuery">
    <template #resolved>
      <template v-if="lists.length">
        <FleetShoppingListPanel
          v-for="list in lists"
          :key="list.id"
          :fleet="fleet"
          :list="list"
          :editable="!!capabilities?.updateShoppingLists"
          :deletable="!!capabilities?.destroyShoppingLists"
          @delete="confirmDelete"
        />
      </template>

      <Empty v-else variant="box" hide-actions>
        <template #headline>{{ t("cart.fleetLists.empty.title") }}</template>
        <template #info>
          <p>{{ t("cart.fleetLists.empty.text") }}</p>
        </template>
      </Empty>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.fleet-shopping-lists__lead {
  margin-bottom: 16px;
}
</style>
