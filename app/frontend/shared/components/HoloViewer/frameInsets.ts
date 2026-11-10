export type HoloFrameInsets = {
  top: number;
  right: number;
  bottom: number;
  left: number;
};

// Covered past this, the frame is too small a hole to fit a ship into, and the
// model takes the whole frame after all.
const MIN_CLEAR_SHARE = 0.25;

/**
 * The part of a frame nothing covers: its size, and how far the camera's view
 * has to shift for the frame's centre to land on the clear part's centre.
 */
export const clearFrame = (
  width: number,
  height: number,
  insets?: HoloFrameInsets,
) => {
  const clearWidth = insets ? width - insets.left - insets.right : width;
  const clearHeight = insets ? height - insets.top - insets.bottom : height;

  if (
    !insets ||
    clearWidth < width * MIN_CLEAR_SHARE ||
    clearHeight < height * MIN_CLEAR_SHARE
  ) {
    return { width, height, offsetX: 0, offsetY: 0 };
  }

  return {
    width: clearWidth,
    height: clearHeight,
    offsetX: width / 2 - (insets.left + clearWidth / 2),
    offsetY: height / 2 - (insets.top + clearHeight / 2),
  };
};
