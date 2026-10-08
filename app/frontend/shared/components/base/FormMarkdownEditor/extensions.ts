import {
  Node,
  createBlockMarkdownSpec,
  type Editor,
  type Extensions,
} from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";
import Image from "@tiptap/extension-image";
import {
  Details,
  DetailsContent,
  DetailsSummary,
} from "@tiptap/extension-details";
import { Markdown } from "@tiptap/markdown";
import {
  isSafeMarkdownHref,
  isSafeMarkdownSrc,
} from "@/shared/utils/MarkdownUrls";
import { Plugin, type Transaction } from "@tiptap/pm/state";
import { ReplaceAroundStep } from "@tiptap/pm/transform";
import {
  DETAILS_CLOSE,
  DETAILS_OPEN,
  DETAILS_SUMMARY,
  closesFence,
  readDetails,
  splitCodeSpans,
} from "@/shared/utils/Markdown";
import {
  CatalogueToken,
  CatalogueTokenResolution,
  CatalogueTokenSuggestion,
  type CatalogueLookup,
  type CatalogueSearch,
} from "./catalogueTokens";

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    center: {
      toggleCenter: () => ReturnType;
    };
  }
}

// A `:::center` ... `:::` container: the one layout the markdown renderer knows
// beyond plain blocks. Rendered with the renderer's own class, so the editor
// shows it the way the page will.
export const Center = Node.create({
  name: "center",
  group: "block",
  content: "block+",
  defining: true,

  parseHTML() {
    return [{ tag: "div.markdown__center" }, { tag: "center" }];
  },

  renderHTML() {
    return ["div", { class: "markdown__center" }, 0];
  },

  ...createBlockMarkdownSpec({ nodeName: "center" }),

  addCommands() {
    return {
      toggleCenter:
        () =>
        ({ commands }) =>
          commands.toggleWrap(this.name),
    };
  },
});

const SUMMARY_NODES = ["text", "catalogueToken"];

// GitHub's collapsible section. The extension's own markdown is a nest of
// `:::details` containers nothing else reads, so the section is read with the
// renderer's own rules and written the way GitHub writes it:
//
//   <details>
//   <summary>Title</summary>
//
//   markdown
//
//   </details>
//
// A section opens in the editor, so what is in it can be seen and edited. The
// toggle is the editor's own view of the text, never written: the page always
// shows a section closed. It is not an edit either, so undo passes over it.
const isToggle = (tr: Transaction) => {
  const [step] = tr.steps;

  if (tr.steps.length !== 1 || !(step instanceof ReplaceAroundStep)) {
    return false;
  }

  const before = tr.before.nodeAt(step.from);
  const after = tr.doc.nodeAt(step.from);

  return (
    before?.type.name === "details" &&
    after?.type.name === "details" &&
    before.content.eq(after.content)
  );
};

const MarkdownDetails = Details.extend({
  addProseMirrorPlugins() {
    return [
      ...(this.parent?.() ?? []),
      new Plugin({
        filterTransaction: (tr) => {
          if (isToggle(tr)) tr.setMeta("addToHistory", false);
          return true;
        },
      }),
    ];
  },

  addAttributes() {
    return {
      open: {
        default: true,
        parseHTML: () => true,
        renderHTML: ({ open }) => (open ? { open: "" } : {}),
      },
    };
  },

  markdownTokenizer: {
    name: "details",
    level: "block",
    start: (src: string) => src.search(/^ {0,3}<details/im),
    tokenize: (src, _tokens, lexer) => {
      const lines = src.split("\n");
      const details = readDetails(lines, 0);

      if (!details) return undefined;

      const consumed = lines.slice(0, details.end + 1).join("\n");

      return {
        type: "details",
        raw: src.length > consumed.length ? `${consumed}\n` : consumed,
        summary: lexer.inlineTokens(details.summary),
        tokens: lexer.blockTokens(details.body.join("\n")),
      };
    },
  },

  parseMarkdown: (token, helpers) => {
    const body = helpers.parseChildren(token.tokens ?? []);

    // An image or a line break has no place on the summary's one line.
    const summary = helpers
      .parseInline((token as { summary?: [] }).summary ?? [])
      .filter((node) => SUMMARY_NODES.includes(node.type ?? ""));

    return helpers.createNode("details", null, [
      helpers.createNode("detailsSummary", null, summary),
      helpers.createNode(
        "detailsContent",
        null,
        body.length ? body : [helpers.createNode("paragraph")],
      ),
    ]);
  },

  renderMarkdown: (node, helpers) => {
    const [summary, content] = node.content ?? [];

    return [
      "<details>",
      `<summary>${helpers.renderChildren(summary?.content ?? [])}</summary>`,
      "",
      helpers.renderChildren(content?.content ?? [], "\n\n"),
      "",
      "</details>",
    ].join("\n");
  },
});

// The parts are written by the section itself. Their own `:::` containers are
// replaced rather than left out: an extension left without one takes its
// parent's.
const noMarkdown = (name: string) => ({
  name,
  level: "block" as const,
  start: () => -1,
  tokenize: () => undefined,
});

// The summary is one line of markdown: text, its marks and catalogue items, but
// no hard break, which would end the line it is written on.
const MarkdownDetailsSummary = DetailsSummary.extend({
  content: `(${SUMMARY_NODES.join(" | ")})*`,
  markdownTokenizer: noMarkdown("detailsSummary"),
});

const MarkdownDetailsContent = DetailsContent.extend({
  markdownTokenizer: noMarkdown("detailsContent"),
});

// How wide an image shows, as a share of the text column; none is full width.
// Written the way Pandoc and markdown-it-attrs write it -- `![a](src){width=50%}`
// -- and limited to these steps, so a description cannot size an image freely.
export const IMAGE_SIZES = ["25", "50", "75"] as const;

export type ImageSize = (typeof IMAGE_SIZES)[number];

const SIZED_IMAGE =
  /^!\[((?:[^[\]\\]|\\.|\[[^[\]]*\])*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)\{width=(25|50|75)%\}/;

// An image the renderer would refuse is not kept either: it would save as
// markdown that shows up on the page as its own source text.
const SafeImage = Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      size: {
        default: null,
        parseHTML: (element) => {
          const size = element.getAttribute("data-size");
          return IMAGE_SIZES.includes(size as ImageSize) ? size : null;
        },
        renderHTML: (attributes) =>
          attributes.size ? { "data-size": attributes.size } : {},
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "img[src]",
        getAttrs: (element) =>
          isSafeMarkdownSrc(element.getAttribute("src") ?? "") ? null : false,
      },
    ];
  },

  // Runs before the markdown parser's own image rule and takes only an image
  // that carries a size; any other is left to that rule.
  markdownTokenizer: {
    name: "image",
    level: "inline",
    start: (src: string) => src.indexOf("!["),
    tokenize: (src: string) => {
      const match = SIZED_IMAGE.exec(src);

      if (!match) return undefined;

      return {
        type: "image",
        raw: match[0],
        text: match[1].replace(/\\(.)/g, "$1"),
        href: match[2],
        title: match[3] ?? null,
        size: match[4],
      };
    },
  },

  parseMarkdown: (token, helpers) =>
    helpers.createNode("image", {
      src: token.href,
      title: token.title,
      alt: token.text,
      size: (token as { size?: string }).size ?? null,
    }),

  renderMarkdown: (node) => {
    const { src, alt, title, size } = node.attrs ?? {};
    const image = title
      ? `![${alt ?? ""}](${src ?? ""} "${title}")`
      : `![${alt ?? ""}](${src ?? ""})`;

    return size ? `${image}{width=${size}%}` : image;
  },
}).configure({ inline: false, allowBase64: false });

export const HEADING_LEVELS = [1, 2, 3] as const;

// Markdown reads `<word>` as an HTML tag, and the editor drops a tag it has no
// node for -- so typed text like `<RSI handle>` would vanish on the next save.
// Outside code, `<` is handed over as the entity for itself, which the editor
// shows and writes back as the character it is.
const protectText = (text: string) =>
  splitCodeSpans(text)
    .map((part) =>
      part.code ? `\`${part.text}\`` : part.text.replaceAll("<", "&lt;"),
    )
    .join("");

export const protectHtml = (markdown: string) => {
  let fence: string | undefined;
  let sectionPrefix = "";
  let depth = 0;
  let awaitingSummary = false;

  return markdown
    .split("\n")
    .map((line) => {
      // A fence can sit inside a quote or a list item: look past the `>`
      // markers and the indentation for it.
      const prefix = /^(?:[ \t]*>[ \t]?)*/.exec(line)?.[0] ?? "";
      const body = line.slice(prefix.length);

      if (fence) {
        if (closesFence(body.trimStart(), fence)) fence = undefined;
        return line;
      }

      const fenceMarker = /^[ \t]*(`{3,}|~{3,})/.exec(body)?.[1];

      if (fenceMarker) {
        fence = fenceMarker;
        return line;
      }

      // A details section's own tags stay tags; a summary's text does not.
      // A section's own tags stay tags, and only where the renderer reads
      // them as one -- a stray `</details>` is text. A summary's text is
      // still text. A quote is a document of its own, so sections are
      // counted per quote level.
      if (prefix !== sectionPrefix) {
        sectionPrefix = prefix;
        depth = 0;
        awaitingSummary = false;
      }

      const open = DETAILS_OPEN.exec(body);

      if (open) {
        depth += 1;
        awaitingSummary = open[2] === undefined;

        return open[2] === undefined
          ? line
          : `${prefix}${open[1]}<summary>${protectText(open[2])}</summary>`;
      }

      if (awaitingSummary && body.trim()) {
        awaitingSummary = false;

        const summary = DETAILS_SUMMARY.exec(body);

        if (summary) {
          return `${prefix}${summary[1]}<summary>${protectText(summary[2])}</summary>`;
        }
      }

      if (depth > 0 && DETAILS_CLOSE.test(body)) {
        depth -= 1;
        return line;
      }

      return prefix + protectText(body);
    })
    .join("\n");
};

// Every block the markdown renderer shows, whether the toolbar offers it or
// not: a block the editor has no node for is flattened when a description is
// opened, and the next save would write the flattened text back. Underline is
// the one left out -- markdown has no way to write it.
export const markdownExtensions = ({
  searchCatalogue,
  lookupCatalogue,
  detailsToggleLabel,
}: {
  searchCatalogue?: CatalogueSearch;
  lookupCatalogue?: CatalogueLookup;
  // Names the button that opens or closes a section in the editor.
  detailsToggleLabel?: (isOpen: boolean) => string;
} = {}): Extensions => [
  StarterKit.configure({
    heading: { levels: [...HEADING_LEVELS] },
    underline: false,
    link: {
      openOnClick: false,
      autolink: true,
      defaultProtocol: "https",
      isAllowedUri: (url) => isSafeMarkdownHref(url),
      HTMLAttributes: { rel: "noopener noreferrer", target: "_blank" },
    },
  }),
  SafeImage,
  Center,
  MarkdownDetails.configure({
    persist: true,
    ...(detailsToggleLabel
      ? {
          renderToggleButton: ({ element, isOpen }) => {
            element.setAttribute("aria-label", detailsToggleLabel(isOpen));
          },
        }
      : {}),
  }),
  MarkdownDetailsSummary,
  MarkdownDetailsContent,
  CatalogueToken,
  CatalogueTokenSuggestion.configure(
    searchCatalogue ? { search: searchCatalogue } : {},
  ),
  CatalogueTokenResolution.configure(
    lookupCatalogue ? { lookup: lookupCatalogue } : {},
  ),
  Markdown,
];

// The editor keeps an empty paragraph after a closing image or block so there
// is somewhere to type below it; it is not part of the text.
export const toMarkdown = (editor: Editor) =>
  editor.isEmpty ? "" : editor.getMarkdown().trimEnd();
