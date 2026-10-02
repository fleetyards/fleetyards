<script lang="ts">
export default {
  name: "ExternalLinks",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import starcitizenToolsLogo from "@/images/icons/starcitizentools.svg";

type Props = {
  // What the thing is called, looked up by name on each site.
  title: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const query = computed(() => encodeURIComponent(props.title.trim()));

// Through the wiki's own search rather than a page address: its titles are
// case-sensitive after the first letter, so "Stanton System" misses the
// "Stanton system" page, while the search's "Go" opens the page whatever the
// case and lists results where there is none, as for the two Outpost 54s.
const wikiUrl = computed(
  () =>
    `https://starcitizen.tools/index.php?title=Special:Search&go=Go&search=${query.value}`,
);

// The Galactapedia addresses an article by its id, so a name can only reach
// its search.
const galactapediaUrl = computed(
  () =>
    `https://robertsspaceindustries.com/galactapedia/search?query=${query.value}`,
);
</script>

<!-- Where else to read about the thing: the ship page's wiki button, and the
     Galactapedia. In the header's right-hand slot, where other pages put
     their actions, so a button never sits in among the badges. -->
<template>
  <Teleport to="#header-right">
    <div class="external-links" data-test="external-links">
      <Btn :href="wikiUrl" :size="BtnSizesEnum.MD" data-test="wiki-link">
        <img :src="starcitizenToolsLogo" alt="" class="external-links__logo" />
        <span>{{ t("labels.model.wiki") }}</span>
      </Btn>
      <Btn
        :href="galactapediaUrl"
        :size="BtnSizesEnum.MD"
        data-test="galactapedia-link"
      >
        <i class="fa-duotone fa-book-atlas" aria-hidden="true" />
        <span>{{ t("labels.galactapedia") }}</span>
      </Btn>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
.external-links {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;

  &__logo {
    width: 1em;
    height: 1em;
  }
}
</style>
