<template>
    <DefaultLayout>
        <div class="max-w-2xl mx-auto px-4 py-8">
            <!-- Header -->
            <div class="mb-8">
                <div class="flex items-center gap-3 mb-1">
                    <RouterLink
                        to="/collection"
                        class="text-textsecondary hover:text-primary transition-colors duration-150"
                    >
                        <ArrowLeft :size="18" />
                    </RouterLink>
                    <h1
                        class="text-2xl font-semibold text-textprimary font-prompt"
                    >
                        {{ t("settings.title") }}
                    </h1>
                </div>
                <p class="text-sm text-textsecondary font-prompt ml-9">
                    {{ t("settings.backToCollection") }}
                </p>
            </div>

            <!-- Loading skeleton -->
            <div v-if="loading" class="space-y-6">
                <div
                    class="bg-surface rounded-2xl border border-border p-6 animate-pulse space-y-4"
                >
                    <div class="h-5 bg-soft rounded-xl w-32" />
                    <div class="h-10 bg-soft rounded-xl" />
                    <div class="h-10 bg-soft rounded-xl" />
                    <div class="h-24 bg-soft rounded-xl" />
                </div>
            </div>

            <!-- Form -->
            <div v-else class="space-y-6">
                <!-- Avatar preview -->
                <div
                    class="bg-surface rounded-2xl border border-border p-6 flex items-center gap-4"
                >
                    <!-- Avatar display -->
                    <div
                        class="w-16 h-16 rounded-full overflow-hidden flex items-center justify-center shadow-md shrink-0 bg-bg border border-border"
                    >
                        <div
                            v-if="avatarSvgPreview"
                            class="w-full h-full flex items-center justify-center p-0.5"
                            v-html="avatarSvgPreview"
                        />
                        <div
                            v-else
                            class="w-full h-full flex items-center justify-center text-2xl font-bold text-white"
                            :style="{ background: avatarGradient }"
                        >
                            {{ avatarInitial }}
                        </div>
                    </div>
                    <div>
                        <p
                            class="text-sm font-semibold text-textprimary font-prompt"
                        >
                            {{
                                form.display_name ||
                                form.username ||
                                "ผู้ใช้งาน"
                            }}
                        </p>
                        <p
                            class="text-xs text-textsecondary font-prompt mt-0.5"
                        >
                            @{{ form.username || "—" }}
                        </p>
                        <p class="text-xs text-textsecondary font-prompt mt-1">
                            {{
                                avatarSvgPreview
                                    ? "ใช้รูป SVG"
                                    : "Avatar สร้างอัตโนมัติจากชื่อ"
                            }}
                        </p>
                    </div>
                </div>

                <!-- Basic Info -->
                <div
                    class="bg-surface rounded-2xl border border-border p-6 space-y-5"
                >
                    <h2
                        class="text-sm font-semibold text-textprimary font-prompt flex items-center gap-2"
                    >
                        <UserCircle2 :size="16" class="text-accent" />
                        {{ t("settings.profileSection.title") }}
                    </h2>

                    <!-- Display Name -->
                    <div>
                        <label
                            class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            {{ t("settings.profileSection.displayNameLabel") }}
                        </label>
                        <input
                            v-model="form.display_name"
                            type="text"
                            :placeholder="
                                t(
                                    'settings.profileSection.displayNamePlaceholder',
                                )
                            "
                            maxlength="60"
                            class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                        />
                    </div>

                    <!-- Username -->
                    <div>
                        <label
                            class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            Username <span class="text-red-500">*</span>
                        </label>
                        <div class="relative">
                            <AtSign
                                :size="16"
                                class="absolute left-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                            />
                            <input
                                v-model="form.username"
                                type="text"
                                placeholder="your_username"
                                maxlength="30"
                                class="w-full pl-9 pr-10 py-2.5 bg-bg border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                                :class="
                                    usernameError
                                        ? 'border-red-400'
                                        : usernameOk
                                          ? 'border-accent'
                                          : 'border-border focus:border-accent'
                                "
                                @blur="validateUsername"
                                @input="onUsernameInput"
                            />
                            <!-- Status icon -->
                            <div
                                class="absolute right-3 top-1/2 -translate-y-1/2"
                            >
                                <Loader2
                                    v-if="checkingUsername"
                                    :size="15"
                                    class="text-textsecondary animate-spin"
                                />
                                <Check
                                    v-else-if="usernameOk"
                                    :size="15"
                                    class="text-accent"
                                />
                                <X
                                    v-else-if="usernameError"
                                    :size="15"
                                    class="text-red-500"
                                />
                            </div>
                        </div>
                        <p
                            v-if="usernameError"
                            class="mt-1 text-xs text-red-500 font-prompt"
                        >
                            {{ usernameError }}
                        </p>
                        <p
                            v-else-if="
                                usernameOk && form.username !== originalUsername
                            "
                            class="mt-1 text-xs text-accent font-prompt flex items-center gap-1"
                        >
                            <Check :size="12" />
                            {{ t("settings.profileSection.usernameAvailable") }}
                        </p>
                        <p
                            v-else
                            class="mt-1 text-xs text-textsecondary font-prompt"
                        >
                            {{ t("settings.profileSection.usernameInvalid") }} —
                            URL: /profile/{{ form.username || "..." }}
                        </p>
                    </div>

                    <!-- Bio -->
                    <div>
                        <label
                            class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            {{ t("settings.profileSection.bioLabel") }}
                            <span class="text-textsecondary font-normal"
                                >({{
                                    t("settings.profileSection.bioOptional")
                                }})</span
                            >
                        </label>
                        <textarea
                            v-model="form.bio"
                            rows="3"
                            :placeholder="
                                t('settings.profileSection.bioPlaceholder')
                            "
                            maxlength="300"
                            class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200 resize-none"
                        />
                        <p
                            class="mt-1 text-xs text-textsecondary font-prompt text-right"
                        >
                            {{ form.bio?.length ?? 0 }} / 300
                        </p>
                    </div>
                </div>

                <!-- Avatar SVG -->
                <div
                    class="bg-surface rounded-2xl border border-border p-6 space-y-4"
                >
                    <h2
                        class="text-sm font-semibold text-textprimary font-prompt flex items-center gap-2"
                    >
                        <ImageIcon :size="16" class="text-accent" />
                        {{ t("settings.avatarSection.title") }}
                    </h2>
                    <p class="text-xs text-textsecondary font-prompt">
                        {{ t("settings.avatarSection.description") }}
                    </p>
                    <!-- Textarea -->
                    <div>
                        <label
                            class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            {{ t("settings.avatarSection.pasteLabel") }}
                            <span class="text-textsecondary font-normal"
                                >({{
                                    t("settings.profileSection.bioOptional")
                                }})</span
                            >
                        </label>
                        <textarea
                            v-model="avatarSvgInput"
                            rows="5"
                            :placeholder="
                                t('settings.avatarSection.pastePlaceholder')
                            "
                            class="w-full px-4 py-3 bg-bg border border-border rounded-xl text-xs font-mono text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200 resize-none"
                            :class="
                                avatarSvgError
                                    ? 'border-red-400'
                                    : 'border-border'
                            "
                            @input="validateAvatarSvg"
                        />
                        <p
                            v-if="avatarSvgError"
                            class="mt-1 text-xs text-red-500 font-prompt"
                        >
                            {{ avatarSvgError }}
                        </p>
                        <p
                            v-else
                            class="mt-1 text-xs text-textsecondary font-prompt"
                        >
                            {{ t("settings.avatarSection.pasteNote") }}
                        </p>
                    </div>
                    <!-- Preview -->
                    <div
                        v-if="avatarSvgPreview"
                        class="flex items-center gap-4"
                    >
                        <div
                            class="w-16 h-16 rounded-full overflow-hidden border border-border bg-bg flex items-center justify-center shrink-0"
                        >
                            <div
                                class="w-full h-full flex items-center justify-center p-0.5"
                                v-html="avatarSvgPreview"
                            />
                        </div>
                        <div class="text-xs text-textsecondary font-prompt">
                            <p class="font-medium text-accent flex items-center gap-1">
                                <Check :size="12" />
                                {{ t("settings.avatarSection.previewLabel") }}
                            </p>
                            <p class="mt-0.5">
                                {{ t("settings.avatarSection.noPreview") }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Contact Info -->
                <div
                    class="bg-surface rounded-2xl border border-border p-6 space-y-5"
                >
                    <h2
                        class="text-sm font-semibold text-textprimary font-prompt flex items-center gap-2"
                    >
                        <ContactRound :size="16" class="text-accent" />
                        {{ t("settings.socialSection.title") }}
                        <span class="text-textsecondary font-normal"
                            >({{ t("settings.socialSection.optional") }})</span
                        >
                    </h2>

                    <!-- Website -->
                    <div>
                        <label
                            class="flex items-center gap-1.5 text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            <Globe :size="14" class="text-textsecondary" />
                            เว็บไซต์ / Portfolio
                        </label>
                        <input
                            v-model="form.website"
                            type="url"
                            placeholder="https://yourwebsite.com"
                            class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                        />
                    </div>

                    <!-- GitHub -->
                    <div>
                        <label
                            class="flex items-center gap-1.5 text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            <Github :size="14" class="text-textsecondary" />
                            GitHub Username
                        </label>
                        <div class="relative">
                            <span
                                class="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-textsecondary font-prompt pointer-events-none"
                            >
                                github.com/
                            </span>
                            <input
                                v-model="form.github"
                                type="text"
                                placeholder="yourusername"
                                maxlength="39"
                                class="w-full pl-24 pr-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                            />
                        </div>
                    </div>

                    <!-- Twitter / X -->
                    <div>
                        <label
                            class="flex items-center gap-1.5 text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            <Twitter :size="14" class="text-textsecondary" />
                            Twitter / X
                        </label>
                        <div class="relative">
                            <span
                                class="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-textsecondary font-prompt pointer-events-none"
                            >
                                @
                            </span>
                            <input
                                v-model="form.twitter"
                                type="text"
                                placeholder="yourhandle"
                                maxlength="50"
                                class="w-full pl-7 pr-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                            />
                        </div>
                    </div>

                    <!-- Instagram -->
                    <div>
                        <label
                            class="flex items-center gap-1.5 text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            <Instagram :size="14" class="text-textsecondary" />
                            Instagram
                        </label>
                        <div class="relative">
                            <span
                                class="absolute left-3 top-1/2 -translate-y-1/2 text-xs text-textsecondary font-prompt pointer-events-none"
                            >
                                @
                            </span>
                            <input
                                v-model="form.instagram"
                                type="text"
                                placeholder="yourhandle"
                                maxlength="30"
                                class="w-full pl-7 pr-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                            />
                        </div>
                    </div>

                    <!-- Phone -->
                    <div>
                        <label
                            class="flex items-center gap-1.5 text-sm font-medium text-textprimary mb-1.5 font-prompt"
                        >
                            <Phone :size="14" class="text-textsecondary" />
                            เบอร์โทรศัพท์
                        </label>
                        <input
                            v-model="form.phone"
                            type="tel"
                            placeholder="เช่น 081-234-5678"
                            maxlength="20"
                            class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition-all duration-200"
                        />
                    </div>
                </div>

                <!-- Error / Success toast inline -->
                <Transition name="fade">
                    <div
                        v-if="saveError"
                        class="flex items-start gap-2.5 bg-red-50 border border-red-200 rounded-xl px-4 py-3"
                    >
                        <AlertCircle
                            :size="16"
                            class="text-red-500 shrink-0 mt-0.5"
                        />
                        <p class="text-sm text-red-600 font-prompt">
                            {{ saveError }}
                        </p>
                    </div>
                </Transition>

                <Transition name="fade">
                    <div
                        v-if="saveSuccess"
                        class="flex items-start gap-2.5 bg-accent/10 border border-accent/30 rounded-xl px-4 py-3"
                    >
                        <CheckCircle
                            :size="16"
                            class="text-accent shrink-0 mt-0.5"
                        />
                        <p class="text-sm text-accent font-prompt">
                            {{ t("settings.success.saved") }}
                        </p>
                    </div>
                </Transition>

                <!-- Action buttons -->
                <div class="flex items-center justify-between gap-3 pb-8">
                    <RouterLink
                        v-if="user?.username"
                        :to="`/profile/${user.username}`"
                        class="flex items-center gap-1.5 text-sm font-prompt text-textsecondary hover:text-accent transition-colors duration-150"
                    >
                        <ExternalLink :size="14" />
                        {{ t("settings.viewProfile") }}
                    </RouterLink>
                    <div v-else />

                    <button
                        @click="handleSave"
                        :disabled="
                            isSaving || !!usernameError || checkingUsername
                        "
                        class="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 shadow-sm hover:shadow-md transition-all duration-200 disabled:opacity-60 disabled:cursor-not-allowed"
                    >
                        <Loader2
                            v-if="isSaving"
                            :size="15"
                            class="animate-spin"
                        />
                        <Save v-else :size="15" />
                        {{
                            isSaving
                                ? t("settings.saving")
                                : t("settings.saveBtn")
                        }}
                    </button>
                </div>
            </div>
        </div>
    </DefaultLayout>
</template>

<script setup lang="ts">
import { useI18n } from "../composables/useI18n";
import { ref, computed, onMounted, watch } from "vue";
import { RouterLink } from "vue-router";
import {
    ArrowLeft,
    UserCircle2,
    AtSign,
    Globe,
    Phone,
    Github,
    Twitter,
    Instagram,
    ContactRound,
    Check,
    X,
    Loader2,
    Save,
    AlertCircle,
    CheckCircle,
    ExternalLink,
    ImageIcon,
} from "lucide-vue-next";
import DefaultLayout from "../layouts/DefaultLayout.vue";
import { useAuth } from "../composables/useAuth";
import { useProfile } from "../composables/useProfile";

const { t } = useI18n();
const { user, fetchUser } = useAuth();
const {
    profile,
    loading,
    fetchProfileById,
    updateProfile,
    checkUsernameAvailable,
} = useProfile();

// ── Form state ────────────────────────────────────────────────────────────

const form = ref({
    display_name: "",
    username: "",
    bio: "",
    website: "",
    github: "",
    twitter: "",
    instagram: "",
    phone: "",
});

const originalUsername = ref("");
const isSaving = ref(false);
const saveError = ref("");
const saveSuccess = ref(false);
const avatarSvgInput = ref("");
const avatarSvgError = ref("");

// Username validation state
const usernameError = ref("");
const usernameOk = ref(false);
const checkingUsername = ref(false);
let usernameDebounceTimer: ReturnType<typeof setTimeout> | null = null;

// ── Computed ──────────────────────────────────────────────────────────────

const avatarInitial = computed(() => {
    const name = form.value.display_name || form.value.username || "?";
    return name.charAt(0).toUpperCase();
});

const avatarGradient = computed(() => {
    const name = form.value.username || "user";
    const palettes = [
        "linear-gradient(135deg, #00cec9, #0984e3)",
        "linear-gradient(135deg, #6c5ce7, #a29bfe)",
        "linear-gradient(135deg, #fd79a8, #e84393)",
        "linear-gradient(135deg, #00b894, #00cec9)",
        "linear-gradient(135deg, #e17055, #fdcb6e)",
        "linear-gradient(135deg, #74b9ff, #0984e3)",
        "linear-gradient(135deg, #55efc4, #00b894)",
        "linear-gradient(135deg, #fab1a0, #e17055)",
    ];
    const idx =
        name.split("").reduce((acc, c) => acc + c.charCodeAt(0), 0) %
        palettes.length;
    return palettes[idx];
});

const avatarSvgPreview = computed(() => {
    if (!avatarSvgInput.value.trim()) return "";
    const cleaned = avatarSvgInput.value
        .trim()
        .replace(/<script[\s\S]*?<\/script>/gi, "")
        .replace(/on\w+="[^"]*"/gi, "")
        .replace(/on\w+='[^']*'/gi, "")
        .replace(/javascript:/gi, "");
    if (!/<svg[\s>]/i.test(cleaned)) return "";
    return cleaned.replace(
        /<svg/i,
        '<svg style="width:100%;height:100%;max-width:100%;max-height:100%;"',
    );
});

const validateAvatarSvg = (): boolean => {
    avatarSvgError.value = "";
    if (!avatarSvgInput.value.trim()) return true;
    if (!/<svg[\s>]/i.test(avatarSvgInput.value)) {
        avatarSvgError.value = "ไม่พบ SVG tag — กรุณาวาง SVG code ที่ถูกต้อง";
        return false;
    }
    return true;
};

// ── Username validation ───────────────────────────────────────────────────

const validateUsernameFormat = (val: string): string => {
    if (!val.trim()) return "กรุณากรอก Username";
    if (val.trim().length < 3) return "Username ต้องมีอย่างน้อย 3 ตัวอักษร";
    if (val.trim().length > 30) return "Username ต้องไม่เกิน 30 ตัวอักษร";
    if (!/^[a-zA-Z0-9_]+$/.test(val.trim()))
        return "Username ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ _ เท่านั้น";
    return "";
};

const validateUsername = async () => {
    const val = form.value.username.trim();
    const formatError = validateUsernameFormat(val);
    if (formatError) {
        usernameError.value = formatError;
        usernameOk.value = false;
        return;
    }

    // Same as original — no need to check uniqueness
    if (val === originalUsername.value) {
        usernameError.value = "";
        usernameOk.value = true;
        return;
    }

    checkingUsername.value = true;
    usernameError.value = "";
    usernameOk.value = false;

    try {
        const available = await checkUsernameAvailable(val, user.value?.id);
        if (available) {
            usernameOk.value = true;
        } else {
            usernameError.value = "Username นี้ถูกใช้งานแล้ว กรุณาเลือกใหม่";
        }
    } finally {
        checkingUsername.value = false;
    }
};

const onUsernameInput = () => {
    usernameOk.value = false;
    usernameError.value = "";
    if (usernameDebounceTimer) clearTimeout(usernameDebounceTimer);
    usernameDebounceTimer = setTimeout(() => {
        validateUsername();
    }, 600);
};

// ── Save ──────────────────────────────────────────────────────────────────

const handleSave = async () => {
    if (!user.value) return;

    // Validate username before saving
    await validateUsername();
    if (usernameError.value) return;
    if (!validateAvatarSvg()) return;

    saveError.value = "";
    saveSuccess.value = false;
    isSaving.value = true;

    try {
        await updateProfile(user.value.id, {
            display_name:
                form.value.display_name.trim() || (null as unknown as string),
            username: form.value.username.trim(),
            bio: form.value.bio.trim() || (null as unknown as string),
            website: form.value.website.trim() || (null as unknown as string),
            github: form.value.github.trim() || (null as unknown as string),
            twitter: form.value.twitter.trim() || (null as unknown as string),
            instagram:
                form.value.instagram.trim() || (null as unknown as string),
            phone: form.value.phone.trim() || (null as unknown as string),
            avatar_svg:
                avatarSvgInput.value.trim() || (null as unknown as string),
        });

        originalUsername.value = form.value.username.trim();
        usernameOk.value = true;

        // Refresh auth user so Navbar reflects new username
        await fetchUser();

        saveSuccess.value = true;
        setTimeout(() => {
            saveSuccess.value = false;
        }, 3000);
    } catch (e: unknown) {
        saveError.value =
            e instanceof Error
                ? e.message
                : "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง";
    } finally {
        isSaving.value = false;
    }
};

// ── Populate form from profile ────────────────────────────────────────────

watch(profile, (p) => {
    if (!p) return;
    form.value.display_name = p.display_name ?? "";
    form.value.username = p.username ?? "";
    form.value.bio = p.bio ?? "";
    form.value.website = p.website ?? "";
    form.value.github = p.github ?? "";
    form.value.twitter = p.twitter ?? "";
    form.value.instagram = p.instagram ?? "";
    form.value.phone = p.phone ?? "";
    avatarSvgInput.value = p.avatar_svg ?? "";
    originalUsername.value = p.username ?? "";
    // If username is set, mark it as OK initially
    if (p.username) usernameOk.value = true;
});

// ── Lifecycle ─────────────────────────────────────────────────────────────

onMounted(async () => {
    if (user.value) {
        await fetchProfileById(user.value.id);
    }
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition:
        opacity 0.25s ease,
        transform 0.25s ease;
}
.fade-enter-from,
.fade-leave-to {
    opacity: 0;
    transform: translateY(-4px);
}
</style>
