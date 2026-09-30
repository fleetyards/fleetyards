import {
  Node,
  createBlockMarkdownSpec,
  type Editor,
  type Extensions,
} from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";
import Image from "@tiptap/extension-image";
import { Markdown } from "@tiptap/markdown";
import {
  isSafeMarkdownHref,
  isSafeMarkdownSrc,
} from "@/shared/utils/MarkdownUrls";
import { splitCodeSpans } from "@/shared/utils/Markdown";

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

// An image the renderer would refuse is not kept either: it would save as
// markdown that shows up on the page as its own source text.
const SafeImage = Image.extend({
  parseHTML() {
    return [
      {
        tag: "img[src]",
        getAttrs: (element) =>
          isSafeMarkdownSrc(element.getAttribute("src") ?? "") ? null : false,
      },
    ];
  },
}).configure({ inline: false, allowBase64: false });

export const HEADING_LEVELS = [1, 2, 3] as const;

// Markdown reads `<word>` as an HTML tag, and the editor drops a tag it has no
// node for -- so typed text like `<RSI handle>` would vanish on the next save.
// Outside code, `<` is handed over as the entity for itself, which the editor
// shows and writes back as the character it is.
export const protectHtml = (markdown: string) => {
  let fence: string | undefined;

  return markdown
    .split("\n")
    .map((line) => {
      const fenceMarker = /^ {0,3}(`{3,}|~{3,})/.exec(line)?.[1];

      if (fence) {
        if (line.trim().startsWith(fence)) fence = undefined;
        return line;
      }

      if (fenceMarker) {
        fence = fenceMarker;
        return line;
      }

      return splitCodeSpans(line)
        .map((part) =>
          part.code ? `\`${part.text}\`` : part.text.replaceAll("<", "&lt;"),
        )
        .join("");
    })
    .join("\n");
};

// Every block the markdown renderer shows, whether the toolbar offers it or
// not: a block the editor has no node for is flattened when a description is
// opened, and the next save would write the flattened text back. Underline is
// the one left out -- markdown has no way to write it.
export const markdownExtensions = (): Extensions => [
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
  Markdown,
];

// The editor keeps an empty paragraph after a closing image or block so there
// is somewhere to type below it; it is not part of the text.
export const toMarkdown = (editor: Editor) =>
  editor.isEmpty ? "" : editor.getMarkdown().trimEnd();
