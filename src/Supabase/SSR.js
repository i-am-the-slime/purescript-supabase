import { createServerClient as createServerClientSSR, createBrowserClient as createBrowserClientSSR, parseCookieHeader, serializeCookieHeader } from "@supabase/ssr";

export const createServerClientImpl = (url, key, opts) =>
  createServerClientSSR(url, key, opts);

export const createBrowserClientImpl = (url, key, _opts) =>
  createBrowserClientSSR(url, key);

export const parseCookieHeaderImpl = (header) =>
  parseCookieHeader(header);

export const serializeCookieHeaderImpl = (name, value, options) => {
  const cleaned = {};
  for (const [k, v] of Object.entries(options)) {
    if (v != null) cleaned[k] = v;
  }
  return serializeCookieHeader(name, value, cleaned);
};
