import { defineStore } from "pinia";

const mobileBreakpoint = 992;

// The test the navigation's stylesheets make with `max-width:
// $desktop-breakpoint`: the viewport including its scrollbar, with 992px itself
// already mobile. Measured any other way, the two disagree at the boundary --
// the CSS has moved the navigation off-canvas while the scripts still lay out
// for a desktop. (The `min-width: 992px` rules elsewhere overlap these by that
// one pixel in the stylesheets themselves.)
const mobileQuery = `(max-width: ${mobileBreakpoint}px)`;

export const isMobileWidth = () => {
  if (typeof window === "undefined") return false;

  // Without matchMedia -- jsdom -- only the document's own width is there.
  if (typeof window.matchMedia !== "function") {
    return document.documentElement.clientWidth < mobileBreakpoint;
  }

  return window.matchMedia(mobileQuery).matches;
};

type MobileState = {
  mobile: boolean;
};

export const useMobileStore = defineStore("mobile", {
  state: (): MobileState => ({
    mobile: isMobileWidth(),
  }),
});
