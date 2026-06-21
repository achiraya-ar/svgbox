import { createRouter, createWebHistory } from "vue-router";
import { supabase } from "../services/supabase";

// Disable the browser's native scroll restoration so that Vue Router
// (and our component-level scroll restoration) is the single source of
// truth.  Without this the browser may scroll to a previously-focused
// element (e.g. the search bar) on a hard refresh.
if (typeof window !== "undefined" && "scrollRestoration" in window.history) {
  window.history.scrollRestoration = "manual";
}

const routes = [
  {
    path: "/",
    component: () => import("../pages/HomePage.vue"),
    name: "home",
  },
  {
    path: "/login",
    component: () => import("../pages/LoginPage.vue"),
    name: "login",
  },
  {
    path: "/register",
    component: () => import("../pages/RegisterPage.vue"),
    name: "register",
  },
  {
    path: "/collection",
    component: () => import("../pages/DashboardPage.vue"),
    name: "collection",
    meta: { requiresAuth: true },
  },
  {
    path: "/svg/:id",
    component: () => import("../pages/SvgDetailPage.vue"),
    name: "svg-detail",
  },
  {
    path: "/profile/:username",
    component: () => import("../pages/ProfilePage.vue"),
    name: "profile",
  },
  {
    path: "/settings",
    component: () => import("../pages/SettingsPage.vue"),
    name: "settings",
    meta: { requiresAuth: true },
  },
  {
    path: "/admin",
    component: () => import("../pages/AdminPage.vue"),
    name: "admin",
    meta: { requiresAuth: true, requiresAdmin: true },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(_to, _from, savedPosition) {
    // savedPosition is provided on browser back/forward (popstate).
    // List pages (home, dashboard, admin) override this themselves after
    // async data finishes loading, so this acts as a reliable fallback for
    // all other pages (settings, login, profile, svg-detail, …).
    if (savedPosition) {
      return savedPosition;
    }
    return { top: 0 };
  },
});

router.beforeEach(async (to) => {
  if (to.meta.requiresAuth) {
    // Use getSession() instead of getUser() to check auth.
    // getUser() makes a network round-trip to the auth server, but more
    // critically, both getUser() and getSession() acquire an internal
    // navigator.lock in Supabase gotrue-js v2.  When the browser tab is
    // backgrounded and then returns, the lock may still be held by a
    // stale onAuthStateChange callback or a pending token refresh.
    // Calling getUser() (or getSession()) without a timeout here will
    // deadlock — the router guard never resolves and the entire UI freezes.
    //
    // We race getSession() against a 3-second timeout.  On timeout we
    // fall back to reading the session from localStorage synchronously,
    // which cannot deadlock.
    let session: { user: { id: string } } | null = null;

    try {
      const result = await Promise.race([
        supabase.auth.getSession(),
        new Promise<never>((_resolve, reject) =>
          setTimeout(() => reject(new Error("guard session timeout")), 3000),
        ),
      ]);
      session = result?.data?.session ?? null;
    } catch {
      // Timeout — try to read session from localStorage as a fallback.
      // This is synchronous and won't deadlock.
      try {
        const storageKey = `sb-${new URL(import.meta.env.VITE_SUPABASE_URL).hostname.split(".")[0]}-auth-token`;
        const raw = localStorage.getItem(storageKey);
        if (raw) {
          const parsed = JSON.parse(raw);
          if (parsed?.user?.id) {
            session = { user: { id: parsed.user.id } };
          }
        }
      } catch {
        // localStorage not available or parse error — treat as not logged in
      }
    }

    if (!session?.user) {
      return { name: "login" };
    }

    if (to.meta.requiresAdmin) {
      const { data: profile } = await supabase
        .from("svgbox_profiles")
        .select("role")
        .eq("id", session.user.id)
        .single();

      if (profile?.role !== "admin") {
        return { name: "collection" };
      }
    }
  }
});

export default router;
