'use client'
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createBrowserClient as createBrowserSupabaseClient } from "@supabase/ssr";

export const createClientImpl = (url, key) => createSupabaseClient(url, key);

export const createBrowserClientImpl = (url, key) => createBrowserSupabaseClient(url, key);

export const createBrowserClientWithOptionsImpl = (options) =>
  createBrowserSupabaseClient(options);
