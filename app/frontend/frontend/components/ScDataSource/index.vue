<script lang="ts">
export default {
  name: "ScDataSourceSwitch",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import { useQueryClient } from "@tanstack/vue-query";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useNavStore } from "@/shared/stores/nav";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";
import { useScDataSources } from "@/services/fyApi";

const { t } = useI18n();
const queryClient = useQueryClient();
const store = useScDataSourceStore();
const { hasChoice, previewSource } = storeToRefs(store);

// The switch is also what tells the store which builds exist, so the two cannot
// disagree: a source the server stopped offering is dropped from the choice.
// That is what closes a ptu cycle on its own -- once live catches up the server
// stops offering the preview, and this item goes away without anyone editing it.
const { data } = useScDataSources();

watch(
  () => data.value,
  (result) => {
    if (result?.items) store.setAvailable(result.items);
  },
  { immediate: true },
);

const selected = computed(() => store.selected);

const onPreview = computed(() => !!selected.value && !selected.value.default);

const label = computed(() => t("nav.scDataSource"));

// The same two conditions NavItem collapses on, because the item's own slot is
// what carries the build here and the slot is handed no state.
const mobile = useMobile();
const { slim: navSlim } = storeToRefs(useNavStore());
const slim = computed(() => navSlim.value && !mobile.value);

// Everything cached was fetched against another build, so it all goes. Sending
// the new source without this would show the old build's data under the new
// label until each query happened to refetch.
const toggle = async () => {
  // Two states, never a list: the live build and the newest preview of it.
  // Read against that preview rather than against "is this the default", so a
  // reader left on a preview the server has since passed -- a second channel
  // configured, or an older choice restored -- is one press from the build the
  // switch offers, not one press from live and a second one back out.
  store.select(
    selected.value?.environment === previewSource.value?.environment
      ? undefined
      : previewSource.value?.environment,
  );

  // Invalidated rather than cleared. `clear()` removes every query, so the
  // mounted observers have nothing left to refetch and the page keeps showing
  // what it already had -- no request goes out at all. Invalidating marks them
  // stale and refetches the active ones, which is what makes the switch visible.
  await queryClient.invalidateQueries();
};
</script>

<template>
  <!-- A row of the navigation rather than a control on the page: it belongs to
       the app the way the collapse toggle does. It stood in the header first,
       where it fought the page's own toolbar for the same slot and had to be
       kept off the pages that had no room for it -- here it costs a row, so it
       is offered wherever the choice exists at all.
       `label` is still handed over for the tooltip the item shows once the
       navigation is collapsed. -->
  <NavItem
    v-if="hasChoice"
    :action="() => void toggle()"
    menu-key="sc-data-source"
    :label="label"
    class="sc-data-source-switch"
    :class="{ 'sc-data-source-switch--preview': onPreview }"
  >
    <span class="sc-data-source-switch__inner">
      <!-- The build stands where every other row has its icon. One glyph cannot
           say which of two builds is being read, and this is the one row whose
           whole point is which -- so it says it in words, and it is all that is
           left once the navigation collapses to the icon column. -->
      <!-- On one line: a newline either side of the interpolation leaves text
           nodes in the box, and the name stops sitting centred in it. -->
      <span class="sc-data-source-switch__build">{{
        selected?.environment
      }}</span>
      <span v-if="!slim" class="sc-data-source-switch__label">
        {{ label }}
      </span>
    </span>
  </NavItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
