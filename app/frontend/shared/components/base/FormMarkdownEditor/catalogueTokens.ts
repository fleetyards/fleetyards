import { Extension, Node, mergeAttributes } from "@tiptap/core";
import { VueRenderer } from "@tiptap/vue-3";
import { PluginKey } from "@tiptap/pm/state";
import Suggestion, { type SuggestionOptions } from "@tiptap/suggestion";
import { computePosition, flip, offset, shift } from "@floating-ui/dom";
import { catalogueSearch, type CatalogueTokenMatch } from "@/services/fyApi";
import {
  catalogueTokenName,
  catalogueTokenText,
} from "@/shared/utils/CatalogueTokens";
import SuggestionList from "./CatalogueSuggestionList.vue";

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    catalogueToken: {
      insertCatalogueToken: (token: string) => ReturnType;
    };
  }
}

const TOKEN = /^\[\*([^*\]\n]+?)\*\]/;

// A catalogue item named inline. One unit in the text -- a chip -- that the
// markdown keeps as `[*Name*]` or `[*type:Name*]`, the way the renderer reads
// it. Without a node of its own the editor would escape the brackets and read
// the name as emphasis, and the first save would rewrite the token.
export const CatalogueToken = Node.create({
  name: "catalogueToken",
  group: "inline",
  inline: true,
  atom: true,
  selectable: true,

  addAttributes() {
    return {
      token: {
        default: "",
        parseHTML: (element) => element.getAttribute("data-catalogue-token"),
        renderHTML: (attributes) => ({
          "data-catalogue-token": attributes.token,
        }),
      },
    };
  },

  parseHTML() {
    return [{ tag: "span[data-catalogue-token]" }];
  },

  renderHTML({ node, HTMLAttributes }) {
    return [
      "span",
      mergeAttributes(HTMLAttributes, {
        class: "catalogue-token catalogue-token--chip",
      }),
      catalogueTokenName(node.attrs.token as string),
    ];
  },

  renderText({ node }) {
    return catalogueTokenText(node.attrs.token as string);
  },

  markdownTokenizer: {
    name: "catalogueToken",
    level: "inline",
    start: (src: string) => src.indexOf("[*"),
    tokenize: (src: string) => {
      const match = TOKEN.exec(src);

      if (!match) return undefined;

      return { type: "catalogueToken", raw: match[0], token: match[1].trim() };
    },
  },

  parseMarkdown: (token, helpers) =>
    helpers.createNode("catalogueToken", {
      token: (token as { token?: string }).token ?? "",
    }),

  renderMarkdown: (node) =>
    catalogueTokenText((node.attrs?.token as string | undefined) ?? ""),

  addCommands() {
    return {
      insertCatalogueToken:
        (token) =>
        ({ commands }) =>
          commands.insertContent([
            { type: this.name, attrs: { token } },
            { type: "text", text: " " },
          ]),
    };
  },
});

export type CatalogueSearch = (query: string) => Promise<CatalogueTokenMatch[]>;

const defaultSearch: CatalogueSearch = async (query) =>
  (await catalogueSearch({ q: query })).items;

const SEARCH_DELAY = 150;

// Typing `[*` offers the items whose names would resolve; picking one inserts
// its token. A name shorter than two characters searches nothing.
export const CatalogueTokenSuggestion = Extension.create<{
  search: CatalogueSearch;
}>({
  name: "catalogueTokenSuggestion",

  addOptions() {
    return { search: defaultSearch };
  },

  addProseMirrorPlugins() {
    const { search } = this.options;
    let pending: ReturnType<typeof setTimeout> | undefined;

    const items: SuggestionOptions<CatalogueTokenMatch>["items"] = ({
      query,
    }) => {
      clearTimeout(pending);

      if (query.trim().length < 2) return [];

      return new Promise((resolve) => {
        pending = setTimeout(() => {
          search(query.trim()).then(resolve, () => resolve([]));
        }, SEARCH_DELAY);
      });
    };

    return [
      Suggestion<CatalogueTokenMatch>({
        editor: this.editor,
        pluginKey: new PluginKey("catalogueTokenSuggestion"),
        char: "[*",
        allowSpaces: true,
        allowedPrefixes: null,
        items,
        command: ({ editor, range, props }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .insertCatalogueToken(props.token)
            .run();
        },
        render: () => {
          let list: VueRenderer | undefined;
          let clientRect: (() => DOMRect | null) | null | undefined;

          const place = () => {
            const element = list?.element as HTMLElement | undefined;
            const rect = clientRect?.();

            if (!element || !rect) return;

            void computePosition(
              { getBoundingClientRect: () => rect },
              element,
              {
                placement: "bottom-start",
                strategy: "fixed",
                middleware: [offset(6), flip(), shift({ padding: 8 })],
              },
            ).then(({ x, y }) => {
              Object.assign(element.style, { left: `${x}px`, top: `${y}px` });
            });
          };

          return {
            onStart: (props) => {
              clientRect = props.clientRect;
              list = new VueRenderer(SuggestionList, {
                props: {
                  items: props.items,
                  query: props.query,
                  command: props.command,
                },
                editor: props.editor,
              });

              const element = list.element as HTMLElement;
              element.style.position = "fixed";
              document.body.appendChild(element);
              place();
            },
            onUpdate: (props) => {
              clientRect = props.clientRect;
              list?.updateProps({
                items: props.items,
                query: props.query,
                command: props.command,
              });
              place();
            },
            onKeyDown: ({ event }) => {
              if (event.key === "Escape") return false;

              return (
                (
                  list?.ref as { onKeyDown?: (event: KeyboardEvent) => boolean }
                )?.onKeyDown?.(event) ?? false
              );
            },
            onExit: () => {
              clearTimeout(pending);
              (list?.element as HTMLElement | undefined)?.remove();
              list?.destroy();
              list = undefined;
            },
          };
        },
      }),
    ];
  },
});
