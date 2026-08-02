import Clipboard from "clipboard";

// Legacy execCommand-based copy. Kept as a fallback for insecure contexts
// (or browsers) where the async Clipboard API is unavailable.
const legacyCopyText = (text: string, container?: Element) =>
  new Promise((resolve, reject) => {
    const fakeElement = document.createElement("button");
    const clipboard = new Clipboard(fakeElement, {
      text() {
        return text;
      },
      action() {
        return "copy";
      },
      container: typeof container === "object" ? container : document.body,
    });
    clipboard.on("success", (e) => {
      clipboard.destroy();
      resolve(e);
    });
    clipboard.on("error", (e) => {
      clipboard.destroy();
      reject(new Error(`Failed to copy text: ${e.text}`));
    });
    document.body.appendChild(fakeElement);
    fakeElement.click();
    document.body.removeChild(fakeElement);
  });

const copyText = function copyText(text: string, container?: Element) {
  // Prefer the async Clipboard API: unlike execCommand it does not rely on a
  // DOM selection or focus, so it also works from within focus-trapping
  // overlays such as the PhotoSwipe image gallery.
  if (navigator.clipboard?.writeText) {
    return navigator.clipboard
      .writeText(text)
      .catch(() => legacyCopyText(text, container));
  }

  return legacyCopyText(text, container);
};

export default copyText;
