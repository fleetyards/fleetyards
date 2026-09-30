<script lang="ts">
export default {
  name: "BaseMarkdown",
};
</script>

<script lang="ts" setup>
import { useQuery } from "@tanstack/vue-query";
import { catalogueLookup } from "@/services/fyApi";
import { renderMarkdown } from "@/shared/utils/Markdown";
import { MARKDOWN_CATALOGUE_TOKEN } from "./catalogueTokens";

// The text and the links mounted into it are two roots, so a class or a test
// hook the caller passes is placed on the text by hand.
defineOptions({ inheritAttrs: false });

type Props = {
  source?: string;
};

const props = withDefaults(defineProps<Props>(), {
  source: "",
});

const html = computed(() => renderMarkdown(props.source));

const tokenComponent = inject(MARKDOWN_CATALOGUE_TOKEN, null);

const root = ref<HTMLElement>();

type TokenMark = { element: HTMLElement; token: string };

// The marks the rendered text holds. They are replaced with every render of
// the text, so they are dropped before it re-renders and read again after --
// a link mounted into a mark that is gone would go with it.
const marks = shallowRef<TokenMark[]>([]);
const renderCount = ref(0);

watch(
  html,
  () => {
    marks.value = [];
  },
  { flush: "pre" },
);

watch(
  html,
  async () => {
    await nextTick();

    renderCount.value += 1;
    marks.value = tokenComponent
      ? Array.from(
          root.value?.querySelectorAll<HTMLElement>("[data-catalogue-token]") ??
            [],
        ).map((element) => ({
          element,
          token: element.dataset.catalogueToken ?? "",
        }))
      : [];
  },
  { immediate: true, flush: "post" },
);

// One request for the whole text, however many items it names.
const names = computed(() =>
  [...new Set(marks.value.map((mark) => mark.token))].sort(),
);

const { data } = useQuery({
  queryKey: computed(() => ["catalogueLookup", names.value]),
  queryFn: () => catalogueLookup({ names: names.value }),
  enabled: computed(() => names.value.length > 0),
  staleTime: 5 * 60 * 1000,
});

const matches = computed(
  () => new Map((data.value?.items ?? []).map((match) => [match.token, match])),
);

const resolvedMarks = computed(() =>
  marks.value.flatMap((mark, index) => {
    const match = matches.value.get(mark.token);

    return match
      ? [{ ...mark, match, key: `${renderCount.value}-${index}` }]
      : [];
  }),
);
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- renderMarkdown escapes every character it does not turn into a tag -->
  <div
    ref="root"
    v-bind="$attrs"
    class="markdown markdown-content"
    v-html="html"
  />
  <template v-if="tokenComponent">
    <Teleport v-for="mark in resolvedMarks" :key="mark.key" :to="mark.element">
      <component
        :is="tokenComponent"
        :item="{
          type: mark.match.type,
          slug: mark.match.slug,
          name: mark.match.name,
        }"
      />
    </Teleport>
  </template>
</template>

<style lang="scss">
@import "./content";
</style>
