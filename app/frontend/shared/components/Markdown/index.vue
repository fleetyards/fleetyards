<script lang="ts">
export default {
  name: "BaseMarkdown",
};
</script>

<script lang="ts" setup>
// Renders a small markdown subset: ATX headings, unordered lists, paragraphs,
// bold, italic, inline code, links, images and a `:::center` ... `:::` block,
// the container syntax Tiptap's markdown extension reads and writes (without a
// space after the colons). Anything else is passed through as text. Everything
// is HTML-escaped before a single tag is added, so the result is safe to hand
// to v-html -- which is why user-written text (a fleet's description) goes
// through here too.

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
// text rather than becoming an href. `//host` and `/\host` are another origin
// (browsers read a backslash as a slash there), so a path may not start so.
const SAME_ORIGIN_PATH = /^\/(?![/\\])/;

const safeHref = (url: string) =>
  /^https?:\/\//.test(url) || SAME_ORIGIN_PATH.test(url);

const safeSrc = (url: string) =>
  /^https:\/\//.test(url) || SAME_ORIGIN_PATH.test(url);

const formatText = (value: string) =>
  value
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (match, alt, url: string) =>
      safeSrc(url) ? `<img src="${url}" alt="${alt}" loading="lazy">` : match,
    )
    // A leading `!` is an image the pass above refused: it stays text.
    .replace(
      /(!?)\[([^\]]+)\]\(([^)\s]+)\)/g,
      (match, bang: string, label, url: string) =>
        !bang && safeHref(url)
          ? `<a href="${url}" target="_blank" rel="noopener noreferrer">${label}</a>`
          : match,
    )
    .replace(/(^|[^*\w[])\*(?!\s)([^*]+?)\*(?![*\w])/g, "$1<em>$2</em>");

const NAMED_ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
};

const decodeEntity = (entity: string) => {
  const numeric = /^#(x[\da-f]+|\d+)$/i.exec(entity);

  if (!numeric) {
    return NAMED_ENTITIES[entity.toLowerCase()];
  }

  const code = numeric[1].startsWith("x")
    ? parseInt(numeric[1].slice(1), 16)
    : parseInt(numeric[1], 10);

  return code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : undefined;
};

// A markdown writer escapes what would otherwise be markup (`\*`, `\[`) and
// writes `&`, `<` and `>` as entities. Both stand for a literal character, so
// each is swapped for a private-use placeholder that no formatting rule
// matches, and put back -- escaped -- once formatting is done.
const PLACEHOLDER = "";
const PLACEHOLDER_BASE = 0xe100;
const PLACEHOLDER_PATTERN = /([-])/g;
const LITERAL_PATTERN =
  /\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])|&(#x[\da-f]+|#\d+|[a-z]+);/gi;

const renderText = (value: string) => {
  const literals: string[] = [];

  // The placeholder marker itself cannot appear in the text, or it would read
  // as one.
  const marked = value
    .replaceAll(PLACEHOLDER, "")
    .replace(
      LITERAL_PATTERN,
      (match, escaped: string | undefined, entity: string | undefined) => {
        const literal = escaped ?? (entity ? decodeEntity(entity) : undefined);

        if (
          literal === undefined ||
          PLACEHOLDER_BASE + literals.length > 0xf8ff
        ) {
          return match;
        }

        literals.push(literal);
        return (
          PLACEHOLDER +
          String.fromCharCode(PLACEHOLDER_BASE + literals.length - 1)
        );
      },
    );

  return formatText(escapeHtml(marked)).replace(
    PLACEHOLDER_PATTERN,
    (_, index: string) =>
      escapeHtml(literals[index.charCodeAt(0) - PLACEHOLDER_BASE]),
  );
};

// Code spans are cut out first so nothing inside them is formatted or
// unescaped; `split` with a capture group puts them at the odd indices.
const renderInline = (value: string) =>
  value
    .split(/(`[^`]+`)/)
    .map((part, index) =>
      index % 2
        ? `<code>${escapeHtml(part.slice(1, -1))}</code>`
        : renderText(part),
    )
    .join("");

const html = computed(() => {
  const blocks: string[] = [];

  let list: string[] = [];
  let paragraph: string[] = [];
  let centred = false;

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

  const flush = () => {
    flushList();
    flushParagraph();
  };

  props.source.split("\n").forEach((line) => {
    const trimmed = line.trim();

    if (!centred && /^:::\s*center$/.test(trimmed)) {
      flush();
      blocks.push('<div class="markdown__center">');
      centred = true;
      return;
    }

    if (centred && trimmed === ":::") {
      flush();
      blocks.push("</div>");
      centred = false;
      return;
    }

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

  flush();

  if (centred) {
    blocks.push("</div>");
  }

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

  // The global reset strips list markers, which turns a list into indented
  // lines with nothing to separate them.
  :deep(ul) {
    margin: 0 0 8px;
    padding-left: 18px;
    list-style: disc;
  }

  :deep(li) {
    margin: 2px 0;
  }

  :deep(.markdown__center) {
    text-align: center;
  }

  :deep(img) {
    max-width: 100%;
    height: auto;
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
