<template>
    <div
        class="group relative bg-surface rounded-2xl shadow-sm border border-border p-4 cursor-pointer transition-all duration-200 hover:shadow-md hover:-translate-y-0.5"
        @click="handleCardClick"
    >
        <!-- SVG Preview -->
        <div
            class="relative w-full h-32 bg-bg rounded-xl flex items-center justify-center overflow-hidden mb-3"
        >
            <div
                v-if="asset.svg_code"
                class="w-full h-full flex items-center justify-center p-2"
                v-html="scopedSvg"
            />
            <div v-else class="text-textsecondary text-xs font-prompt">
                {{ t("svgCard.noPreview") }}
            </div>

            <!-- Hover Action Overlay -->
            <div
                class="absolute inset-0 bg-primary/60 rounded-xl flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                @click.stop
            >
                <!-- Favorite -->
                <button
                    @click.stop="handleFavorite"
                    :title="
                        effectiveFavorite
                            ? t('svgCard.removeFavorite')
                            : t('svgCard.addFavorite')
                    "
                    :class="[
                        'p-2 rounded-xl transition-all duration-150 hover:scale-110',
                        effectiveFavorite
                            ? 'bg-accent text-white'
                            : 'bg-white/20 text-white hover:bg-accent',
                    ]"
                >
                    <Heart
                        :size="16"
                        :fill="effectiveFavorite ? 'currentColor' : 'none'"
                    />
                </button>

                <!-- Download -->
                <button
                    @click.stop="handleDownload"
                    :title="t('svgCard.downloadSvg')"
                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-accent transition-all duration-150 hover:scale-110"
                >
                    <Download :size="16" />
                </button>

                <!-- Copy -->
                <button
                    @click.stop="handleCopy"
                    :title="t('svgCard.copySvgCode')"
                    :class="[
                        'p-2 rounded-xl transition-all duration-150 hover:scale-110',
                        copied
                            ? 'bg-accent text-white'
                            : 'bg-white/20 text-white hover:bg-accent',
                    ]"
                >
                    <Check v-if="copied" :size="16" />
                    <Copy v-else :size="16" />
                </button>
            </div>
        </div>

        <!-- Name -->
        <p
            class="font-prompt font-medium text-sm text-textprimary truncate mb-2"
        >
            {{ asset.name }}
        </p>

        <!-- Tags -->
        <div
            v-if="asset.tags && asset.tags.length"
            class="flex flex-wrap gap-1"
        >
            <span
                v-for="tag in asset.tags.slice(0, 3)"
                :key="tag"
                class="bg-soft text-textsecondary rounded-full px-2 py-0.5 text-xs font-prompt"
            >
                {{ tag }}
            </span>
            <span
                v-if="asset.tags.length > 3"
                class="bg-soft text-textsecondary rounded-full px-2 py-0.5 text-xs font-prompt"
            >
                +{{ asset.tags.length - 3 }}
            </span>
        </div>

        <!-- Category badge -->
        <div v-if="asset.category" class="mt-2">
            <span
                class="text-[11px] font-prompt text-accent bg-accent/10 px-2 py-0.5 rounded-full"
            >
                {{ asset.category }}
            </span>
        </div>

        <!-- Creator badge -->
        <div
            v-if="asset.creator?.username"
            class="mt-2 flex items-center gap-1"
            @click.stop
        >
            <component
                :is="'RouterLink'"
                :to="`/profile/${asset.creator.username}`"
                class="inline-flex items-center gap-1 text-[11px] font-prompt text-textsecondary hover:text-accent transition-colors duration-150 group/creator"
                :title="`${t('svgCard.viewProfileOf')} @${asset.creator.username}`"
            >
                <User2
                    :size="11"
                    class="shrink-0 group-hover/creator:text-accent"
                />
                <span>@{{ asset.creator.username }}</span>
            </component>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { useRouter } from "vue-router";
import { Heart, Download, Copy, Check, User2 } from "lucide-vue-next";
import {
    sanitizeSvg,
    copySvgToClipboard,
} from "../utils/svgUtils";
import { useI18n } from "../composables/useI18n";
import type { SvgAsset } from "../types";

const props = defineProps<{
    asset: SvgAsset;
    currentUserId?: string;
    userFavorited?: boolean;
}>();

const emit = defineEmits<{
    favorite: [id: string, current: boolean];
    download: [id: string];
    copy: [id: string];
}>();

const router = useRouter();
const { t } = useI18n();
const copied = ref(false);

const effectiveFavorite = computed(() =>
    props.userFavorited !== undefined
        ? props.userFavorited
        : props.asset.is_favorite,
);

/**
 * Generate a short unique prefix for this card so that SVG element IDs
 * (linearGradient, filter, clipPath, mask, etc.) don't clash with IDs from
 * other cards rendered on the same page.
 *
 * We use the asset id (which is stable) so the value doesn't change on
 * every render, avoiding unnecessary DOM patching.
 */
const scopePrefix = computed(() => `svgc-${props.asset.id}-`);

/**
 * Rewrite every `id="…"` definition and every `url(#…)` / `href="#…"` /
 * `xlink:href="#…"` reference inside the SVG so they are namespaced with the
 * per-card prefix.  This prevents gradient/filter/clip collisions when many
 * cards are visible at the same time.
 */
function scopeSvgIds(svg: string, prefix: string): string {
    // Collect all ids defined in this SVG
    const idRegex = /\bid="([^"]+)"/g;
    const ids: string[] = [];
    let m: RegExpExecArray | null;
    while ((m = idRegex.exec(svg)) !== null) {
        ids.push(m[1]);
    }

    if (ids.length === 0) return svg;

    // Escape special regex chars in id values
    const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    let result = svg;

    for (const id of ids) {
        const escapedId = escape(id);
        const newId = `${prefix}${id}`;

        // Replace id="…" definitions
        result = result.replace(
            new RegExp(`\\bid="${escapedId}"`, "g"),
            `id="${newId}"`,
        );

        // Replace url(#…) references
        result = result.replace(
            new RegExp(`url\\(#${escapedId}\\)`, "g"),
            `url(#${newId})`,
        );

        // Replace href="#…" references
        result = result.replace(
            new RegExp(`href="#${escapedId}"`, "g"),
            `href="#${newId}"`,
        );

        // Replace xlink:href="#…" references
        result = result.replace(
            new RegExp(`xlink:href="#${escapedId}"`, "g"),
            `xlink:href="#${newId}"`,
        );
    }

    return result;
}

const scopedSvg = computed(() => {
    if (!props.asset.svg_code) return "";
    const cleaned = sanitizeSvg(props.asset.svg_code);
    const scoped = scopeSvgIds(cleaned, scopePrefix.value);
    // Force SVG to fill the container
    return scoped.replace(
        /<svg/i,
        '<svg style="max-width:100%;max-height:100%;width:auto;height:auto;"',
    );
});

const handleCardClick = () => {
    router.push({ name: "svg-detail", params: { id: props.asset.id } });
};

const handleFavorite = () => {
    emit("favorite", props.asset.id, effectiveFavorite.value);
};

const handleDownload = () => {
    // Don't download directly — let the parent open the DownloadMenu so
    // the user can pick format + size.
    emit("download", props.asset.id);
};

const handleCopy = async () => {
    try {
        await copySvgToClipboard(props.asset.svg_code);
        copied.value = true;
        emit("copy", props.asset.id);
        setTimeout(() => {
            copied.value = false;
        }, 2000);
    } catch {
        // fallback - ignore
    }
};
</script>
