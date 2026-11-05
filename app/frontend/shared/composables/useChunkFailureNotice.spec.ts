import { nextTick } from "vue";
import { createPinia, setActivePinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { chunkLoadFailures } from "@/shared/utils/ChunkReload";
import { useChunkFailureNotice } from "./useChunkFailureNotice";

describe("useChunkFailureNotice", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    chunkLoadFailures.value = 0;
  });

  afterEach(() => {
    chunkLoadFailures.value = 0;
  });

  it("stays quiet while chunks load", () => {
    useChunkFailureNotice();

    expect(useNotificationsStore().messages).toHaveLength(0);
  });

  it("keeps a notice up once a chunk could not be recovered", async () => {
    useChunkFailureNotice();

    chunkLoadFailures.value = 1;
    await nextTick();

    const [message] = useNotificationsStore().messages;
    expect(message?.persist).toBe(true);
    expect(message?.timeout).toBe(false);
  });

  it("brings a dismissed notice back on the next failure", async () => {
    useChunkFailureNotice();
    chunkLoadFailures.value = 1;
    await nextTick();
    const store = useNotificationsStore();
    store.hideTagged(() => true);

    chunkLoadFailures.value = 2;
    await nextTick();

    expect(store.messages.filter((message) => message.visible)).toHaveLength(1);
  });

  it("shows the notice for a failure from before the app mounted", () => {
    chunkLoadFailures.value = 1;

    useChunkFailureNotice();

    expect(useNotificationsStore().messages).toHaveLength(1);
  });
});
