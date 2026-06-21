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
                @click.self="close"
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
                        class="bg-surface rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] flex flex-col overflow-hidden border border-border font-prompt"
                    >
                        <!-- Header -->
                        <div
                            class="flex items-center justify-between px-5 py-4 border-b border-border shrink-0"
                        >
                            <div class="flex items-center gap-2">
                                <div
                                    class="w-8 h-8 rounded-xl bg-accent/10 flex items-center justify-center"
                                >
                                    <Download :size="16" class="text-accent" />
                                </div>
                                <h2 class="text-base font-semibold text-textprimary font-prompt">
                                    Download
                                </h2>
                            </div>
                            <button
                                @click="close"
                                class="p-1.5 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                            >
                                <X :size="18" />
                            </button>
                        </div>

                        <!-- Body -->
                        <div class="flex-1 overflow-y-auto p-5 space-y-5">
                            <!-- Format selector (SVG / PNG / JPEG) -->
                            <div>
                                <label class="block text-sm font-medium text-textprimary font-prompt mb-2">
                                    Format
                                </label>
                                <div class="grid grid-cols-3 gap-2">
                                    <button
                                        v-for="fmt in formatOptions"
                                        :key="fmt.key"
                                        @click="selectedFormat = fmt.key"
                                        :class="[
                                            'flex flex-col items-center gap-1.5 px-3 py-3 rounded-xl text-xs font-prompt font-medium transition-all duration-150 border',
                                            selectedFormat === fmt.key
                                                ? 'border-accent bg-accent/5 text-accent ring-2 ring-accent/20'
                                                : 'border-border bg-bg text-textprimary hover:border-accent/60',
                                        ]"
                                    >
                                        <component :is="fmt.icon" :size="20" />
                                        <span>{{ fmt.label }}</span>
                                    </button>
                                </div>
                            </div>

                            <!-- Size selector (only for raster formats) -->
                            <div v-if="selectedFormat !== 'svg'">
                                <label class="block text-sm font-medium text-textprimary font-prompt mb-2">
                                    Size
                                </label>
                                <div class="grid grid-cols-2 gap-2">
                                    <button
                                        v-for="size in sizeOptions"
                                        :key="size.value"
                                        @click="selectedSize = size.value"
                                        :class="[
                                            'flex flex-col items-center gap-0.5 px-3 py-2.5 rounded-xl text-xs font-prompt font-medium transition-all duration-150 border',
                                            selectedSize === size.value
                                                ? 'border-accent bg-accent/5 text-accent ring-2 ring-accent/20'
                                                : 'border-border bg-bg text-textprimary hover:border-accent/60',
                                        ]"
                                    >
                                        <span class="text-sm font-semibold tabular-nums">{{ size.label }}</span>
                                        <span class="text-[10px] text-textsecondary font-normal">{{ size.subtitle }}</span>
                                    </button>
                                </div>
                            </div>
                            <div v-else class="text-xs text-textsecondary font-prompt leading-relaxed bg-soft/60 border border-border rounded-xl p-3">
                                SVG is a vector format — it scales to any size without quality loss.
                            </div>

                            <!-- JPEG quality (only for JPEG) -->
                            <div v-if="selectedFormat === 'jpeg'">
                                <label class="block text-sm font-medium text-textprimary font-prompt mb-2">
                                    Quality
                                    <span class="text-textsecondary font-normal">{{ Math.round(jpegQuality * 100) }}%</span>
                                </label>
                                <input
                                    v-model.number="jpegQuality"
                                    type="range"
                                    min="0.5"
                                    max="1"
                                    step="0.05"
                                    class="w-full accent-accent"
                                />
                            </div>
                        </div>

                        <!-- Footer -->
                        <div
                            class="flex items-center justify-end gap-3 px-5 py-4 border-t border-border shrink-0 bg-soft/30"
                        >
                            <button
                                @click="close"
                                class="px-4 py-2 rounded-xl text-sm font-prompt text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                            >
                                Cancel
                            </button>
                            <button
                                @click="handleDownload"
                                :disabled="isConverting"
                                class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-150"
                            >
                                <Loader2 v-if="isConverting" :size="15" class="animate-spin" />
                                <Download v-else :size="15" />
                                {{ isConverting ? "Preparing..." : "Download" }}
                            </button>
                        </div>
                    </div>
                </Transition>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import {
    X,
    Download,
    Loader2,
    FileImage,
    FileCode,
    Image,
} from "lucide-vue-next";
import { exportSvgToImage, downloadSvg } from "../utils/svgUtils";

const props = defineProps<{
    modelValue: boolean;
    svgCode: string;
    filename: string;
}>();

const emit = defineEmits<{
    "update:modelValue": [value: boolean];
    downloaded: [];
}>();

// ── Format ──────────────────────────────────────────────────────────
type DownloadFormat = "svg" | "png" | "jpeg";
const formatOptions: {
    key: DownloadFormat;
    label: string;
    icon: typeof FileImage;
}[] = [
    { key: "svg", label: "SVG", icon: FileCode },
    { key: "png", label: "PNG", icon: FileImage },
    { key: "jpeg", label: "JPEG", icon: Image },
];
const selectedFormat = ref<DownloadFormat>("png");

// ── Size ────────────────────────────────────────────────────────────
interface SizeOpt {
    value: string;
    label: string;
    subtitle: string;
    width: number;
    height: number;
}
const sizeOptions: SizeOpt[] = [
    { value: "256", label: "256×256", subtitle: "Small", width: 256, height: 256 },
    { value: "512", label: "512×512", subtitle: "Medium", width: 512, height: 512 },
    { value: "1024", label: "1024×1024", subtitle: "Large", width: 1024, height: 1024 },
    { value: "2048", label: "2048×2048", subtitle: "Original", width: 2048, height: 2048 },
];
const selectedSize = ref<string>("1024");

// ── Quality ────────────────────────────────────────────────────────
const jpegQuality = ref(0.92);

// ── State ──────────────────────────────────────────────────────────
const isConverting = ref(false);

// Reset defaults when modal opens
watch(
    () => props.modelValue,
    (open) => {
        if (open) {
            selectedFormat.value = "png";
            selectedSize.value = "1024";
            jpegQuality.value = 0.92;
            isConverting.value = false;
        }
    },
);

const close = () => {
    if (isConverting.value) return;
    emit("update:modelValue", false);
};

const handleDownload = async () => {
    if (!props.svgCode || isConverting.value) return;
    isConverting.value = true;

    try {
        if (selectedFormat.value === "svg") {
            // Raw SVG download — no rasterization, preserves vector quality
            downloadSvg(props.svgCode, props.filename);
        } else {
            const size = sizeOptions.find((s) => s.value === selectedSize.value);
            if (!size) throw new Error("Invalid size");
            await exportSvgToImage(props.svgCode, {
                width: size.width,
                height: size.height,
                format: selectedFormat.value,
                background: "white",
                quality: jpegQuality.value,
                filename: props.filename,
            });
        }
        emit("downloaded");
        emit("update:modelValue", false);
    } catch {
        // Surface the error through toast in parent; modal stays open.
    } finally {
        isConverting.value = false;
    }
};
</script>
