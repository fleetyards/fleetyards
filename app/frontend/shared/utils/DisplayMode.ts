// iOS Safari never matches the display-mode query for a Home Screen app and
// reports it through its own `navigator.standalone` instead.
export const isInstalledApp = (): boolean => {
  try {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      (navigator as Navigator & { standalone?: boolean }).standalone === true
    );
  } catch {
    return false;
  }
};
