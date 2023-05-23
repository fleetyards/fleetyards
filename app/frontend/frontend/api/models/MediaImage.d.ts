interface FyMediaImage {
  source: string;
  small: string;
  medium: string;
  large: string;
}

interface FyMediaViewImage extends FyMediaImage {
  xlarge: string;
  height: number;
  width: number;
}
