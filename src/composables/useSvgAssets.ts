import { ref } from "vue";
import { supabase } from "../services/supabase";
import type { SvgAsset } from "../types";

// ─────────────────────────────────────────────────────────────────────────────
//  Singleton state — defined at MODULE level so every component that calls
//  useSvgAssets() shares the exact same refs.
//
//  Previously these were declared inside the exported function, meaning each
//  call got its own independent `loading`, `assets`, and `fetchGeneration`.
//  That caused the classic "loading stuck at true" bug: when a new fetch
//  started (e.g. after a tab-switch visibilitychange), it incremented a
//  *different* counter from the one the old in-flight promise was checking,
//  so the finally-block guard `if (gen === fetchGeneration)` never matched
//  and `loading.value` was never set back to false.
// ─────────────────────────────────────────────────────────────────────────────
const assets = ref<SvgAsset[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);

// Generation counter — incremented on every new fetch call.
// The in-flight promise captures its own generation at start; if a newer
// fetch has begun by the time the promise resolves, the stale result is
// silently discarded and, crucially, `loading` is NOT reset to false by the
// stale promise.
let fetchGeneration = 0;

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: ensure the Supabase client holds a fresh, non-expired JWT before
//  any mutating operation.
//
//  getSession() triggers the built-in token refresh when the access token is
//  within its refresh window (last ~60 s by default).  Using getUser() alone
//  makes a network round-trip to the auth server but does NOT update the
//  stored token, so we deliberately use getSession() here.
// ─────────────────────────────────────────────────────────────────────────────
async function ensureFreshSession(): Promise<void> {
  // Race getSession() against a timeout to prevent deadlock.
  // Supabase gotrue-js v2 uses navigator.locks internally; when the browser
  // tab was backgrounded the lock may still be held by a stale callback,
  // causing getSession() to hang forever.  A 5-second timeout ensures the
  // UI never freezes — if the timeout fires we fall back to reading the
  // session from localStorage synchronously.
  let session: unknown = null;

  try {
    const result = await Promise.race([
      supabase.auth.getSession(),
      new Promise<never>((_resolve, reject) =>
        setTimeout(() => reject(new Error("ensureFreshSession timeout")), 5000),
      ),
    ]);
    session = result?.data?.session ?? null;
  } catch {
    // Timeout or network error — try localStorage as a synchronous fallback.
    try {
      const storageKey = `sb-${new URL(import.meta.env.VITE_SUPABASE_URL).hostname.split(".")[0]}-auth-token`;
      const raw = localStorage.getItem(storageKey);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed?.access_token) {
          // A token exists in storage; assume it's still usable.
          // If it's truly expired the subsequent DB query will fail with an
          // RLS error, which is better than freezing the entire UI.
          return;
        }
      }
    } catch {
      // localStorage unavailable or parse error — fall through to throw
    }
  }

  if (!session) {
    throw new Error("เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: merge creator profile info into a list of raw asset rows.
//  Makes a single extra query for all unique user_ids — avoids N+1 queries.
// ─────────────────────────────────────────────────────────────────────────────
async function attachCreators(rawAssets: SvgAsset[]): Promise<SvgAsset[]> {
  if (!rawAssets.length) return rawAssets;

  const userIds = [...new Set(rawAssets.map((a) => a.user_id))];

  const { data: profiles } = await supabase
    .from("svgbox_profiles")
    .select("id, username, display_name")
    .in("id", userIds);

  const profileMap = new Map(
    (profiles ?? []).map(
      (p: {
        id: string;
        username: string | null;
        display_name: string | null;
      }) => [
        p.id,
        { id: p.id, username: p.username, display_name: p.display_name },
      ],
    ),
  );

  return rawAssets.map((a) => ({
    ...a,
    creator: profileMap.get(a.user_id) ?? null,
  }));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Composable — exposes the shared singleton state + async actions.
//  Safe to call from any number of components simultaneously.
// ─────────────────────────────────────────────────────────────────────────────
export function useSvgAssets() {
  // ── READ ────────────────────────────────────────────────────────────────

  /**
   * Fetch all SVG assets visible to the current user.
   *
   * Visibility rules (enforced by RLS + this client filter):
   *   - guest  : only status='approved' AND is_private=false
   *   - user   : everything they own + approved public from others
   *   - admin  : every row regardless of status/visibility
   *
   * Attaches creator profile info (username, display_name) to each asset
   * using a single batched profile query — no N+1.
   */
  const fetchAll = async (search?: string, category?: string, tag?: string) => {
    const gen = ++fetchGeneration;
    loading.value = true;
    error.value = null;

    try {
      let query = supabase
        .from("svgbox_assets")
        .select("*")
        .order("created_at", { ascending: false });

      if (search) query = query.ilike("name", `%${search}%`);
      if (category) query = query.eq("category", category);
      if (tag) query = query.contains("tags", [tag]);

      const { data, error: err } = await query;

      // A newer fetch has already started — discard this stale result without
      // touching loading (the newer fetch will manage it).
      if (gen !== fetchGeneration) return;

      if (err) throw err;

      const withCreators = await attachCreators((data ?? []) as SvgAsset[]);

      // Check generation again AFTER attachCreators — it is an async call that
      // makes its own DB query.  A newer fetch may have started while we were
      // waiting for the profile lookup, and we must not overwrite its results.
      if (gen !== fetchGeneration) return;

      assets.value = withCreators;
    } catch (e: unknown) {
      if (gen !== fetchGeneration) return;
      error.value = e instanceof Error ? e.message : "ไม่สามารถโหลด SVG ได้";
    } finally {
      // Only the most recent fetch may clear the loading flag.
      if (gen === fetchGeneration) {
        loading.value = false;
      }
    }
  };

  /**
   * Fetch all SVG assets belonging to a specific user (Dashboard).
   * Also attaches creator info for consistency (useful when cards are shared).
   */
  const fetchByUser = async (userId: string) => {
    const gen = ++fetchGeneration;
    loading.value = true;
    error.value = null;

    try {
      const { data, error: err } = await supabase
        .from("svgbox_assets")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

      if (gen !== fetchGeneration) return;

      if (err) throw err;

      const withCreators = await attachCreators((data ?? []) as SvgAsset[]);

      // Check generation again AFTER attachCreators — same reasoning as fetchAll.
      if (gen !== fetchGeneration) return;

      assets.value = withCreators;
    } catch (e: unknown) {
      if (gen !== fetchGeneration) return;
      error.value =
        e instanceof Error ? e.message : "ไม่สามารถโหลด SVG ของคุณได้";
    } finally {
      if (gen === fetchGeneration) {
        loading.value = false;
      }
    }
  };

  /**
   * Fetch a single SVG asset by id.
   * Includes creator profile info for the detail page.
   * Also increments view_count via RPC (fire-and-forget).
   */
  const fetchById = async (id: string): Promise<SvgAsset | null> => {
    const { data, error: err } = await supabase
      .from("svgbox_assets")
      .select("*")
      .eq("id", id)
      .single();

    if (err || !data) return null;

    const { data: profile } = await supabase
      .from("svgbox_profiles")
      .select("id, username, display_name")
      .eq("id", data.user_id)
      .maybeSingle();

    // Increment view_count — fire-and-forget, don't block render.
    void (async () => {
      try {
        await supabase.rpc("svgbox_increment_view_count", { asset_id: id });
      } catch {
        // non-critical — silently ignore
      }
    })();

    return {
      ...data,
      creator: profile
        ? {
            id: profile.id,
            username: profile.username,
            display_name: profile.display_name,
          }
        : null,
    } as SvgAsset;
  };

  // ── WRITE ──────────────────────────────────────────────────────────────

  /**
   * Insert a new SVG asset.
   * Calls ensureFreshSession() first so the Supabase client always sends a
   * valid, non-expired JWT and avoids silent RLS violations.
   */
  const create = async (
    asset: Omit<
      SvgAsset,
      "id" | "created_at" | "updated_at" | "view_count" | "creator"
    >,
  ): Promise<SvgAsset> => {
    await ensureFreshSession();

    const { data, error: err } = await supabase
      .from("svgbox_assets")
      .insert(asset)
      .select()
      .single();

    if (err) {
      if (
        err.message?.toLowerCase().includes("jwt") ||
        err.message?.toLowerCase().includes("auth") ||
        err.code === "42501"
      ) {
        throw new Error(
          "ไม่มีสิทธิ์บันทึก — กรุณารีเฟรชหน้าแล้วลองใหม่ หรือเข้าสู่ระบบอีกครั้ง",
        );
      }
      throw err;
    }

    return data as SvgAsset;
  };

  /**
   * Update an existing SVG asset.
   * Also refreshes the session before mutating.
   */
  const update = async (
    id: string,
    updates: Partial<Omit<SvgAsset, "creator">>,
  ): Promise<void> => {
    await ensureFreshSession();

    const { error: err } = await supabase
      .from("svgbox_assets")
      .update(updates)
      .eq("id", id);

    if (err) throw err;
  };

  /**
   * Delete an SVG asset by id.
   * Also refreshes the session before mutating.
   */
  const remove = async (id: string): Promise<void> => {
    await ensureFreshSession();

    const { error: err } = await supabase
      .from("svgbox_assets")
      .delete()
      .eq("id", id);

    if (err) throw err;
  };

  /**
   * Toggle the is_favorite flag on an asset.
   * Only the asset owner (or admin) can toggle — enforced by RLS.
   */
  const toggleFavorite = async (
    id: string,
    current: boolean,
  ): Promise<void> => {
    await update(id, { is_favorite: !current });
  };

  // ── ADMIN ─────────────────────────────────────────────────────────────

  /**
   * Admin only — review an SVG asset (approve / reject / set public).
   * Delegates to the SECURITY DEFINER function svgbox_admin_review_asset
   * so the trigger svgbox_assets_guard_approval does not block admin updates.
   */
  const adminReview = async (
    id: string,
    newStatus: "pending" | "approved" | "rejected",
    newIsPrivate: boolean,
  ): Promise<void> => {
    await ensureFreshSession();
    const { error: err } = await supabase.rpc("svgbox_admin_review_asset", {
      target_asset_id: id,
      new_status: newStatus,
      new_is_private: newIsPrivate,
    });
    if (err) throw err;
  };

  return {
    // Shared singleton state
    assets,
    loading,
    error,
    // Actions
    fetchAll,
    fetchByUser,
    fetchById,
    create,
    update,
    remove,
    toggleFavorite,
    adminReview,
  };
}
