<template>
    <DefaultLayout>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 font-prompt">
            <!-- Header Row -->
            <div
                class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8"
            >
                <div>
                    <h1
                        class="text-2xl font-semibold text-textprimary font-prompt"
                    >
                        {{ t("dashboard.title") }}
                        <span class="text-accent">{{ displayName }}</span>
                    </h1>
                    <p class="text-sm text-textsecondary font-prompt mt-1">
                        {{ t("dashboard.titleHighlight") }}
                    </p>
                </div>

                <button
                    @click="uploadModalOpen = true"
                    class="inline-flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 shadow-sm hover:shadow-md transition-all duration-200"
                >
                    <Plus :size="18" />
                    {{ t("dashboard.uploadBtn") }}
                </button>
            </div>

            <!-- Stats Row -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center"
                        >
                            <Layers :size="18" class="text-accent" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ assets.length }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t("dashboard.stats.mySvgs") }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-red-50 flex items-center justify-center"
                        >
                            <Heart :size="18" class="text-red-400" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ favoriteCount }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t("dashboard.stats.favorites") }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-soft flex items-center justify-center"
                        >
                            <Tag :size="18" class="text-secondary" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ uniqueCategories.length }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t("dashboard.stats.categories") }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-soft flex items-center justify-center"
                        >
                            <Hash :size="18" class="text-secondary" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ uniqueTagCount }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t("dashboard.stats.tags") }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <div class="flex gap-2 mb-6">
                <button
                    @click="activeTab = 'mine'"
                    :class="[
                        'flex items-center gap-1.5 px-5 py-2.5 rounded-2xl text-sm font-prompt font-medium transition-all duration-200',
                        activeTab === 'mine'
                            ? 'bg-accent text-white shadow-sm'
                            : 'bg-surface text-textprimary border border-border hover:border-accent hover:text-accent',
                    ]"
                >
                    <Layers :size="16" />
                    {{ t("dashboard.tabs.mySvgs") }}
                    <span class="text-xs opacity-70"
                        >({{ assets.length }})</span
                    >
                </button>
                <button
                    @click="activeTab = 'favorites'"
                    :class="[
                        'flex items-center gap-1.5 px-5 py-2.5 rounded-2xl text-sm font-prompt font-medium transition-all duration-200',
                        activeTab === 'favorites'
                            ? 'bg-accent text-white shadow-sm'
                            : 'bg-surface text-textprimary border border-border hover:border-accent hover:text-accent',
                    ]"
                >
                    <Heart :size="16" />
                    {{ t("dashboard.tabs.favorites") }}
                    <span class="text-xs opacity-70"
                        >({{ favoriteIds.size }})</span
                    >
                </button>
            </div>

            <!-- Filter & Search Row -->
            <div class="flex flex-col sm:flex-row gap-3 mb-6">
                <!-- Search -->
                <div class="relative flex-1">
                    <Search
                        :size="16"
                        class="absolute left-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                    />
                    <input
                        v-model="searchQuery"
                        type="text"
                        :placeholder="t('dashboard.searchPlaceholder')"
                        class="w-full pl-9 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                    />
                </div>

                <!-- Category Filter -->
                <div class="relative">
                    <select
                        v-model="selectedCategory"
                        class="pl-4 pr-8 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 appearance-none transition-all duration-200 min-w-[160px]"
                    >
                        <option value="">
                            {{ t("dashboard.categoryAll") }}
                        </option>
                        <option
                            v-for="cat in allCategories"
                            :key="cat"
                            :value="cat"
                        >
                            {{ cat }}
                        </option>
                    </select>
                    <ChevronDown
                        :size="14"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                    />
                </div>

                <!-- Sort (mine tab only) -->
                <div v-if="activeTab === 'mine'" class="relative">
                    <select
                        v-model="sortOrder"
                        class="pl-4 pr-8 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 appearance-none transition-all duration-200 min-w-[160px]"
                    >
                        <option value="newest">
                            {{ t("dashboard.sort.newest") }}
                        </option>
                        <option value="oldest">
                            {{ t("dashboard.sort.oldest") }}
                        </option>
                        <option value="name">
                            {{ t("dashboard.sort.az") }}
                        </option>
                    </select>
                    <ChevronDown
                        :size="14"
                        class="absolute right-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                    />
                </div>
            </div>

            <!-- Loading Skeleton -->
            <div
                v-if="loading || favLoading"
                class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
            >
                <div
                    v-for="i in 8"
                    :key="i"
                    class="bg-surface rounded-2xl border border-border p-4 animate-pulse"
                >
                    <div class="w-full h-32 bg-soft rounded-xl mb-3"></div>
                    <div class="h-4 bg-soft rounded-full w-3/4 mb-2"></div>
                    <div class="h-3 bg-soft rounded-full w-1/2"></div>
                </div>
            </div>

            <!-- Error State -->
            <div
                v-else-if="error"
                class="flex flex-col items-center justify-center py-20 text-center"
            >
                <div
                    class="w-16 h-16 rounded-2xl bg-red-50 flex items-center justify-center mb-4"
                >
                    <AlertCircle :size="28" class="text-red-400" />
                </div>
                <h3 class="text-lg font-semibold text-primary font-prompt mb-1">
                    {{ t("dashboard.error.title") }}
                </h3>
                <p class="text-sm text-textsecondary font-prompt mb-5">
                    {{ error }}
                </p>
                <button
                    @click="loadAssets()"
                    class="px-5 py-2.5 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 transition-all duration-200"
                >
                    {{ t("dashboard.error.retry") }}
                </button>
            </div>

            <!-- SVG Grid — Mine Tab -->
            <div
                v-else-if="activeTab === 'mine' && filteredAssets.length"
                class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
            >
                <SVGCard
                    v-for="asset in filteredAssets"
                    :key="asset.id"
                    :asset="asset"
                    :current-user-id="user?.id"
                    :user-favorited="isFavorited(asset.id)"
                    @favorite="handleFavorite"
                    @download="handleDownload"
                    @copy="handleCopy"
                />
            </div>

            <!-- SVG Grid — Favorites Tab -->
            <div
                v-else-if="
                    activeTab === 'favorites' && filteredFavoriteAssets.length
                "
                class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
            >
                <SVGCard
                    v-for="asset in filteredFavoriteAssets"
                    :key="asset.id"
                    :asset="asset"
                    :current-user-id="user?.id"
                    :user-favorited="isFavorited(asset.id)"
                    @favorite="handleFavorite"
                    @download="handleDownload"
                    @copy="handleCopy"
                />
            </div>

            <!-- Empty State -->
            <div
                v-else
                class="flex flex-col items-center justify-center py-24 text-center"
            >
                <div
                    class="w-20 h-20 rounded-2xl bg-soft flex items-center justify-center mb-5"
                >
                    <PackageOpen :size="36" class="text-textsecondary" />
                </div>
                <h3 class="text-xl font-semibold text-primary font-prompt mb-2">
                    {{
                        activeTab === "favorites" &&
                        !(searchQuery || selectedCategory)
                            ? t("dashboard.emptyFavorites.title")
                            : searchQuery || selectedCategory
                              ? t("home.empty.title")
                              : t("dashboard.empty.title")
                    }}
                </h3>
                <p class="text-sm text-textsecondary font-prompt max-w-xs mb-6">
                    {{
                        activeTab === "favorites" &&
                        !(searchQuery || selectedCategory)
                            ? t("dashboard.emptyFavorites.description")
                            : searchQuery || selectedCategory
                              ? t("home.empty.description")
                              : t("dashboard.empty.description")
                    }}
                </p>
                <button
                    v-if="
                        activeTab === 'mine' &&
                        !searchQuery &&
                        !selectedCategory
                    "
                    @click="uploadModalOpen = true"
                    class="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 shadow-sm hover:shadow-md transition-all duration-200"
                >
                    <Plus :size="18" />
                    {{ t("dashboard.empty.uploadFirst") }}
                </button>
                <button
                    v-else-if="searchQuery || selectedCategory"
                    @click="clearFilters()"
                    class="px-5 py-2.5 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 transition-all duration-200"
                >
                    {{ t("home.empty.clearFilters") }}
                </button>
            </div>
        </div>

        <!-- Upload Modal -->
        <UploadModal
            v-if="user"
            v-model="uploadModalOpen"
            :user-id="user.id"
            @uploaded="handleUploaded"
        />

        <!-- Download menu (shared for all cards on this page) -->
        <DownloadMenu
            v-if="downloadAsset"
            v-model="downloadMenuOpen"
            :svg-code="downloadAsset.svg_code"
            :filename="downloadAsset.name"
            @downloaded="showToast('Downloaded', 'success')"
        />

        <!-- Toast -->
        <ToastNotification
            v-if="toast.message"
            :message="toast.message"
            :type="toast.type"
            @dismiss="toast.message = ''"
        />
    </DefaultLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { useI18n } from "../composables/useI18n";
import {
    Plus,
    Layers,
    Heart,
    Tag,
    Hash,
    Search,
    ChevronDown,
    AlertCircle,
    PackageOpen,
} from "lucide-vue-next";
import DefaultLayout from "../layouts/DefaultLayout.vue";
import SVGCard from "../components/SVGCard.vue";
import UploadModal from "../components/UploadModal.vue";
import ToastNotification from "../components/ToastNotification.vue";
import DownloadMenu from "../components/DownloadMenu.vue";
import type { SvgAsset } from "../types";
import { useAuth } from "../composables/useAuth";
import { useSvgAssets } from "../composables/useSvgAssets";
import { useScrollRestoration } from "../composables/useScrollRestoration";
import { useFavorites } from "../composables/useFavorites";

const { user, refreshSession } = useAuth();
const { t } = useI18n();
const { assets, loading, error, fetchByUser, toggleFavorite } = useSvgAssets();
const {
    favoriteAssets,
    favoriteIds,
    favLoading,
    fetchFavoriteAssets,
    isFavorited,
    toggleFavorite: toggleUserFavorite,
} = useFavorites();
const { restoreScroll } = useScrollRestoration("dashboard");

const uploadModalOpen = ref(false);
const downloadMenuOpen = ref(false);
const downloadAsset = ref<SvgAsset | null>(null);
const searchQuery = ref("");
const selectedCategory = ref("");
const sortOrder = ref("newest");
const activeTab = ref<"mine" | "favorites">("mine");

const allCategories = ["Illustration", "Icon", "Logo", "Animation", "Other"];

const toast = ref<{ message: string; type: "success" | "error" | "info" }>({
    message: "",
    type: "success",
});

const showToast = (
    message: string,
    type: "success" | "error" | "info" = "success",
) => {
    toast.value = { message, type };
};

const displayName = computed(() => {
    if (!user.value) return "ผู้ใช้";
    if (user.value.username) return `@${user.value.username}`;
    if (user.value.email) return user.value.email.split("@")[0];
    return "ผู้ใช้";
});

const favoriteCount = computed(() => favoriteIds.value.size);

const uniqueCategories = computed(() => {
    const cats = new Set(assets.value.map((a) => a.category).filter(Boolean));
    return Array.from(cats);
});

const uniqueTagCount = computed(() => {
    const tags = new Set(assets.value.flatMap((a) => a.tags ?? []));
    return tags.size;
});

const filteredAssets = computed(() => {
    let list = [...assets.value];

    // Search filter
    if (searchQuery.value.trim()) {
        const q = searchQuery.value.toLowerCase();
        list = list.filter(
            (a) =>
                a.name.toLowerCase().includes(q) ||
                a.tags?.some((t) => t.toLowerCase().includes(q)) ||
                a.category?.toLowerCase().includes(q),
        );
    }

    // Category filter
    if (selectedCategory.value) {
        list = list.filter((a) => a.category === selectedCategory.value);
    }

    // Sort
    switch (sortOrder.value) {
        case "newest":
            list.sort(
                (a, b) =>
                    new Date(b.created_at).getTime() -
                    new Date(a.created_at).getTime(),
            );
            break;
        case "oldest":
            list.sort(
                (a, b) =>
                    new Date(a.created_at).getTime() -
                    new Date(b.created_at).getTime(),
            );
            break;
        case "name":
            list.sort((a, b) => a.name.localeCompare(b.name, "th"));
            break;
    }

    return list;
});

const filteredFavoriteAssets = computed(() => {
    let list = [...favoriteAssets.value];

    if (searchQuery.value.trim()) {
        const q = searchQuery.value.toLowerCase();
        list = list.filter(
            (a) =>
                a.name.toLowerCase().includes(q) ||
                a.tags?.some((t) => t.toLowerCase().includes(q)) ||
                a.category?.toLowerCase().includes(q),
        );
    }

    if (selectedCategory.value) {
        list = list.filter((a) => a.category === selectedCategory.value);
    }

    return list;
});

const clearFilters = () => {
    searchQuery.value = "";
    selectedCategory.value = "";
};

const loadAssets = async (restorePosition = false) => {
    if (!user.value) {
        try {
            await refreshSession();
        } catch {
            // ignore — fetchByUser will simply not run if user is unavailable
        }
    }

    if (user.value) {
        await Promise.all([
            fetchByUser(user.value.id),
            fetchFavoriteAssets(user.value.id),
        ]);
        if (restorePosition) restoreScroll();
    }
};

const handleUploaded = async () => {
    showToast(t("uploadModal.upload"), "success");
    await loadAssets();
};

const handleFavorite = async (id: string, current: boolean) => {
    if (!user.value) return;
    const userId = user.value.id;
    const wasAlreadyFav = isFavorited(id);
    try {
        await toggleUserFavorite(userId, id);

        // For own assets in the "mine" tab, also sync the is_favorite field
        // on the asset row itself (owner-only — RLS enforced on the DB side).
        if (activeTab.value === "mine") {
            try {
                await toggleFavorite(id, current);
            } catch {
                // RLS may block if not the owner — ignore silently
            }
        }

        if (activeTab.value === "favorites") {
            // Refresh the favorites list so the removed card disappears
            await fetchFavoriteAssets(userId);
        } else {
            await loadAssets();
        }

        showToast(
            wasAlreadyFav
                ? t("dashboard.toast.favoriteRemoved")
                : t("dashboard.toast.favoriteAdded"),
            "success",
        );
    } catch {
        showToast(t("dashboard.toast.error"), "error");
    }
};

const handleDownload = (id: string) => {
    const asset = assets.value.find((a) => a.id === id);
    if (!asset) return;
    downloadAsset.value = asset;
    downloadMenuOpen.value = true;
};

const handleCopy = () => {
    showToast(t("dashboard.toast.copied"), "success");
};

// Re-fetch when the user switches back to this tab.
// The sequence is critical: refresh the auth token FIRST (so the JWT stored
// in Supabase is valid), THEN fetch data.  Without this ordering the fetch
// races with the token refresh and may send an expired JWT → RLS blocks the
// query → the page appears frozen with stale/empty data.
// The concurrency guard (`isRecovering`) prevents rapid-fire calls when some
// browsers emit multiple visibilitychange events in quick succession.
let isRecovering = false;
const handleVisibilityChange = async () => {
    if (document.visibilityState !== "visible") return;
    if (isRecovering) return;
    isRecovering = true;
    try {
        await refreshSession();
        await loadAssets();
    } catch {
        // Swallow errors — the page keeps showing whatever data it already has
    } finally {
        isRecovering = false;
    }
};

onMounted(async () => {
    // Refresh the auth session first so that `user.value` is populated
    // and the Supabase client holds a fresh JWT before fetching assets.
    try {
        await refreshSession();
    } catch {
        // If refresh times out or fails, we still attempt to load assets.
        // The fallback in loadAssets will handle the absence of user.
    }

    await loadAssets(true);
    document.addEventListener("visibilitychange", handleVisibilityChange);
});

onUnmounted(() => {
    document.removeEventListener("visibilitychange", handleVisibilityChange);
});
</script>
