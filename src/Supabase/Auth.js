export const signUpImpl = (client, opts) => client.auth.signUp(opts);

export const signInWithPasswordImpl = (client, opts) => client.auth.signInWithPassword(opts);

export const signInWithOtpImpl = (client, opts) => client.auth.signInWithOtp(opts);

export const verifyOtpImpl = (client, opts) => client.auth.verifyOtp(opts);

export const signInWithOAuthImpl = (client, opts) => client.auth.signInWithOAuth(opts);

export const signInWithIdTokenImpl = (client, opts) => client.auth.signInWithIdToken(opts);

export const signInWithSSOImpl = (client, opts) => client.auth.signInWithSSO(opts);

export const signInAnonymouslyImpl = (client) => client.auth.signInAnonymously();

export const signOutImpl = (client) => client.auth.signOut();

export const updateUserImpl = (client, attrs) => client.auth.updateUser(attrs);

export const resetPasswordForEmailImpl = (client, email) =>
  client.auth.resetPasswordForEmail(email);

export const getSessionImpl = (client) => client.auth.getSession();

export const getUserImpl = (client) => client.auth.getUser();

export const refreshSessionImpl = (client) => client.auth.refreshSession();

export const setSessionImpl = (client, tokens) => client.auth.setSession(tokens);

export const exchangeCodeForSessionImpl = (client, code) =>
  client.auth.exchangeCodeForSession(code);

export const reauthenticateImpl = (client) => client.auth.reauthenticate();

export const onAuthStateChangeImpl = (client, handler) =>
  client.auth.onAuthStateChange((_event, session) => handler(session));

export const invokeImpl = (client, functionName, opts) =>
  client.functions.invoke(functionName, opts);

export const functionsSetAuthImpl = (client, token) => client.functions.setAuth(token);

export const channelImpl = (channelName, client) => client.channel(channelName);

export const getChannelsImpl = (client) => client.getChannels();

export const removeChannelImpl = (client, channel) => client.removeChannel(channel);

export const removeAllChannelsImpl = (client) => client.removeAllChannels();
