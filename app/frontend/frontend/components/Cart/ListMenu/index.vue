<script lang="ts">
export default {
  name: "CartListMenu",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useCartLists } from "@/services/fyApi";

type Props = {
  size?: `${BtnSizesEnum}`;
  variant?: `${BtnVariantsEnum}`;
};

withDefaults(defineProps<Props>(), {
  size: BtnSizesEnum.MD,
  variant: BtnVariantsEnum.GHOST,
});

const emit = defineEmits<{ pick: [listId: string] }>();

const { t } = useI18n();

const { isAuthenticated } = storeToRefs(useSessionStore());

// One request however many buttons a page has: they share the query.
const { data: lists } = useCartLists({ query: { enabled: isAuthenticated } });

// The main button already adds to the active list.
const others = computed(() =>
  (lists.value ?? []).filter((list) => !list.active),
);
</script>

<template>
  <BtnDropdown
    v-if="others.length"
    :size="size"
    :variant="variant"
    expand-left
    data-test="cart-list-menu"
    @click.stop.prevent
  >
    <template #label>
      <i class="fa-light fa-chevron-down" />
      <span class="sr-only">{{ t("cart.lists.addTo") }}</span>
    </template>
    <Btn
      v-for="list in others"
      :key="list.id"
      :size="BtnSizesEnum.SM"
      :data-test="`cart-list-pick-${list.id}`"
      @click.stop.prevent="emit('pick', list.id)"
    >
      <i class="fa-light fa-list" />
      {{ t("cart.lists.addToList", { name: list.name }) }}
    </Btn>
  </BtnDropdown>
</template>
