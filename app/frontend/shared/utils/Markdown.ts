import {
  isSafeMarkdownHref,
  isSafeMarkdownSrc,
} from "@/shared/utils/MarkdownUrls";

// Renders the markdown the editor writes: ATX and underlined headings,
// bulleted and numbered lists (nested by indentation), block quotes, fenced
// code, horizontal rules, paragraphs, bold, italic, strikethrough, inline
// code, links, images and a `:::center` ... `:::` block, the container syntax
// Tiptap's markdown extension reads and writes (without a space after the
// colons). Anything else is passed through as text. Everything is
// HTML-escaped before a single tag is added, so the result is safe to hand to
// v-html -- which is why user-written text goes through here too.

const escapeHtml = (value: string) =>
  value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

const unescapeHtml = (value: string) =>
  value
    .replace(/&quot;/g, '"')
    .replace(/&gt;/g, ">")
    .replace(/&lt;/g, "<")
    .replace(/&amp;/g, "&");

const NAMED_ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: "\u00a0",
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
const PLACEHOLDER = "\ue000";
const PLACEHOLDER_BASE = 0xe100;
const PLACEHOLDER_LAST = 0xf8ff;
const PLACEHOLDER_PATTERN = /\ue000([\ue100-\uf8ff])/g;
const LITERAL_PATTERN =
  /\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])|&(#x[\da-f]+|#\d+|[a-z]+);/gi;

const formatText = (value: string, resolve: (text: string) => string) => {
  // A URL is judged by what the browser will get, with every escape and
  // entity in it resolved -- `/\/host` is `//host` once the backslash goes.
  const target = (url: string) => unescapeHtml(resolve(url));

  return (
    value
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/~~([^~]+)~~/g, "<del>$1</del>")
      .replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (match, alt, url: string) =>
        isSafeMarkdownSrc(target(url))
          ? `<img src="${url}" alt="${alt}" loading="lazy">`
          : match,
      )
      // A leading `!` is an image the pass above refused: it stays text.
      .replace(
        /(!?)\[([^\]]+)\]\(([^)\s]+)\)/g,
        (match, bang: string, label, url: string) =>
          !bang && isSafeMarkdownHref(target(url))
            ? `<a href="${url}" target="_blank" rel="noopener noreferrer">${label}</a>`
            : match,
      )
      .replace(/(^|[^*\w[])\*(?!\s)([^*]+?)\*(?![*\w])/g, "$1<em>$2</em>")
  );
};

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
          PLACEHOLDER_BASE + literals.length > PLACEHOLDER_LAST
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

  const literalAt = (index: string) =>
    literals[index.charCodeAt(0) - PLACEHOLDER_BASE];

  const resolve = (text: string) =>
    text.replace(PLACEHOLDER_PATTERN, (_, index: string) =>
      escapeHtml(literalAt(index)),
    );

  return resolve(formatText(escapeHtml(marked), resolve));
};

// Code spans are cut out first so nothing inside them is formatted or
// unescaped. A backslash-escaped backtick opens nothing: it is text.
export const splitCodeSpans = (value: string) => {
  const parts: { code: boolean; text: string }[] = [];
  let text = "";
  let index = 0;

  while (index < value.length) {
    const char = value[index];

    if (char === "\\" && index + 1 < value.length) {
      text += value.slice(index, index + 2);
      index += 2;
      continue;
    }

    if (char === "`") {
      const close = value.indexOf("`", index + 1);

      if (close > index + 1) {
        if (text) parts.push({ code: false, text });
        parts.push({ code: true, text: value.slice(index + 1, close) });
        text = "";
        index = close + 1;
        continue;
      }
    }

    text += char;
    index += 1;
  }

  if (text) parts.push({ code: false, text });

  return parts;
};

const renderInline = (value: string) =>
  splitCodeSpans(value)
    .map((part) =>
      part.code
        ? `<code>${escapeHtml(part.text)}</code>`
        : renderText(part.text),
    )
    .join("");

type OpenList = {
  type: "ul" | "ol";
  indent: number;
  start: number;
  items: string[];
};

const indentOf = (line: string) =>
  [...(/^[ \t]*/.exec(line)?.[0] ?? "")].reduce(
    (width, char) => width + (char === "\t" ? 4 : 1),
    0,
  );

export const renderMarkdown = (source: string): string => {
  const blocks: string[] = [];

  const lists: OpenList[] = [];
  let paragraph: string[] = [];
  let quote: string[] | undefined;
  let fence: { marker: string; lines: string[] } | undefined;
  let centred = false;

  const closeList = () => {
    const list = lists.pop();

    if (!list) return;

    const items = list.items.map((item) => `<li>${item}</li>`).join("");
    const start =
      list.type === "ol" && list.start !== 1 ? ` start="${list.start}"` : "";
    const html = `<${list.type}${start}>${items}</${list.type}>`;
    const parent = lists.at(-1);

    if (parent) {
      parent.items[parent.items.length - 1] += html;
    } else {
      blocks.push(html);
    }
  };

  const flushLists = () => {
    while (lists.length) closeList();
  };

  const flushParagraph = () => {
    if (!paragraph.length) return;

    blocks.push(`<p>${paragraph.join("<br>")}</p>`);
    paragraph = [];
  };

  // A quote holds markdown of its own, so its lines are rendered as a
  // document of their own.
  const flushQuote = () => {
    if (!quote) return;

    blocks.push(`<blockquote>${renderMarkdown(quote.join("\n"))}</blockquote>`);
    quote = undefined;
  };

  const flush = () => {
    flushLists();
    flushParagraph();
    flushQuote();
  };

  const addItem = (
    type: "ul" | "ol",
    content: string,
    indent: number,
    start = 1,
  ) => {
    flushParagraph();
    flushQuote();

    while (lists.length && indent < lists[lists.length - 1].indent) {
      closeList();
    }

    const current = lists.at(-1);

    if (current && indent === current.indent && current.type !== type) {
      closeList();
    }

    const parent = lists.at(-1);

    if (!parent || indent > parent.indent) {
      lists.push({ type, indent, start, items: [] });
    }

    lists[lists.length - 1].items.push(renderInline(content));
  };

  source.split("\n").forEach((line) => {
    const trimmed = line.trim();

    if (fence) {
      if (trimmed.startsWith(fence.marker)) {
        blocks.push(
          `<pre><code>${escapeHtml(fence.lines.join("\n"))}</code></pre>`,
        );
        fence = undefined;
      } else {
        fence.lines.push(line);
      }
      return;
    }

    const fenceOpen = /^ {0,3}(`{3,}|~{3,})/.exec(line);

    if (fenceOpen) {
      flush();
      fence = { marker: fenceOpen[1], lines: [] };
      return;
    }

    const quoted = /^ {0,3}>\s?(.*)$/.exec(line);

    if (quoted) {
      flushLists();
      flushParagraph();
      quote = [...(quote ?? []), quoted[1]];
      return;
    }

    flushQuote();

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
      flush();

      const level = Math.min(heading[1].length + 2, 6);
      blocks.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
      return;
    }

    const item = /^[-*+]\s+(.*)$/.exec(trimmed);

    if (item) {
      addItem("ul", item[1], indentOf(line));
      return;
    }

    const numbered = /^(\d{1,9})[.)]\s+(.*)$/.exec(trimmed);

    if (numbered) {
      addItem("ol", numbered[2], indentOf(line), Number(numbered[1]));
      return;
    }

    if (!trimmed) {
      flush();
      return;
    }

    flushLists();
    paragraph.push(renderInline(trimmed));
  });

  if (fence) {
    blocks.push(
      `<pre><code>${escapeHtml(fence.lines.join("\n"))}</code></pre>`,
    );
  }

  flush();

  if (centred) {
    blocks.push("</div>");
  }

  return blocks.join("");
};

// The text a one-line preview shows -- a table cell, a card's lede -- with
// the markup gone. Read back out of the rendered HTML, so it agrees with the
// renderer about what is markup; an inert template, so nothing in it loads.
export const markdownToPlainText = (source: string) => {
  const template = document.createElement("template");
  template.innerHTML = renderMarkdown(source).replace(
    /<br>|<\/(p|li|h\d|div|pre|blockquote)>/g,
    "$& ",
  );

  return (template.content.textContent ?? "").replace(/\s+/g, " ").trim();
};
