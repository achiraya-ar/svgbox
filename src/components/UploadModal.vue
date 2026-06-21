<template>
    <Teleport to="body">
        <Transition name="modal">
            <div
                v-if="modelValue"
                class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
                @click.self="handleClose"
            >
                <div
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
                                <Upload :size="16" class="text-accent" />
                            </div>
                            <h2
                                class="text-base font-semibold text-textprimary font-prompt"
                            >
                                Upload SVG
                            </h2>
                        </div>
                        <button
                            @click="handleClose"
                            class="p-1.5 rounded-lg text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                        >
                            <X :size="18" />
                        </button>
                    </div>

                    <!-- Body: 2 columns — preview LEFT, source + form fields RIGHT -->
                    <form
                        @submit.prevent="handleSubmit"
                        class="flex-1 overflow-hidden grid md:grid-cols-2 min-h-0"
                    >
                        <!-- LEFT: preview -->
                        <div
                            class="p-5 overflow-y-auto border-r border-border h-full flex flex-col"
                        >
                            <label
                                class="block text-sm font-medium text-textprimary font-prompt mb-1.5 shrink-0"
                            >
                                Preview
                            </label>
                            <div
                                class="flex-1 w-full border border-border rounded-xl overflow-hidden flex items-center justify-center p-6 bg-bg"
                                style="min-height: 280px"
                            >
                                <div
                                    v-if="previewHtml"
                                    class="w-full h-full flex items-center justify-center"
                                    v-html="previewHtml"
                                />
                                <p
                                    v-else
                                    class="text-sm text-textsecondary font-prompt"
                                >
                                    Preview will appear here
                                </p>
                            </div>
                        </div>

                        <!-- RIGHT: source selector + form fields -->
                        <div class="p-5 space-y-4 overflow-y-auto">
                            <!-- Source selector: Upload File / Paste Code -->
                            <div>
                                <div
                                    class="flex items-center gap-1 bg-soft p-1 rounded-xl w-fit border border-border mb-2"
                                >
                                    <button
                                        type="button"
                                        @click="inputMode = 'paste'"
                                        :class="[
                                            'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-200',
                                            inputMode === 'paste'
                                                ? 'bg-surface text-accent shadow-sm border border-border'
                                                : 'text-textsecondary hover:text-primary',
                                        ]"
                                    >
                                        <Code :size="13" />
                                        Paste Code
                                    </button>
                                    <button
                                        type="button"
                                        @click="inputMode = 'file'"
                                        :class="[
                                            'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-200',
                                            inputMode === 'file'
                                                ? 'bg-surface text-accent shadow-sm border border-border'
                                                : 'text-textsecondary hover:text-primary',
                                        ]"
                                    >
                                        <FileUp :size="13" />
                                        Upload File
                                    </button>
                                </div>

                                <!-- File upload zone -->
                                <div v-if="inputMode === 'file'">
                                    <div
                                        class="relative border-2 border-dashed rounded-xl transition-all duration-200 cursor-pointer"
                                        :class="[
                                            isDragging
                                                ? 'border-accent bg-accent/5 scale-[1.01]'
                                                : errors.svg_code
                                                  ? 'border-red-400 bg-bg'
                                                  : form.svg_code
                                                    ? 'border-accent/40 bg-accent/5'
                                                    : 'border-border bg-bg hover:border-accent/60 hover:bg-accent/5',
                                        ]"
                                        @dragover.prevent="isDragging = true"
                                        @dragleave.prevent="isDragging = false"
                                        @drop.prevent="handleDrop"
                                        @click="triggerFileInput"
                                    >
                                        <input
                                            ref="fileInput"
                                            type="file"
                                            accept=".svg,image/svg+xml"
                                            class="hidden"
                                            @change="handleFileChange"
                                        />

                                        <div
                                            v-if="!form.svg_code"
                                            class="flex flex-col items-center justify-center py-6 px-4 text-center pointer-events-none"
                                        >
                                            <div
                                                class="w-10 h-10 rounded-xl bg-soft flex items-center justify-center mb-2"
                                            >
                                                <FileUp
                                                    :size="20"
                                                    class="text-textsecondary"
                                                />
                                            </div>
                                            <p
                                                class="text-sm font-medium text-textprimary font-prompt"
                                            >
                                                Drop SVG file here
                                            </p>
                                            <p
                                                class="text-xs text-textsecondary mt-0.5 font-prompt"
                                            >
                                                or click to browse
                                            </p>
                                        </div>

                                        <div
                                            v-else
                                            class="flex items-center gap-2 px-4 py-3"
                                        >
                                            <FileCheck
                                                :size="18"
                                                class="text-accent shrink-0"
                                            />
                                            <span
                                                class="text-sm text-accent font-prompt font-medium truncate flex items-center gap-1"
                                            >
                                                <Check :size="12" />
                                                Ready
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <!-- Paste code textarea -->
                                <div v-else class="relative">
                                    <textarea
                                        v-model="form.svg_code"
                                        placeholder='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">...</svg>'
                                        class="w-full px-4 py-3 bg-bg border rounded-xl text-xs font-mono text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 resize-none transition-all duration-200"
                                        :class="
                                            errors.svg_code
                                                ? 'border-red-400'
                                                : 'border-border focus:border-accent'
                                        "
                                        style="min-height: 120px"
                                        rows="5"
                                        @input="onPasteInput"
                                    />
                                </div>

                                <p
                                    v-if="errors.svg_code"
                                    class="mt-1 text-xs text-red-500 font-prompt"
                                >
                                    {{ errors.svg_code }}
                                </p>
                            </div>

                            <!-- Name -->
                            <div>
                                <label
                                    class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                >
                                    Name
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.name"
                                    type="text"
                                    placeholder="My SVG name..."
                                    class="w-full px-4 py-2.5 bg-bg border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                                    :class="
                                        errors.name
                                            ? 'border-red-400'
                                            : 'border-border focus:border-accent'
                                    "
                                />
                                <p
                                    v-if="errors.name"
                                    class="mt-1 text-xs text-red-500 font-prompt"
                                >
                                    {{ errors.name }}
                                </p>
                            </div>

                            <!-- Tags -->
                            <div>
                                <label
                                    class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                >
                                    Tags
                                </label>
                                <input
                                    v-model="tagsInput"
                                    type="text"
                                    placeholder="Add tag..."
                                    class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                                    @input="parseTags"
                                />
                                <div
                                    v-if="form.tags.length"
                                    class="flex flex-wrap gap-1.5 mt-2"
                                >
                                    <span
                                        v-for="tag in form.tags"
                                        :key="tag"
                                        class="flex items-center gap-1 bg-soft text-textsecondary rounded-full px-2.5 py-0.5 text-xs font-prompt"
                                    >
                                        {{ tag }}
                                        <button
                                            type="button"
                                            @click="removeTag(tag)"
                                            class="hover:text-primary transition-colors"
                                        >
                                            <X :size="10" />
                                        </button>
                                    </span>
                                </div>
                            </div>

                            <!-- Category -->
                            <div>
                                <label
                                    class="block text-sm font-medium text-textprimary font-prompt mb-1.5"
                                >
                                    Category
                                </label>
                                <div class="relative">
                                    <select
                                        v-model="form.category"
                                        class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 appearance-none transition-all duration-200 pr-10"
                                    >
                                        <option value="">Select category</option>
                                        <option
                                            v-for="cat in categories"
                                            :key="cat"
                                            :value="cat"
                                        >
                                            {{ cat }}
                                        </option>
                                    </select>
                                    <ChevronDown
                                        :size="16"
                                        class="absolute right-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                                    />
                                </div>
                            </div>

                            <!-- Error -->
                            <div
                                v-if="submitError"
                                class="flex items-start gap-2 bg-red-50 border border-red-200 rounded-xl px-4 py-3"
                            >
                                <AlertCircle
                                    :size="16"
                                    class="text-red-500 shrink-0 mt-0.5"
                                />
                                <p class="text-sm text-red-600 font-prompt">
                                    {{ submitError }}
                                </p>
                            </div>
                        </div>
                    </form>

                    <!-- Footer -->
                    <div
                        class="flex items-center justify-end gap-3 px-5 py-4 border-t border-border shrink-0 bg-soft/30"
                    >
                        <button
                            type="button"
                            @click="handleClose"
                            class="px-4 py-2 rounded-xl text-sm font-prompt text-textsecondary hover:text-textprimary hover:bg-soft transition-all duration-150"
                        >
                            Cancel
                        </button>
                        <button
                            type="button"
                            @click="handleSubmit"
                            :disabled="isSubmitting"
                            class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-150"
                        >
                            <Loader2
                                v-if="isSubmitting"
                                :size="15"
                                class="animate-spin"
                            />
                            <Save v-else :size="15" />
                            {{
                                isSubmitting
                                    ? "Saving..."
                                    : "Save"
                            }}
                        </button>
                    </div>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import {
    Upload,
    X,
    FileUp,
    FileCheck,
    ChevronDown,
    AlertCircle,
    Loader2,
    Save,
    Check,
    Code,
} from "lucide-vue-next";
import { useSvgAssets } from "../composables/useSvgAssets";
import { sanitizeSvg } from "../utils/svgUtils";

const props = defineProps<{
    modelValue: boolean;
    userId: string;
}>();

const emit = defineEmits<{
    "update:modelValue": [value: boolean];
    uploaded: [];
}>();

const { create } = useSvgAssets();

const categories = ["Illustration", "Icon", "Logo", "Animation", "Other"];

const fileInput = ref<HTMLInputElement | null>(null);
const isDragging = ref(false);
const isSubmitting = ref(false);
const submitError = ref<string | null>(null);
const tagsInput = ref("");
const inputMode = ref<"file" | "paste">("paste");

const onPasteInput = () => {
    errors.value.svg_code = "";
    submitError.value = null;
};

const form = ref({
    name: "",
    svg_code: "",
    tags: [] as string[],
    category: "",
});

const errors = ref({
    name: "",
    svg_code: "",
});

const previewHtml = computed(() => {
    if (!form.value.svg_code) return "";
    const cleaned = sanitizeSvg(form.value.svg_code);
    return cleaned.replace(
        /<svg/i,
        '<svg style="max-width:100%;max-height:100%;width:auto;height:auto;"',
    );
});

const triggerFileInput = () => {
    fileInput.value?.click();
};

const readSvgFile = (file: File) => {
    if (!file.name.endsWith(".svg") && file.type !== "image/svg+xml") {
        submitError.value = "Please select an .svg file";
        return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
        const content = e.target?.result as string;
        form.value.svg_code = content;
        errors.value.svg_code = "";
        submitError.value = null;
    };
    reader.readAsText(file);
};

const handleFileChange = (e: Event) => {
    const input = e.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) readSvgFile(file);
};

const handleDrop = (e: DragEvent) => {
    isDragging.value = false;
    const file = e.dataTransfer?.files?.[0];
    if (file) readSvgFile(file);
};

const parseTags = () => {
    form.value.tags = tagsInput.value
        .split(",")
        .map((t) => t.trim())
        .filter((t) => t.length > 0);
};

const removeTag = (tag: string) => {
    form.value.tags = form.value.tags.filter((t) => t !== tag);
    tagsInput.value = form.value.tags.join(", ");
};

const validate = (): boolean => {
    errors.value = { name: "", svg_code: "" };
    let valid = true;
    if (!form.value.name.trim()) {
        errors.value.name = "Please enter a name";
        valid = false;
    }
    if (!form.value.svg_code.trim()) {
        errors.value.svg_code = "Please upload an SVG file";
        valid = false;
    } else if (!form.value.svg_code.includes("<svg")) {
        errors.value.svg_code = "Invalid SVG — <svg> tag required";
        valid = false;
    }
    return valid;
};

const handleSubmit = async () => {
    if (!validate()) return;
    isSubmitting.value = true;
    submitError.value = null;
    let saved = false;
    try {
        await create({
            user_id: props.userId,
            name: form.value.name.trim(),
            svg_code: sanitizeSvg(form.value.svg_code),
            tags: form.value.tags,
            category: form.value.category || "Other",
            is_favorite: false,
            is_private: true,
            status: "pending",
        });
        saved = true;
        emit("uploaded");
    } catch (e: unknown) {
        submitError.value =
            e instanceof Error ? e.message : "An error occurred, please try again";
    } finally {
        isSubmitting.value = false;
    }
    if (saved) handleClose();
};

const handleClose = () => {
    if (isSubmitting.value) return;
    resetForm();
    emit("update:modelValue", false);
};

const resetForm = () => {
    form.value = { name: "", svg_code: "", tags: [], category: "" };
    errors.value = { name: "", svg_code: "" };
    tagsInput.value = "";
    submitError.value = null;
    isDragging.value = false;
    inputMode.value = "paste";
    if (fileInput.value) fileInput.value.value = "";
};
</script>

<style scoped>
.modal-enter-active {
    animation: modalIn 0.25s cubic-bezier(0.34, 1.2, 0.64, 1);
}
.modal-leave-active {
    animation: modalOut 0.2s ease-in forwards;
}

@keyframes modalIn {
    from {
        opacity: 0;
    }
    to {
        opacity: 1;
    }
}

@keyframes modalOut {
    from {
        opacity: 1;
    }
    to {
        opacity: 0;
    }
}

.preview-enter-active,
.preview-leave-active {
    transition: all 0.25s ease;
}
.preview-enter-from,
.preview-leave-to {
    opacity: 0;
    transform: scaleY(0.95);
}
</style>
