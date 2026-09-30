<script lang="ts">
export default {
  name: "BaseMarkdown",
};
</script>

<script lang="ts" setup>
import {
  isSafeMarkdownHref,
  isSafeMarkdownSrc,
} from "@/shared/utils/MarkdownUrls";

// Renders a small markdown subset: ATX and underlined headings, bulleted and
// numbered lists, horizontal rules, paragraphs, bold, italic, inline code,
// links, images and a `:::center` ... `:::` block,
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

const formatText = (value: string) =>
  value
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (match, alt, url: string) =>
      isSafeMarkdownSrc(url)
        ? `<img src="${url}" alt="${alt}" loading="lazy">`
        : match,
    )
    // A leading `!` is an image the pass above refused: it stays text.
    .replace(
      /(!?)\[([^\]]+)\]\(([^)\s]+)\)/g,
      (match, bang: string, label, url: string) =>
        !bang && isSafeMarkdownHref(url)
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
  let listType: "ul" | "ol" = "ul";
  let listStart = 1;
  let paragraph: string[] = [];
  let centred = false;

  const flushList = () => {
    if (!list.length) return;

    const items = list.map((item) => `<li>${item}</li>`).join("");
    const start =
      listType === "ol" && listStart !== 1 ? ` start="${listStart}"` : "";
    blocks.push(`<${listType}${start}>${items}</${listType}>`);
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

  const addItem = (type: "ul" | "ol", content: string, start = 1) => {
    flushParagraph();

    if (list.length && listType !== type) {
      flushList();
    }

    if (!list.length) {
      listType = type;
      listStart = start;
    }

    list.push(renderInline(content));
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

    // A line of = or - under a paragraph makes that paragraph a heading (the
    // "setext" form, which fleets used to underline their section titles).
    const underline = /^(=+|-+)$/.exec(trimmed);

    if (underline && paragraph.length) {
      const level = underline[1].startsWith("=") ? 3 : 4;
      blocks.push(`<h${level}>${paragraph.join(" ")}</h${level}>`);
      paragraph = [];
      return;
    }

    if (/^([-*_])(\s*\1){2,}$/.test(trimmed)) {
      flush();
      blocks.push("<hr>");
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

    const item = /^[-*+]\s+(.*)$/.exec(trimmed);

    if (item) {
      addItem("ul", item[1]);
      return;
    }

    const numbered = /^(\d{1,9})[.)]\s+(.*)$/.exec(trimmed);

    if (numbered) {
      addItem("ol", numbered[2], Number(numbered[1]));
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
  <div class="markdown markdown-content" v-html="html" />
</template>

<style lang="scss">
@import "./content";
</style>
