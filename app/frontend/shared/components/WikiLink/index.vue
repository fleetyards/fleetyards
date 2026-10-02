<script lang="ts">
export default {
  name: "WikiLink",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import starcitizenToolsLogo from "@/images/icons/starcitizentools.svg";

type Props = {
  // What the thing is called. Through the wiki's own search rather than a
  // page address: its titles are case-sensitive after the first letter, so
  // "Stanton System" misses the "Stanton system" page, while the search's
  // "Go" opens the page whatever the case and lists results where there is
  // none, as for the two Outpost 54s.
  title: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const href = computed(
  () =>
    `https://starcitizen.tools/index.php?title=Special:Search&go=Go&search=${encodeURIComponent(props.title.trim())}`,
);
</script>

<!-- The ship page's "Star Citizen Wiki" link, for any page named after a
     thing the wiki has a page for. Drawn as one more badge in a masthead's
     row of them, so it sits at their height rather than a button's. -->
<template>
  <a
    :href="href"
    class="wiki-link"
    target="_blank"
    rel="noopener"
    data-test="wiki-link"
  >
    <img :src="starcitizenToolsLogo" alt="" class="wiki-link__logo" />
    {{ t("labels.model.wiki") }}
  </a>
</template>

<style lang="scss" scoped>
.wiki-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  font-size: 13.5px;
  font-weight: 600;
  color: var(--color-text, #c8c8c8);
  white-space: nowrap;
  transition:
    border-color 150ms ease,
    color 150ms ease;

  &:hover,
  &:focus-visible {
    border-color: var(--color-primary, #428bca);
    color: #fff;
  }

  &__logo {
    width: 14px;
    height: 14px;
  }
}
</style>
