type TVideo = {
  videoId: string;
  type: "youtube";
  url: string;
};

interface TVideoParams extends TCollectionParams<undefined> {
  modelSlug: string;
}
