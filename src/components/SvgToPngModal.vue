<template>
    <Teleport to="body">
        <Transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div
                v-if="modelValue"
                class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
                @click.self="$emit('update:modelValue', false)"
            >
                <Transition
                    enter-active-class="transition duration-200 ease-out"
                    enter-from-class="opacity-0 scale-95 translate-y-2"
                    enter-to-class="opacity-100 scale-100 translate-y-0"
                    leave-active-class="transition duration-150 ease-in"
                    leave-from-class="opacity-100 scale-100 translate-y-0"
                    leave-to-class="opacity-0 scale-95 translate-y-2"
                >
                    <div
                        v-if="modelValue"
                        class="bg-surface rounded-2xl shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden border border-border font-prompt"
                    >
                        <!-- Header -->
                        <div
                            class="flex items-center justify-between px-5 py-4 border-b border-border shrink-0"
                        >
                            <div class="flex items-center gap-2">
                                <div
                                    class="w-8 h-8 rounded-xl bg-accent/10 flex items-center justify-center"
                                >
                                    <ImageDown :size="16" class="text-accent" />
                                </div>
                                <h2 class="text-base font-semibold text-textprimary font-prompt">
                                    SVG to PNG
                                </h2>
                            </div>
                            <button
                                @click="$emit('update:modelValue', false)"
                                class="p-1.5 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                            >
                                <X :size="18" />
                            </button>
                        </div>

                        <!-- Body: 2 columns — preview LEFT, code RIGHT -->
                        <div class="flex-1 overflow-hidden grid md:grid-cols-2 min-h-0">
                            <!-- LEFT: Preview + background picker (always shown) -->
                            <div
                                class="p-5 space-y-3 overflow-y-auto border-r border-border h-full"
                            >
                                <div>
                                    <label
                                        class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                    >
                                        Preview
                                    </label>
                                    <div
                                        class="w-full border border-border rounded-xl overflow-hidden"
                                        :style="{
                                            background: previewBackgroundStyle,
                                            minHeight: '260px',
                                        }"
                                    >
                                        <div
                                            v-if="sanitizedSvg"
                                            ref="previewRef"
                                            class="w-full h-full flex items-center justify-center p-6"
                                            style="min-height: 260px"
                                            v-html="sanitizedSvg"
                                        />
                                        <div
                                            v-else
                                            class="flex flex-col items-center justify-center gap-2 text-textsecondary"
                                            style="min-height: 260px"
                                        >
                                            <ImageIcon :size="36" class="opacity-30" />
                                            <p class="text-sm font-prompt">
                                                Preview will appear here
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <!-- Background picker (always shown — preview only) -->
                                <div>
                                    <label
                                        class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                    >
                                        Background
                                        <span class="text-[11px] font-normal text-textsecondary ml-1">
                                            (preview only)
                                        </span>
                                    </label>
                                    <div class="flex flex-wrap gap-2">
                                        <button
                                            v-for="bg in backgroundOptions"
                                            :key="bg.key"
                                            @click="selectedBackground = bg.key"
                                            :title="bg.label"
                                            :class="[
                                                'flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-150 border',
                                                selectedBackground === bg.key
                                                    ? 'border-accent ring-2 ring-accent/20'
                                                    : 'border-border hover:border-accent/60',
                                            ]"
                                        >
                                            <span
                                                :class="[
                                                    'w-4 h-4 rounded border border-border shrink-0',
                                                    bg.swatchClass,
                                                ]"
                                            />
                                            {{ bg.label }}
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- RIGHT: SVG code editor + size/format (only when SVG present) -->
                            <div class="p-5 flex flex-col h-full min-h-0 gap-3">
                                <div class="flex flex-col flex-1 min-h-0">
                                    <label
                                        class="block text-sm font-medium text-textprimary font-prompt mb-1.5 shrink-0"
                                    >
                                        Paste SVG Code here
                                    </label>
                                    <div class="relative flex-1 min-h-[300px]">
                                        <textarea
                                            v-model="svgInput"
                                            placeholder='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">...</svg>'
                                            class="w-full h-full px-4 py-3 bg-bg border border-border rounded-xl text-xs font-mono text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200 resize-none"
                                            @input="onInput"
                                        />
                                        <button
                                            v-if="svgInput"
                                            @click="clearInput"
                                            class="absolute top-2 right-2 p-1 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                                            title="Clear"
                                        >
                                            <X :size="14" />
                                        </button>
                                    </div>
                                    <p
                                        v-if="parseError"
                                        class="mt-1 text-xs text-red-500 font-prompt shrink-0"
                                    >
                                        {{ parseError }}
                                    </p>
                                </div>

                                <!-- Size + format (only when SVG present) -->
                                <div
                                    v-if="sanitizedSvg"
                                    class="space-y-2 shrink-0"
                                >
                                    <div class="flex items-center gap-3 flex-wrap">
                                        <label
                                            class="text-sm font-medium text-textprimary font-prompt shrink-0"
                                        >
                                            Size:
                                        </label>
                                        <div class="flex gap-2 flex-wrap">
                                            <button
                                                v-for="size in pngSizes"
                                                :key="size.label"
                                                @click="selectedSize = size"
                                                :class="[
                                                    'px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-150',
                                                    selectedSize.label === size.label
                                                        ? 'bg-accent text-white'
                                                        : 'bg-soft text-textsecondary hover:text-textprimary hover:bg-border',
                                                ]"
                                            >
                                                {{ size.label }}
                                            </button>
                                        </div>
                                    </div>

                                    <div class="flex items-center gap-3 flex-wrap">
                                        <label
                                            class="text-sm font-medium text-textprimary font-prompt shrink-0"
                                        >
                                            Format:
                                        </label>
                                        <div class="flex gap-2">
                                            <button
                                                v-for="fmt in formatOptions"
                                                :key="fmt.key"
                                                @click="selectedFormat = fmt.key"
                                                :class="[
                                                    'px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-150 border',
                                                    selectedFormat === fmt.key
                                                        ? 'bg-accent text-white border-accent'
                                                        : 'bg-soft text-textsecondary border-border hover:text-textprimary hover:bg-border',
                                                ]"
                                            >
                                                {{ fmt.label }}
                                            </button>
                                        </div>
                                        <div
                                            v-if="selectedFormat === 'jpeg'"
                                            class="flex items-center gap-2 ml-auto"
                                        >
                                            <label
                                                class="text-xs font-prompt text-textsecondary shrink-0"
                                            >
                                                Quality
                                            </label>
                                            <input
                                                v-model.number="jpegQuality"
                                                type="range"
                                                min="0.5"
                                                max="1"
                                                step="0.05"
                                                class="w-24 accent-accent"
                                            />
                                            <span
                                                class="text-xs font-prompt text-textsecondary tabular-nums w-8"
                                            >
                                                {{ Math.round(jpegQuality * 100) }}%
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Footer -->
                        <div
                            class="flex items-center justify-between gap-3 px-5 py-4 border-t border-border shrink-0 bg-soft/30"
                        >
                            <div class="text-xs text-textsecondary font-prompt flex items-center gap-1">
                                <template v-if="sanitizedSvg">
                                    <Check :size="12" class="text-accent" />
                                    <span>Ready to download</span>
                                </template>
                                <span v-else>Paste SVG code to preview</span>
                            </div>
                            <div class="flex gap-2">
                                <button
                                    @click="$emit('update:modelValue', false)"
                                    class="px-4 py-2 rounded-xl text-sm font-prompt text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                                >
                                    Close
                                </button>
                                <button
                                    v-if="sanitizedSvg"
                                    @click="copySvg"
                                    :class="[
                                        'flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-prompt font-medium transition-all duration-150',
                                        copied
                                            ? 'bg-accent text-white'
                                            : 'bg-soft text-textprimary hover:bg-border',
                                    ]"
                                >
                                    <Check v-if="copied" :size="15" />
                                    <Copy v-else :size="15" />
                                    {{ copied ? "Copied!" : "Copy SVG" }}
                                </button>
                                <button
                                    v-if="sanitizedSvg"
                                    @click="downloadImage"
                                    :disabled="isConverting"
                                    class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-150"
                                >
                                    <Loader2
                                        v-if="isConverting"
                                        :size="15"
                                        class="animate-spin"
                                    />
                                    <Download v-else :size="15" />
                                    {{ isConverting ? "Converting..." : "Download" }}
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import {
    X,
    ImageDown,
    Download,
    Copy,
    Check,
    Loader2,
    ImageIcon,
} from "lucide-vue-next";
import {
    sanitizeSvg,
    exportSvgToImage,
    type ExportBackground,
} from "../utils/svgUtils";

defineProps<{
    modelValue: boolean;
}>();

defineEmits<{
    "update:modelValue": [value: boolean];
}>();

// ── State ────────────────────────────────────────────────────────────────────

const svgInput = ref("");
const parseError = ref("");
const previewRef = ref<HTMLElement | null>(null);
const isConverting = ref(false);
const copied = ref(false);

const pngSizes = [
    { label: "512px", width: 512, height: 512 },
    { label: "1024px", width: 1024, height: 1024 },
    { label: "2048px", width: 2048, height: 2048 },
];
const selectedSize = ref(pngSizes[0]);

type ExportFormat = "png" | "jpeg";
const formatOptions: { key: ExportFormat; label: string }[] = [
    { key: "png", label: "PNG" },
    { key: "jpeg", label: "JPEG" },
];
const selectedFormat = ref<ExportFormat>("png");
const jpegQuality = ref(0.92);

interface BgOpt {
    key: ExportBackground;
    label: string;
    swatchClass: string;
    previewStyle: string;
}
const backgroundOptions: BgOpt[] = [
    {
        key: "white",
        label: "White",
        swatchClass: "bg-white",
        previewStyle: "#FFFFFF",
    },
    {
        key: "black",
        label: "Black",
        swatchClass: "bg-black",
        previewStyle: "#000000",
    },
    {
        key: "transparent",
        label: "Transparent",
        swatchClass:
            "[background-image:linear-gradient(45deg,#d1d5db_25%,transparent_25%),linear-gradient(-45deg,#d1d5db_25%,transparent_25%),linear-gradient(45deg,transparent_75%,#d1d5db_75%),linear-gradient(-45deg,transparent_75%,#d1d5db_75%)] [background-size:8px_8px] [background-position:0_0,0_4px,4px_-4px,-4px_0px] bg-white",
        previewStyle:
            "repeating-conic-gradient(#d1d5db 0 25%, #ffffff 0 50%) 0 0 / 16px 16px",
    },
    {
        key: "checkerboard",
        label: "Checker",
        swatchClass:
            "[background-image:linear-gradient(45deg,#9ca3af_25%,transparent_25%),linear-gradient(-45deg,#9ca3af_25%,transparent_25%),linear-gradient(45deg,#9ca3af_25%,transparent_25%),linear-gradient(-45deg,#9ca3af_25%,transparent_25%)] [background-size:8px_8px] [background-position:0_0,0_4px,4px_-4px,-4px_0px] bg-soft",
        previewStyle:
            "repeating-conic-gradient(#9ca3af 0 25%, #e5e7eb 0 50%) 0 0 / 16px 16px",
    },
];
const selectedBackground = ref<ExportBackground>("white");

const previewBackgroundStyle = computed(() => {
    const opt = backgroundOptions.find(
        (b) => b.key === selectedBackground.value,
    );
    return opt?.previewStyle ?? "#FFFFFF";
});

// ── Computed ─────────────────────────────────────────────────────────────────

const sanitizedSvg = computed(() => {
    if (!svgInput.value.trim()) return "";
    try {
        const cleaned = sanitizeSvg(svgInput.value.trim());
        if (!/<svg[\s>]/i.test(cleaned)) return "";
        return cleaned.replace(
            /<svg/i,
            '<svg style="max-width:100%;max-height:480px;width:auto;height:auto;"',
        );
    } catch {
        return "";
    }
});

// ── Handlers ─────────────────────────────────────────────────────────────────

const onInput = () => {
    parseError.value = "";
    if (svgInput.value.trim() && !/<svg[\s>]/i.test(svgInput.value)) {
        parseError.value = "SVG tag not found — please paste valid SVG code";
    }
};

const clearInput = () => {
    svgInput.value = "";
    parseError.value = "";
};

const copySvg = async () => {
    try {
        await navigator.clipboard.writeText(svgInput.value.trim());
        copied.value = true;
        setTimeout(() => {
            copied.value = false;
        }, 2000);
    } catch {
        // ignore
    }
};

/**
 * Convert the SVG to the chosen format/size/background and trigger a
 * download.  Delegates to exportSvgToImage in utils/svgUtils.ts.
 */
const downloadImage = async () => {
    if (!sanitizedSvg.value || isConverting.value) return;
    isConverting.value = true;

    try {
        const rawSvg = svgInput.value.trim();
        const { width, height } = selectedSize.value;
        const filename = "svg-to-image";

        await exportSvgToImage(rawSvg, {
            width,
            height,
            format: selectedFormat.value,
            background: selectedBackground.value,
            quality: jpegQuality.value,
            filename,
        });
    } catch (e) {
        parseError.value =
            e instanceof Error ? e.message : "Error occurred while downloading";
    } finally {
        isConverting.value = false;
    }
};

// ── Exposed ───────────────────────────────────────────────────────────────────

const resetState = () => {
    svgInput.value = "";
    parseError.value = "";
    copied.value = false;
    selectedSize.value = pngSizes[0];
    selectedFormat.value = "png";
    selectedBackground.value = "white";
    jpegQuality.value = 0.92;
};

defineExpose({ resetState });
</script>
