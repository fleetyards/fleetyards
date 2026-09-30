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

// Only what the markdown renderer can show. Everything else StarterKit brings
// is switched off, so the editor cannot produce a block the page would print as
// raw markdown.
export const markdownExtensions = (): Extensions => [
  StarterKit.configure({
    heading: { levels: [...HEADING_LEVELS] },
    blockquote: false,
    codeBlock: false,
    strike: false,
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
