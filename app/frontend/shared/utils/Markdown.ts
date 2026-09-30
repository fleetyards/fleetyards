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

// Link text and image descriptions may hold one level of balanced brackets
// (`[Team [A]](…)`), which is what a markdown writer leaves unescaped.
const formatText = (value: string, resolve: (text: string) => string) => {
  // A URL is judged by what the browser will get, with every escape and
  // entity in it resolved -- `/\/host` is `//host` once the backslash goes.
  const target = (url: string) => unescapeHtml(resolve(url));

  return (
    value
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/~~([^~]+)~~/g, "<del>$1</del>")
      .replace(
        /!\[((?:[^[\]]|\[[^[\]]*\])*)\]\(([^)\s]+)\)/g,
        (match, alt, url: string) =>
          isSafeMarkdownSrc(target(url))
            ? `<img src="${url}" alt="${alt}" loading="lazy">`
            : match,
      )
      // A leading `!` is an image the pass above refused: it stays text.
      .replace(
        /(!?)\[((?:[^[\]]|\[[^[\]]*\])+)\]\(([^)\s]+)\)/g,
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

const indentOf = (line: string) =>
  [...(/^[ \t]*/.exec(line)?.[0] ?? "")].reduce(
    (width, char) => width + (char === "\t" ? 4 : 1),
    0,
  );

// Removes `width` columns of leading indentation, a tab counting as four.
const dedent = (line: string, width: number) => {
  let column = 0;
  let index = 0;

  while (index < line.length && column < width) {
    if (line[index] === " ") column += 1;
    else if (line[index] === "\t") column += 4;
    else break;
    index += 1;
  }

  return line.slice(index);
};

const FENCE_OPEN = /^ {0,3}(`{3,}|~{3,})/;

// A closing fence is a line of nothing but the opening's character, at least
// as many of them -- ```still-code is a line of code, not the end of it.
export const closesFence = (line: string, marker: string) => {
  const close = /^ {0,3}(`{3,}|~{3,})\s*$/.exec(line);

  return (
    !!close && close[1][0] === marker[0] && close[1].length >= marker.length
  );
};

const LIST_ITEM = /^([ \t]*)([-*+]|\d{1,9}[.)])([ \t]+|$)(.*)$/;

type List = { type: "ul" | "ol"; start: number; items: string[] };

export const renderMarkdown = (source: string): string => {
  const lines = source.split("\n");
  const blocks: string[] = [];

  let list: List | undefined;
  let paragraph: string[] = [];
  let quote: string[] | undefined;
  let centred = false;

  const flushList = () => {
    if (!list) return;

    const items = list.items.map((item) => `<li>${item}</li>`).join("");
    const start =
      list.type === "ol" && list.start !== 1 ? ` start="${list.start}"` : "";
    blocks.push(`<${list.type}${start}>${items}</${list.type}>`);
    list = undefined;
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
    flushList();
    flushParagraph();
    flushQuote();
  };

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();

    const quoted = /^ {0,3}>\s?(.*)$/.exec(line);

    if (quoted) {
      flushList();
      flushParagraph();
      quote = [...(quote ?? []), quoted[1]];
      continue;
    }

    flushQuote();

    const fenceOpen = FENCE_OPEN.exec(line);

    if (fenceOpen) {
      flush();

      const code: string[] = [];
      index += 1;

      while (index < lines.length && !closesFence(lines[index], fenceOpen[1])) {
        code.push(lines[index]);
        index += 1;
      }

      blocks.push(`<pre><code>${escapeHtml(code.join("\n"))}</code></pre>`);
      continue;
    }

    if (!centred && /^:::\s*center$/.test(trimmed)) {
      flush();
      blocks.push('<div class="markdown__center">');
      centred = true;
      continue;
    }

    if (centred && trimmed === ":::") {
      flush();
      blocks.push("</div>");
      centred = false;
      continue;
    }

    // A line of = or - under a paragraph makes that paragraph a heading (the
    // "setext" form, which fleets used to underline their section titles).
    const underline = /^(=+|-+)$/.exec(trimmed);

    if (underline && paragraph.length) {
      const level = underline[1].startsWith("=") ? 3 : 4;
      blocks.push(`<h${level}>${paragraph.join(" ")}</h${level}>`);
      paragraph = [];
      continue;
    }

    if (/^([-*_])(\s*\1){2,}$/.test(trimmed)) {
      flush();
      blocks.push("<hr>");
      continue;
    }

    const heading = /^(#{1,6})\s+(.*)$/.exec(trimmed);

    if (heading) {
      flush();

      const level = Math.min(heading[1].length + 2, 6);
      blocks.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
      continue;
    }

    // An item is a container: every following line indented at least as far
    // as its text belongs to it -- a nested list, a second paragraph, a code
    // block -- and is rendered as markdown of its own.
    const item = LIST_ITEM.exec(line);

    if (item) {
      flushParagraph();

      const marker = item[2];
      const type = /\d/.test(marker) ? "ol" : "ul";
      const contentColumn =
        indentOf(item[1]) + marker.length + Math.max(item[3].length, 1);
      const content = [item[4]];

      while (index + 1 < lines.length) {
        const next = lines[index + 1];

        if (next.trim()) {
          if (indentOf(next) < contentColumn) break;
        } else {
          const following = lines
            .slice(index + 2)
            .find((candidate) => candidate.trim());

          if (!following || indentOf(following) < contentColumn) break;
        }

        content.push(dedent(next, contentColumn));
        index += 1;
      }

      if (list && list.type !== type) {
        flushList();
      }

      list ??= {
        type,
        start: type === "ol" ? parseInt(marker, 10) : 1,
        items: [],
      };

      // A single paragraph is the item's text itself, as in a tight list.
      const rendered = renderMarkdown(content.join("\n"));
      const single = /^<p>((?:(?!<p>)[\s\S])*)<\/p>$/.exec(rendered);
      list.items.push(single ? single[1] : rendered);
      continue;
    }

    if (!trimmed) {
      flush();
      continue;
    }

    flushList();
    paragraph.push(renderInline(trimmed));
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
