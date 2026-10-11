<script lang="ts" setup>
type Props = {
  src: string;
  title: string;
};

const props = defineProps<Props>();

const route = useRoute();
const router = useRouter();

/*
 * The tools are Rails engines rendering their own pages, so they are framed
 * rather than linked: a link leaves the admin, and the installed app has no
 * back button to return with.
 *
 * Where the frame has got to is kept in `?path=`, so a reload or a shared link
 * comes back to the same page. Only a path under the engine is taken from the
 * query, which keeps the frame from being pointed anywhere else.
 */
const pathFromQuery = () => {
  const path = route.query.path;

  return typeof path === "string" && /^\/(?!\/)/.test(path) ? path : "";
};

// Read once: the frame navigates itself, and a src following the query would
// reload it every time it reported where it went.
const initialSrc = `${props.src}${pathFromQuery()}`;

const frame = ref<HTMLIFrameElement | null>(null);

let resizeObserver: ResizeObserver | undefined;

/*
 * Sized to its content so the page scrolls as a whole, as every other admin
 * page does, instead of a scroll area inside one -- which on a phone leaves no
 * room to scroll the page around it. The height is dropped before measuring
 * because a document is never shorter than its frame, so a shorter page than
 * the last one could not shrink it otherwise.
 */
const fitContent = () => {
  const element = frame.value;
  const doc = element?.contentDocument;
  if (!element || !doc?.documentElement) return;

  element.style.height = "";
  element.style.height = `${doc.documentElement.scrollHeight}px`;
};

const onLoad = () => {
  const location = frame.value?.contentWindow?.location;
  if (!location) return;

  const href = `${location.pathname}${location.search}${location.hash}`;

  // A link out of the tool -- the admin login after a session ran out, say --
  // belongs in the window, not in a frame inside the admin.
  const insideEngine =
    location.pathname === props.src ||
    location.pathname.startsWith(`${props.src}/`);

  if (!insideEngine) {
    window.location.assign(href);
    return;
  }

  const path = href.slice(props.src.length);

  void router.replace({
    query: { ...route.query, path: path && path !== "/" ? path : undefined },
  });

  resizeObserver?.disconnect();
  const body = frame.value?.contentDocument?.body;
  if (body) {
    resizeObserver = new ResizeObserver(fitContent);
    resizeObserver.observe(body);
  }

  fitContent();
};

onBeforeUnmount(() => resizeObserver?.disconnect());
</script>

<template>
  <iframe
    ref="frame"
    :src="initialSrc"
    :title="title"
    class="engine-frame"
    data-test="engine-frame"
    @load="onLoad"
  />
</template>

<style lang="scss" scoped>
.engine-frame {
  display: block;
  width: 100%;
  min-height: 70vh;
  border: 0;
  border-radius: 4px;
}
</style>
