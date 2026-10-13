// dom-to-image ships no typings; this is the part of its API the app calls.
declare module "dom-to-image" {
  type Options = {
    bgcolor?: string;
    width?: number;
    height?: number;
    style?: Record<string, string>;
    quality?: number;
    cacheBust?: boolean;
  };

  const domtoimage: {
    toSvg(node: Node, options?: Options): Promise<string>;
  };

  export default domtoimage;
}
