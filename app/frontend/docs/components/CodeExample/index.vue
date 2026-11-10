<script lang="ts">
export default {
  name: "DocsCodeExample",
};
</script>

<script lang="ts" setup>
import hljs from "highlight.js";
import { useCopy } from "@/docs/composables/useCopy";

type Props = {
  code: string;
  language?: "javascript" | "html" | "markdown" | "plaintext";
  flush?: boolean;
  copyOnClick?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  language: "javascript",
  flush: false,
  copyOnClick: true,
});

// highlight.js marks an element it has highlighted and skips it from then on,
// so code that changes after mounting is highlighted to a string instead.
const highlighted = computed(
  () => hljs.highlight(props.code, { language: props.language }).value,
);

const { copy } = useCopy();

const onClick = () => {
  if (props.copyOnClick) {
    void copy(props.code);
  }
};
</script>

<template>
  <div
    class="code-example"
    :class="{
      'code-example--flush': flush,
      'code-example--copyable': copyOnClick,
    }"
    @click="onClick"
  >
    <i v-if="copyOnClick" class="fa-solid fa-copy code-example__copy"></i>
    <!-- eslint-disable-next-line vue/no-v-html -->
    <pre><code :class="`hljs language-${language}`" class="rounded !py-5 !px-4" v-html="highlighted"></code></pre>
  </div>
</template>

<style lang="scss" scoped>
.code-example {
  position: relative;
  margin: 2.5rem 0;

  @media (min-width: 1024px) {
    margin-left: 6rem;
    margin-right: 6rem;
  }

  pre {
    margin: 0 !important;
    border-radius: 0.375rem !important;
    border: 0.3em solid hsl(30, 20%, 40%);
    padding: 0.3rem;
    overflow-x: auto;
  }

  pre > code {
    padding: 20px 15px;
    background: #282c34 !important;
  }
}

.code-example--copyable {
  cursor: pointer;
}

.code-example--flush {
  margin: 0;

  pre > code {
    white-space: pre-wrap;
    overflow-wrap: anywhere;
  }

  @media (min-width: 1024px) {
    margin-left: 0;
    margin-right: 0;
  }
}

.code-example__copy {
  position: absolute;
  right: 2rem;
  top: 2rem;
  opacity: 0;
  transition: opacity 0.2s;
}

.code-example:hover .code-example__copy {
  opacity: 1;
}
</style>
