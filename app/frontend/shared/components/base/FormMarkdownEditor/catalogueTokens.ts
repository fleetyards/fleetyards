import { Extension, Node, mergeAttributes, type Editor } from "@tiptap/core";
import { VueRenderer } from "@tiptap/vue-3";
import { PluginKey } from "@tiptap/pm/state";
import Suggestion, { type SuggestionOptions } from "@tiptap/suggestion";
import { computePosition, flip, offset, shift } from "@floating-ui/dom";
import {
  catalogueLookup,
  catalogueSearch,
  type CatalogueTokenMatch,
} from "@/services/fyApi";
import {
  catalogueTokenIcon,
  catalogueTokenName,
  catalogueTokenPrefix,
  catalogueTokenText,
} from "@/shared/utils/CatalogueTokens";
import SuggestionList from "./CatalogueSuggestionList.vue";

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    catalogueToken: {
      insertCatalogueToken: (token: string, type?: string) => ReturnType;
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

  // `type` and `state` are what the lookup answered -- they drive the icon and
  // are never written to the markdown, which keeps only the token's text.
  addAttributes() {
    return {
      token: {
        default: "",
        parseHTML: (element) => element.getAttribute("data-catalogue-token"),
        renderHTML: (attributes) => ({
          "data-catalogue-token": attributes.token,
        }),
      },
      type: {
        default: null,
        parseHTML: (element) => element.getAttribute("data-type"),
        renderHTML: (attributes) =>
          attributes.type ? { "data-type": attributes.type } : {},
      },
      state: {
        default: "pending",
        parseHTML: (element) => element.getAttribute("data-state") ?? "pending",
        renderHTML: (attributes) => ({ "data-state": attributes.state }),
      },
    };
  },

  parseHTML() {
    return [{ tag: "span[data-catalogue-token]" }];
  },

  // Marked as it will read on the page: the resolved type's icon, then the
  // name in brackets. A token nothing resolves is plain text there, so here it
  // says so rather than looking like a link.
  renderHTML({ node, HTMLAttributes }) {
    const token = node.attrs.token as string;
    const unresolved = node.attrs.state === "unresolved";
    const name = catalogueTokenName(token);

    return [
      "span",
      mergeAttributes(HTMLAttributes, {
        class: `catalogue-token catalogue-token--chip${unresolved ? " catalogue-token--unresolved" : ""}`,
      }),
      [
        "i",
        {
          class: unresolved
            ? "fa-duotone fa-circle-question"
            : catalogueTokenIcon(
                (node.attrs.type as string | null) ??
                  catalogueTokenPrefix(token),
              ),
          "aria-hidden": "true",
        },
      ],
      unresolved ? name : `[${name}]`,
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
        (token, type) =>
        ({ commands }) =>
          commands.insertContent([
            {
              type: this.name,
              attrs: {
                token,
                type: type ?? null,
                state: type ? "resolved" : "pending",
              },
            },
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
            .insertCatalogueToken(props.token, props.type)
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

export type CatalogueLookup = (
  names: string[],
) => Promise<CatalogueTokenMatch[]>;

const defaultLookup: CatalogueLookup = async (names) =>
  (await catalogueLookup({ names })).items;

const LOOKUP_DELAY = 250;

// The lookup's own limit on names per request.
const LOOKUP_BATCH = 100;

// Resolves the document's tokens the way the page will, so each chip shows its
// real type's icon -- a token without a prefix could be any of three -- or
// that it will not link at all. The answers only mark the nodes: the markdown
// does not change, and the marking is kept out of the undo history.
export const CatalogueTokenResolution = Extension.create<
  { lookup: CatalogueLookup },
  { known: Map<string, string | null>; timer?: ReturnType<typeof setTimeout> }
>({
  name: "catalogueTokenResolution",

  addOptions() {
    return { lookup: defaultLookup };
  },

  addStorage() {
    return { known: new Map(), timer: undefined };
  },

  onCreate() {
    resolveTokens(this.editor, this.options.lookup, this.storage);
  },

  // Every change to the document, not only an edit: text loaded from outside
  // -- a new value, the source view switched back -- arrives without one.
  onTransaction({ transaction }) {
    if (!transaction.docChanged) return;

    resolveTokens(this.editor, this.options.lookup, this.storage);
  },

  onDestroy() {
    clearTimeout(this.storage.timer);
  },
});

type ResolutionStorage = {
  known: Map<string, string | null>;
  timer?: ReturnType<typeof setTimeout>;
};

const markKnown = (editor: Editor, known: Map<string, string | null>) => {
  if (editor.isDestroyed) return;

  const { tr } = editor.state;

  editor.state.doc.descendants((node, pos) => {
    if (node.type.name !== "catalogueToken") return;

    const token = node.attrs.token as string;
    if (!known.has(token)) return;

    const type = known.get(token) ?? null;
    const state = type ? "resolved" : "unresolved";

    if (node.attrs.type !== type || node.attrs.state !== state) {
      tr.setNodeMarkup(pos, undefined, { ...node.attrs, type, state });
    }
  });

  // What a token is changes how it looks, not the text: no undo step, and no
  // update -- one arriving while a new value loads would publish it as an edit.
  if (tr.docChanged) {
    tr.setMeta("addToHistory", false);
    tr.setMeta("preventUpdate", true);
    editor.view.dispatch(tr);
  }
};

const resolveTokens = (
  editor: Editor,
  lookup: CatalogueLookup,
  storage: ResolutionStorage,
) => {
  const unknown = new Set<string>();

  editor.state.doc.descendants((node) => {
    if (node.type.name !== "catalogueToken") return;

    const token = node.attrs.token as string;

    // A token picked from the search already knows what it is.
    if (
      node.attrs.state === "resolved" &&
      node.attrs.type &&
      !storage.known.has(token)
    ) {
      storage.known.set(token, node.attrs.type as string);
    }

    if (!storage.known.has(token)) unknown.add(token);
  });

  markKnown(editor, storage.known);

  if (!unknown.size) return;

  clearTimeout(storage.timer);
  storage.timer = setTimeout(() => {
    const names = [...unknown].sort();

    for (let start = 0; start < names.length; start += LOOKUP_BATCH) {
      const batch = names.slice(start, start + LOOKUP_BATCH);

      lookup(batch).then(
        (matches) => {
          const types = new Map(
            matches.map((match) => [match.token, match.type]),
          );
          batch.forEach((name) =>
            storage.known.set(name, types.get(name) ?? null),
          );
          markKnown(editor, storage.known);
        },
        () => undefined,
      );
    }
  }, LOOKUP_DELAY);
};
