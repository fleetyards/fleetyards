import { isSafeMarkdownHref } from "@/shared/utils/MarkdownUrls";

// Confirm and toast texts are translations with a little markup, but their
// placeholders are filled with names other players chose, and neither i18n
// library escapes those. Only the tags the translations use survive, with no
// attributes but a link's address and target and a span's class.
const ALLOWED_TAGS = new Set([
  "A",
  "B",
  "BR",
  "EM",
  "I",
  "P",
  "SPAN",
  "STRONG",
]);

const DROPPED_TAGS = new Set(["SCRIPT", "STYLE", "TEMPLATE"]);

const ALLOWED_ATTRIBUTES: Record<string, string[]> = {
  A: ["href", "target"],
  SPAN: ["class"],
};

const clean = (source: Node, target: Node, doc: Document) => {
  source.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      target.appendChild(doc.createTextNode(node.textContent || ""));
      return;
    }

    if (node.nodeType !== Node.ELEMENT_NODE) return;

    const element = node as Element;

    if (DROPPED_TAGS.has(element.tagName)) return;

    if (!ALLOWED_TAGS.has(element.tagName)) {
      clean(element, target, doc);
      return;
    }

    const copy = doc.createElement(element.tagName);

    (ALLOWED_ATTRIBUTES[element.tagName] || []).forEach((name) => {
      const value = element.getAttribute(name);

      if (value === null) return;
      if (name === "href" && !isSafeMarkdownHref(value)) return;

      copy.setAttribute(name, value);
    });

    if (copy.tagName === "A" && copy.getAttribute("target") === "_blank") {
      copy.setAttribute("rel", "noopener noreferrer");
    }

    clean(element, copy, doc);
    target.appendChild(copy);
  });
};

export const sanitizeHtml = (html: string) => {
  const doc = new DOMParser().parseFromString(html, "text/html");
  const container = doc.createElement("div");

  clean(doc.body, container, doc);

  return container.innerHTML;
};
