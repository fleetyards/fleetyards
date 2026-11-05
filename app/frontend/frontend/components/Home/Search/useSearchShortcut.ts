import { useNavStore } from "@/shared/stores/nav";

// Ctrl+K on a Mac deletes to the end of the line in any text field.
const isMac = /Mac|iPhone|iPad/.test(navigator.platform);

export const SEARCH_SHORTCUT_LABEL = isMac ? "⌘K" : "Ctrl K";

export const SEARCH_SHORTCUT_ARIA = `/ ${isMac ? "Meta" : "Control"}+K`;

const isCommandK = (event: KeyboardEvent) =>
  event.key.toLowerCase() === "k" &&
  !event.shiftKey &&
  !event.altKey &&
  (isMac ? event.metaKey && !event.ctrlKey : event.ctrlKey && !event.metaKey);

const isSlash = (event: KeyboardEvent) =>
  event.key === "/" && !event.metaKey && !event.ctrlKey && !event.altKey;

const within = (event: KeyboardEvent, selector: string) =>
  !!(event.target as Element | null)?.closest?.(selector);

export const useSearchShortcut = (focusSearch: () => void) => {
  const navStore = useNavStore();

  const onKeydown = (event: KeyboardEvent) => {
    if (event.defaultPrevented) {
      return;
    }

    // The search sits behind whatever has taken over the screen, the mobile
    // drawer included.
    if (document.querySelector('[aria-modal="true"]') || !navStore.collapsed) {
      return;
    }

    const wanted = isCommandK(event)
      ? !within(event, "[contenteditable]")
      : isSlash(event) &&
        !within(
          event,
          'input, textarea, select, [contenteditable], [role="combobox"], [role="listbox"]',
        );

    if (wanted) {
      event.preventDefault();
      focusSearch();
    }
  };

  onMounted(() => document.addEventListener("keydown", onKeydown));
  onBeforeUnmount(() => document.removeEventListener("keydown", onKeydown));
};
