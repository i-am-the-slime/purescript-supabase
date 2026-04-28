export const sendImpl = (what, channel) => channel.send(what);

export const onImpl = (listenType, filter, callback, channel) =>
  channel.on(listenType, filter, callback);

export const subscribeImpl = (callback, timeout, channel) =>
  channel.subscribe(callback, timeout);

export const unsubscribeImpl = (channel) => channel.unsubscribe();

export const teardownImpl = (channel) => channel.teardown();

export const trackImpl = (payload, channel) => channel.track(payload);

export const untrackImpl = (channel) => channel.untrack();

export const presenceStateImpl = (channel) => channel.presenceState();
