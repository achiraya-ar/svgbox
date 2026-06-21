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
                        class="bg-surface rounded-2xl shadow-xl w-full max-w-3xl max-h-[90vh] flex flex-col overflow-hidden border border-border"
                    >
                        <!-- Header -->
                        <div
                            class="flex items-center justify-between px-5 py-4 border-b border-border shrink-0"
                        >
                            <div class="flex items-center gap-2">
                                <div
                                    class="w-8 h-8 rounded-xl bg-accent/10 flex items-center justify-center"
                                >
                                    <Eye :size="16" class="text-accent" />
                                </div>
                                <h2
                                    class="text-base font-semibold text-textprimary font-prompt"
                                >
                                    Preview SVG
                                </h2>
                            </div>
                            <button
                                @click="$emit('update:modelValue', false)"
                                class="p-1.5 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                            >
                                <X :size="18" />
                            </button>
                        </div>

                        <!-- Body -->
                        <div
                            class="flex-1 overflow-y-auto p-5 space-y-4 min-h-0"
                        >
                            <!-- SVG Code Input -->
                            <div>
                                <label
                                    class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                >
                                    วาง SVG Code ที่นี่
                                </label>
                                <div class="relative">
                                    <textarea
                                        v-model="svgInput"
                                        placeholder='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">...</svg>'
                                        rows="6"
                                        class="w-full px-4 py-3 bg-bg border border-border rounded-xl text-xs font-mono text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200 resize-none"
                                        @input="onInput"
                                    />
                                    <button
                                        v-if="svgInput"
                                        @click="clearInput"
                                        class="absolute top-2 right-2 p-1 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                                        title="ล้าง"
                                    >
                                        <X :size="14" />
                                    </button>
                                </div>
                                <p
                                    v-if="parseError"
                                    class="mt-1 text-xs text-red-500 font-prompt"
                                >
                                    {{ parseError }}
                                </p>
                            </div>

                            <!-- Preview Area -->
                            <div>
                                <label
                                    class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                >
                                    ตัวอย่าง
                                </label>
                                <div
                                    class="w-full bg-bg border border-border rounded-xl overflow-hidden"
                                    style="min-height: 240px"
                                >
                                    <!-- SVG Preview -->
                                    <div
                                        v-if="sanitizedSvg"
                                        ref="previewRef"
                                        class="w-full h-full flex items-center justify-center p-6"
                                        style="min-height: 240px"
                                        v-html="sanitizedSvg"
                                    />
                                    <!-- Placeholder -->
                                    <div
                                        v-else
                                        class="flex flex-col items-center justify-center gap-2 text-textsecondary"
                                        style="min-height: 240px"
                                    >
                                        <ImageIcon :size="36" class="opacity-30" />
                                        <p class="text-sm font-prompt">
                                            ตัวอย่างจะแสดงที่นี่
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <!-- Size selector -->
                            <div v-if="sanitizedSvg" class="flex items-center gap-3">
                                <label class="text-sm font-medium text-textprimary font-prompt shrink-0">
                                    ขนาด PNG:
                                </label>
                                <div class="flex gap-2">
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
                        </div>

                        <!-- Footer Actions -->
                        <div
                            class="flex items-center justify-between gap-3 px-5 py-4 border-t border-border shrink-0 bg-soft/30"
                        >
                            <div class="text-xs text-textsecondary font-prompt flex items-center gap-1">
                                <template v-if="sanitizedSvg">
                                    <Check :size="12" class="text-accent" />
                                    <span>SVG พร้อมดาวน์โหลด</span>
                                </template>
                                <span v-else>วาง SVG code เพื่อดูตัวอย่าง</span>
                            </div>
                            <div class="flex gap-2">
                                <button
                                    @click="$emit('update:modelValue', false)"
                                    class="px-4 py-2 rounded-xl text-sm font-prompt text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                                >
                                    ปิด
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
                                    {{ copied ? 'คัดลอกแล้ว!' : 'คัดลอก SVG' }}
                                </button>
                                <button
                                    v-if="sanitizedSvg"
                                    @click="downloadPng"
                                    :disabled="isConverting"
                                    class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-150"
                                >
                                    <Loader2
                                        v-if="isConverting"
                                        :size="15"
                                        class="animate-spin"
                                    />
                                    <Download v-else :size="15" />
                                    ดาวน์โหลด PNG
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
    Eye,
    Download,
    Copy,
    Check,
    Loader2,
    ImageIcon,
} from "lucide-vue-next";
import { sanitizeSvg } from "../utils/svgUtils";

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
        parseError.value = "ไม่พบ SVG tag — กรุณาวาง SVG code ที่ถูกต้อง";
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
 * Convert the SVG preview to a PNG and trigger a download.
 * Uses an offscreen Canvas; the SVG is serialized as a data-URL and drawn
 * onto the canvas via an Image element.
 */
const downloadPng = async () => {
    if (!sanitizedSvg.value || isConverting.value) return;
    isConverting.value = true;

    try {
        const { width, height } = selectedSize.value;

        const rawSvg = svgInput.value.trim();
        const svgWithSize = rawSvg.replace(
            /<svg/i,
            `<svg width="${width}" height="${height}"`,
        );

        const svgBlob = new Blob([svgWithSize], { type: "image/svg+xml;charset=utf-8" });
        const svgUrl = URL.createObjectURL(svgBlob);

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");
        if (!ctx) throw new Error("Canvas 2D context not available");

        await new Promise<void>((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(img, 0, 0, width, height);
                URL.revokeObjectURL(svgUrl);
                resolve();
            };
            img.onerror = () => {
                URL.revokeObjectURL(svgUrl);
                reject(new Error("ไม่สามารถแปลง SVG เป็น PNG ได้"));
            };
            img.src = svgUrl;
        });

        const pngUrl = canvas.toDataURL("image/png");
        const a = document.createElement("a");
        a.download = `svg-preview-${width}px.png`;
        a.href = pngUrl;
        a.click();
    } catch (e) {
        parseError.value =
            e instanceof Error
                ? e.message
                : "เกิดข้อผิดพลาดในการดาวน์โหลด PNG";
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
};

defineExpose({ resetState });
</script>
