<script lang="ts">
export default {
  name: "BaseMarkdown",
};
</script>

<script lang="ts" setup>
// Renders the markdown subset our own generated report bodies use: ATX
// headings, unordered lists, paragraphs, bold, inline code and inline links.
// Anything else is passed through as text. Everything is HTML-escaped before a
// single tag is added, so the result is safe to hand to v-html.

type Props = {
  source?: string;
};

const props = withDefaults(defineProps<Props>(), {
  source: "",
});

const escapeHtml = (value: string) =>
  value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

// Anything but http(s) and same-origin paths - javascript: above all - stays
// text rather than becoming an href.
const safeHref = (url: string) => /^(https?:\/\/|\/)/.test(url);

const renderInline = (value: string) =>
  escapeHtml(value)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (match, label, url: string) =>
      safeHref(url)
        ? `<a href="${url}" target="_blank" rel="noopener noreferrer">${label}</a>`
        : match,
    );

const html = computed(() => {
  const blocks: string[] = [];

  let list: string[] = [];
  let paragraph: string[] = [];

  const flushList = () => {
    if (!list.length) return;

    blocks.push(`<ul>${list.map((item) => `<li>${item}</li>`).join("")}</ul>`);
    list = [];
  };

  const flushParagraph = () => {
    if (!paragraph.length) return;

    blocks.push(`<p>${paragraph.join("<br>")}</p>`);
    paragraph = [];
  };

  props.source.split("\n").forEach((line) => {
    const trimmed = line.trim();

    const heading = /^(#{1,6})\s+(.*)$/.exec(trimmed);

    if (heading) {
      flushList();
      flushParagraph();

      const level = Math.min(heading[1].length + 2, 6);
      blocks.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
      return;
    }

    const item = /^[-*]\s+(.*)$/.exec(trimmed);

    if (item) {
      flushParagraph();
      list.push(renderInline(item[1]));
      return;
    }

    if (!trimmed) {
      flushList();
      flushParagraph();
      return;
    }

    flushList();
    paragraph.push(renderInline(trimmed));
  });

  flushList();
  flushParagraph();

  return blocks.join("");
});
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- escaped above, see renderInline -->
  <div class="markdown" v-html="html" />
</template>

<style lang="scss" scoped>
.markdown {
  /*
   * Report bodies carry generated identifiers - slugs, ids, urls - with no space
   * to break on, and this renders inside a narrow admin panel. `anywhere` rather
   * than `break-all`, so ordinary prose still breaks between words.
   */
  overflow-wrap: anywhere;

  :deep(h3),
  :deep(h4),
  :deep(h5),
  :deep(h6) {
    margin: 12px 0 6px;
    font-size: 1em;
    font-weight: bold;

    &:first-child {
      margin-top: 0;
    }
  }

  :deep(p) {
    margin: 0 0 8px;
  }

  :deep(ul) {
    margin: 0 0 8px;
    padding-left: 18px;
  }

  :deep(li) {
    margin: 2px 0;
  }

  :deep(code) {
    padding: 1px 4px;
    font-size: 0.9em;
    background-color: rgba($gray-darker, 0.8);
    border-radius: $border-radius-base;
  }

  :deep(:last-child) {
    margin-bottom: 0;
  }
}
</style>
