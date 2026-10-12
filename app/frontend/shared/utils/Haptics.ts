/*
 * A short, light tick for a gesture that has landed: a held row turning into a
 * selection, a swiped row passing the point where letting go will act.
 *
 * Android only. Safari ships no Vibration API on any platform and WebKit
 * opposes it, so every browser on an iPhone stays silent; the hidden-switch
 * workaround web pages used there stopped ticking from script in iOS 26.5, and
 * what remains of it is too fragile to build on. Native haptics on iOS are one
 * of the reasons kept for a native app.
 */
export const hapticTick = () => {
  if (typeof navigator !== "undefined" && "vibrate" in navigator) {
    navigator.vibrate(10);
  }
};
