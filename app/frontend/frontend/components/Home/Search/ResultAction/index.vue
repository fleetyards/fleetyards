<script lang="ts">
export default {
  name: "HomeSearchResultAction",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  HANGAR_TYPES,
  useSearchResultAdd,
} from "@/frontend/components/Home/Search/useSearchResultAdd";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { type SearchResult } from "@/services/fyApi";

type Props = {
  result: SearchResult;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  // A modal took over from the search.
  opened: [];
  // The record cannot be added, which only its full record tells.
  unavailable: [];
}>();

const { t } = useI18n();
const { canAdd, add } = useSearchResultAdd();
const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const addsToHangar = computed(() => HANGAR_TYPES.includes(props.result.type));

const visible = computed(() => canAdd(props.result));

const label = computed(() => {
  if (props.result.type === "Blueprint") {
    return t("actions.blueprint.addToAssets");
  }

  return addsToHangar.value
    ? t("actions.addToHangar")
    : t("actions.logistics.addToInventory");
});

// Only ships can say so up front: both lists are kept in the session, while a
// blueprint's marks arrive with its full record.
const marked = computed(
  () =>
    props.result.type === "Model" &&
    [...(hangarStore.ships || []), ...(wishlistStore.ships || [])].includes(
      props.result.slug,
    ),
);

const loading = ref(false);

const open = async () => {
  loading.value = true;

  const outcome = await add(props.result);

  loading.value = false;

  if (outcome === "opened") emit("opened");
  if (outcome === "unavailable") emit("unavailable");
};
</script>

<template>
  <!-- A press on the row opens the item, so this one must not reach it. -->
  <span v-if="visible" @mousedown.stop>
    <Btn
      v-tooltip.bottom="label"
      :variant="BtnVariantsEnum.BARE"
      :size="BtnSizesEnum.SM"
      :loading="loading"
      :aria-label="label"
      data-test="home-search-action"
      @click.stop.prevent="open"
    >
      <i
        v-if="!addsToHangar"
        class="fa-duotone fa-box-open"
        aria-hidden="true"
      />
      <i v-else-if="marked" class="fa fa-bookmark" aria-hidden="true" />
      <i v-else class="fa-light fa-bookmark" aria-hidden="true" />
    </Btn>
  </span>
</template>
