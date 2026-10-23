import { createClient } from "@supabase/supabase-js";
import * as SecureStore from "expo-secure-store";

import { env, envConfigurado } from "./env";
import type { SupabaseClient } from "@supabase/supabase-js";

const secureStorage = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};

let client: SupabaseClient | undefined;

export function getSupabaseClient(): SupabaseClient {
  if (!envConfigurado) {
    throw new Error("Supabase no está configurado. Revisa las variables EXPO_PUBLIC_*.");
  }

  client ??= createClient(env.supabaseUrl, env.supabaseAnonKey, {
    auth: {
      storage: secureStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  });

  return client;
}
