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
import {
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
// shows a section closed.
const MarkdownDetails = Details.extend({
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

    return helpers.createNode("details", null, [
      helpers.createNode(
        "detailsSummary",
        null,
        helpers.parseInline((token as { summary?: [] }).summary ?? []),
      ),
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

// The summary is one line of markdown: text, its marks and catalogue items, but
// no hard break, which would end the line it is written on.
const MarkdownDetailsSummary = DetailsSummary.extend({
  content: "(text | catalogueToken)*",
  markdownTokenizer: undefined,
});

const MarkdownDetailsContent = DetailsContent.extend({
  markdownTokenizer: undefined,
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

const DETAILS_TAG = /^[ \t]*(?:<details(?:\s+open)?>|<\/details>)[ \t]*$/i;
const DETAILS_SUMMARY =
  /^([ \t]*(?:<details(?:\s+open)?>[ \t]*)?)<summary>(.*)<\/summary>[ \t]*$/i;

export const protectHtml = (markdown: string) => {
  let fence: string | undefined;

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
      if (DETAILS_TAG.test(body)) return line;

      const summary = DETAILS_SUMMARY.exec(body);

      if (summary) {
        return `${prefix}${summary[1]}<summary>${protectText(summary[2])}</summary>`;
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
