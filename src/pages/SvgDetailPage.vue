<template>
    <DefaultLayout>
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 font-prompt">
            <!-- Back Button -->
            <div class="mb-6">
                <button
                    @click="router.back()"
                    class="inline-flex items-center gap-2 text-sm font-prompt text-textsecondary hover:text-primary transition-colors duration-200 group"
                >
                    <ArrowLeft
                        :size="16"
                        class="group-hover:-translate-x-0.5 transition-transform duration-200"
                    />
                    {{ t("svgDetail.backBtn") }}
                </button>
            </div>

            <!-- Loading State -->
            <div v-if="loading" class="grid md:grid-cols-2 gap-8">
                <div
                    class="bg-surface rounded-2xl border border-border p-8 animate-pulse flex items-center justify-center min-h-[320px]"
                >
                    <div class="w-32 h-32 bg-soft rounded-xl"></div>
                </div>
                <div class="space-y-4 animate-pulse">
                    <div class="h-7 bg-soft rounded-full w-2/3"></div>
                    <div class="h-4 bg-soft rounded-full w-1/3"></div>
                    <div class="h-4 bg-soft rounded-full w-1/2"></div>
                    <div class="flex gap-2 mt-4">
                        <div class="h-8 w-20 bg-soft rounded-full"></div>
                        <div class="h-8 w-20 bg-soft rounded-full"></div>
                    </div>
                </div>
            </div>

            <!-- Not Found State -->
            <div
                v-else-if="!asset"
                class="flex flex-col items-center justify-center py-24 text-center"
            >
                <div
                    class="w-20 h-20 rounded-2xl bg-soft flex items-center justify-center mb-5"
                >
                    <FileX :size="36" class="text-textsecondary" />
                </div>
                <h2 class="text-xl font-semibold text-primary font-prompt mb-2">
                    {{ t("svgDetail.notFoundTitle") }}
                </h2>
                <p class="text-sm text-textsecondary font-prompt mb-6">
                    {{ t("svgDetail.notFoundDesc") }}
                </p>
                <RouterLink
                    to="/"
                    class="inline-flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 transition-all duration-200"
                >
                    <Home :size="16" />
                    {{ t("svgDetail.backToHome") }}
                </RouterLink>
            </div>

            <!-- Main Content -->
            <div v-else class="grid md:grid-cols-2 gap-8">
                <!-- Left: SVG Preview -->
                <div>
                    <div
                        class="rounded-2xl border border-border p-8 flex items-center justify-center min-h-[320px] relative group shadow-sm transition-colors duration-200"
                        :style="{ background: previewBackgroundStyle }"
                    >
                        <!-- SVG Preview -->
                        <div
                            class="w-full h-full flex items-center justify-center"
                            v-html="sanitizedSvg"
                        />
                        <!-- Zoom hint -->
                        <div
                            class="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
                        >
                            <span
                                class="text-xs font-prompt text-textsecondary bg-soft px-2 py-1 rounded-lg"
                                >SVG Preview</span
                            >
                        </div>
                    </div>

                    <!-- Background picker (preview only) -->
                    <div class="mt-4">
                        <label
                            class="block text-sm font-medium text-textprimary font-prompt mb-2"
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

                    <!-- Code Preview Toggle -->
                    <div class="mt-4">
                        <button
                            @click="showCode = !showCode"
                            class="flex items-center gap-2 text-sm font-prompt text-textsecondary hover:text-primary transition-colors duration-200 w-full bg-surface border border-border rounded-xl px-4 py-2.5 hover:border-accent/60"
                        >
                            <Code :size="15" />
                            {{
                                showCode
                                    ? t("svgDetail.hideCode")
                                    : t("svgDetail.showCode")
                            }}
                            <ChevronDown
                                :size="15"
                                class="ml-auto transition-transform duration-200"
                                :class="showCode ? 'rotate-180' : ''"
                            />
                        </button>
                        <Transition name="code-expand">
                            <div
                                v-if="showCode"
                                class="mt-2 bg-primary rounded-xl overflow-hidden"
                            >
                                <div
                                    class="flex items-center justify-between px-4 py-2 border-b border-white/10"
                                >
                                    <span
                                        class="text-xs font-prompt text-white/50"
                                        >SVG Code</span
                                    >
                                    <button
                                        @click="handleCopy"
                                        class="flex items-center gap-1.5 text-xs font-prompt text-white/70 hover:text-white transition-colors"
                                    >
                                        <Check v-if="copied" :size="13" />
                                        <Copy v-else :size="13" />
                                        {{
                                            copied
                                                ? t("svgDetail.copiedCode")
                                                : t("svgDetail.copyCode")
                                        }}
                                    </button>
                                </div>
                                <pre
                                    class="px-4 py-3 text-xs text-white/80 overflow-x-auto max-h-48 font-mono leading-relaxed whitespace-pre-wrap break-all"
                                    >{{ asset.svg_code }}</pre
                                >
                            </div>
                        </Transition>
                    </div>
                </div>

                <!-- Right: Info & Actions -->
                <div class="space-y-6">
                    <!-- Name + Category -->
                    <div>
                        <div
                            class="flex items-start justify-between gap-3 mb-2"
                        >
                            <h1
                                class="text-2xl font-semibold text-textprimary font-prompt leading-tight break-words"
                            >
                                {{ asset.name }}
                            </h1>
                            <span
                                v-if="asset.category"
                                class="shrink-0 text-xs font-prompt text-accent bg-accent/10 px-3 py-1 rounded-full mt-1"
                            >
                                {{ asset.category }}
                            </span>
                        </div>
                        <p
                            class="text-xs font-prompt text-textsecondary flex items-center gap-1.5"
                        >
                            <Calendar :size="12" />
                            {{ t("svgDetail.createdAt") }}
                            {{ formatDate(asset.created_at) }}
                        </p>
                        <!-- Creator Attribution -->
                        <RouterLink
                            v-if="asset.creator?.username"
                            :to="`/profile/${asset.creator.username}`"
                            class="mt-2 inline-flex items-center gap-1.5 text-xs font-prompt text-textsecondary hover:text-accent transition-colors duration-150 group/creator"
                        >
                            <User2 :size="13" class="shrink-0" />
                            <span>{{ t("svgDetail.by") }}</span>
                            <span
                                class="font-medium text-accent group-hover/creator:underline"
                            >
                                @{{ asset.creator.username }}
                            </span>
                            <ExternalLink
                                :size="11"
                                class="opacity-50 group-hover/creator:opacity-100"
                            />
                        </RouterLink>
                        <p
                            v-else-if="asset.creator?.display_name"
                            class="mt-2 text-xs font-prompt text-textsecondary flex items-center gap-1.5"
                        >
                            <User2 :size="13" />
                            {{ t("svgDetail.by") }}
                            {{ asset.creator.display_name }}
                        </p>
                    </div>

                    <!-- Tags -->
                    <div v-if="asset.tags && asset.tags.length">
                        <p
                            class="text-sm font-medium text-textprimary font-prompt mb-2 flex items-center gap-1.5"
                        >
                            <Tag :size="14" class="text-textsecondary" />
                            {{ t("svgDetail.tags") }}
                        </p>
                        <div class="flex flex-wrap gap-2">
                            <span
                                v-for="tag in asset.tags"
                                :key="tag"
                                class="bg-soft text-textsecondary rounded-full px-3 py-1 text-xs font-prompt hover:bg-accent/10 hover:text-accent transition-colors cursor-default"
                            >
                                {{ tag }}
                            </span>
                        </div>
                    </div>

                    <!-- Favorite Status -->
                    <div
                        v-if="asset.is_favorite"
                        class="flex items-center gap-2 text-sm font-prompt text-red-400 bg-red-50 px-3 py-2 rounded-xl"
                    >
                        <Heart :size="14" fill="currentColor" />
                        อยู่ในรายการโปรด
                    </div>

                    <!-- Visibility / Approval Status Badges -->
                    <div class="flex flex-wrap items-center gap-2">
                        <span
                            v-if="asset.status === 'pending'"
                            class="inline-flex items-center gap-1.5 text-xs font-prompt font-medium text-orange-600 bg-orange-50 border border-orange-200 px-2.5 py-1 rounded-full"
                        >
                            <Clock :size="12" />
                            Pending
                        </span>
                        <span
                            v-else-if="asset.status === 'rejected'"
                            class="inline-flex items-center gap-1.5 text-xs font-prompt font-medium text-red-600 bg-red-50 border border-red-200 px-2.5 py-1 rounded-full"
                        >
                            <X :size="12" />
                            Rejected
                        </span>
                        <span
                            v-else-if="asset.is_private"
                            class="inline-flex items-center gap-1.5 text-xs font-prompt font-medium text-secondary bg-soft border border-border px-2.5 py-1 rounded-full"
                        >
                            <Lock :size="12" />
                            Private
                        </span>
                        <span
                            v-else
                            class="inline-flex items-center gap-1.5 text-xs font-prompt font-medium text-green-600 bg-green-50 border border-green-200 px-2.5 py-1 rounded-full"
                        >
                            <Check :size="12" />
                            Public
                        </span>
                    </div>

                    <!-- Action Buttons -->
                    <div class="space-y-3">
                        <p
                            class="text-sm font-medium text-textprimary font-prompt"
                        >
                            การดำเนินการ
                        </p>

                        <div class="grid grid-cols-2 gap-3">
                            <!-- Download -->
                            <button
                                @click="handleDownload"
                                class="flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 shadow-sm hover:shadow-md transition-all duration-200"
                            >
                                <Download :size="16" />
                                Download
                            </button>

                            <!-- Copy SVG Code -->
                            <button
                                @click="handleCopy"
                                :class="[
                                    'flex items-center justify-center gap-2 px-4 py-3 rounded-2xl text-sm font-prompt font-medium border transition-all duration-200',
                                    copied
                                        ? 'bg-accent text-white border-accent shadow-sm'
                                        : 'bg-surface text-primary border-border hover:border-accent hover:text-accent',
                                ]"
                            >
                                <Check v-if="copied" :size="16" />
                                <Copy v-else :size="16" />
                                {{
                                    copied
                                        ? t("svgDetail.actions.copied")
                                        : t("svgDetail.actions.copy")
                                }}
                            </button>
                        </div>

                        <!-- Favorite Toggle (for logged in users) -->
                        <button
                            v-if="currentUser"
                            @click="handleFavoriteToggle"
                            :disabled="favoriteLoading"
                            :class="[
                                'w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-2xl text-sm font-prompt font-medium border transition-all duration-200 disabled:opacity-50',
                                asset.is_favorite
                                    ? 'bg-red-50 text-red-400 border-red-200 hover:bg-red-100'
                                    : 'bg-surface text-secondary border-border hover:border-red-300 hover:text-red-400 hover:bg-red-50',
                            ]"
                        >
                            <Loader2
                                v-if="favoriteLoading"
                                :size="15"
                                class="animate-spin"
                            />
                            <Heart
                                v-else
                                :size="15"
                                :fill="
                                    asset.is_favorite ? 'currentColor' : 'none'
                                "
                            />
                            {{
                                asset.is_favorite
                                    ? t("svgDetail.actions.removeFavorite")
                                    : t("svgDetail.actions.addFavorite")
                            }}
                        </button>
                    </div>

                    <!-- Owner / Admin Actions -->
                    <div
                        v-if="canManage"
                        class="pt-2 border-t border-border space-y-3"
                    >
                        <p
                            class="text-sm font-medium text-textprimary font-prompt flex items-center gap-1.5"
                        >
                            <Shield :size="14" class="text-textsecondary" />
                            {{ t("svgDetail.owner.edit") }} /
                            {{ t("svgDetail.owner.delete") }}
                            <span
                                v-if="isAdmin && !isOwner"
                                class="text-xs font-normal text-purple-600 bg-purple-50 px-2 py-0.5 rounded-full"
                                >Admin</span
                            >
                            <span
                                v-else
                                class="text-xs font-normal text-textsecondary"
                                >(เจ้าของ)</span
                            >
                        </p>
                        <div class="grid grid-cols-2 gap-2 sm:gap-3">
                            <!-- Edit -->
                            <button
                                @click="openEditModal"
                                class="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 rounded-full bg-soft text-primary text-xs sm:text-sm font-prompt font-medium hover:bg-primary hover:text-white transition-all duration-200 whitespace-nowrap"
                            >
                                <Pencil :size="15" />
                                {{ t("svgDetail.owner.edit") }}
                            </button>

                            <!-- Delete -->
                            <button
                                @click="confirmDeleteOpen = true"
                                class="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 rounded-full bg-red-50 text-red-500 text-xs sm:text-sm font-prompt font-medium hover:bg-red-500 hover:text-white transition-all duration-200 border border-red-200 hover:border-red-500 whitespace-nowrap"
                            >
                                <Trash2 :size="15" />
                                {{ t("svgDetail.owner.delete") }}
                            </button>
                        </div>
                    </div>

                    <!-- Admin Approval Actions -->
                    <div
                        v-if="isAdmin && canManage && (asset.status !== 'approved' || asset.is_private)"
                        class="bg-purple-50/60 border border-purple-200 rounded-2xl p-4 space-y-3"
                    >
                        <div class="flex items-center justify-between gap-2">
                            <p
                                class="text-sm font-semibold text-purple-700 font-prompt flex items-center gap-1.5"
                            >
                                <Shield :size="14" class="text-purple-500" />
                                Review
                            </p>
                            <span
                                class="text-[10px] font-prompt font-semibold text-purple-700 bg-white border border-purple-200 px-2 py-0.5 rounded-full uppercase tracking-wide"
                            >Admin</span>
                        </div>

                        <!-- Status actions: Approve / Reject (only if not yet approved) -->
                        <div
                            v-if="asset.status === 'pending' || asset.status === 'rejected'"
                            class="grid grid-cols-2 gap-2 sm:gap-3"
                        >
                            <button
                                v-if="asset.status === 'pending' || asset.status === 'rejected'"
                                @click="openReviewModal('approve')"
                                :disabled="adminActionLoading"
                                class="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 rounded-full bg-white text-green-500 text-xs sm:text-sm font-prompt font-medium hover:bg-green-500 hover:text-white border border-green-200 transition-all duration-200 disabled:opacity-50 whitespace-nowrap"
                            >
                                <Check :size="15" />
                                Approve
                            </button>
                            <button
                                v-if="asset.status === 'pending' || asset.status === 'rejected'"
                                @click="openReviewModal('reject')"
                                :disabled="adminActionLoading"
                                class="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 rounded-full bg-white text-orange-500 text-xs sm:text-sm font-prompt font-medium hover:bg-orange-500 hover:text-white border border-orange-200 transition-all duration-200 disabled:opacity-50 whitespace-nowrap"
                            >
                                <XCircle :size="15" />
                                Reject
                            </button>
                        </div>

                        <!-- Visibility toggle (only when approved) -->
                        <div
                            v-if="asset.status === 'approved'"
                            class="pt-2 border-t border-purple-200/70 space-y-2"
                        >
                            <p
                                class="text-xs text-purple-700 font-prompt flex items-center gap-1.5"
                            >
                                <Eye :size="13" class="text-purple-500" />
                                Visibility
                            </p>
                            <button
                                @click="handleToggleVisibility"
                                :disabled="adminActionLoading"
                                :class="[
                                    'w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-prompt font-medium border transition-all duration-200 disabled:opacity-50',
                                    asset.is_private
                                        ? 'bg-purple-500 text-white border-purple-500 hover:bg-purple-600 shadow-sm'
                                        : 'bg-white text-purple-600 border-purple-200 hover:bg-purple-500 hover:text-white',
                                ]"
                            >
                                <Loader2
                                    v-if="adminActionLoading"
                                    :size="15"
                                    class="animate-spin"
                                />
                                <Unlock
                                    v-else-if="!asset.is_private"
                                    :size="15"
                                    class="-scale-x-100"
                                />
                                <Lock v-else :size="15" />
                                {{
                                    asset.is_private
                                        ? "Make Public"
                                        : "Make Private"
                                }}
                            </button>
                            <p
                                class="text-[11px] text-purple-600/80 font-prompt leading-relaxed"
                            >
                                {{
                                    asset.is_private
                                        ? "Currently private — only the owner can see this."
                                        : "Currently public — visible in the home page."
                                }}
                            </p>
                        </div>
                    </div>

                    <!-- Login CTA -->
                    <div
                        v-if="!currentUser"
                        class="bg-soft rounded-2xl px-4 py-4 flex items-center gap-3"
                    >
                        <div
                            class="w-9 h-9 rounded-xl bg-accent/10 flex items-center justify-center shrink-0"
                        >
                            <LogIn :size="16" class="text-accent" />
                        </div>
                        <div>
                            <p
                                class="text-sm font-medium text-textprimary font-prompt"
                            >
                                {{ t("svgDetail.loginPrompt.title") }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t("svgDetail.loginPrompt.description") }}
                            </p>
                        </div>
                        <RouterLink
                            to="/login"
                            class="ml-auto shrink-0 px-3 py-1.5 rounded-xl bg-accent text-white text-xs font-prompt font-medium hover:bg-accent/90 transition-colors"
                        >
                            {{ t("svgDetail.loginPrompt.loginBtn") }}
                        </RouterLink>
                    </div>
                </div>
            </div>

            <!-- Edit Modal -->
            <Teleport to="body">
                <Transition name="modal">
                    <div
                        v-if="editModalOpen"
                        class="fixed inset-0 z-50 flex items-start justify-center bg-black/40 backdrop-blur-sm overflow-y-auto py-8 px-4"
                        @click.self="closeEditModal"
                    >
                        <div
                            class="bg-surface rounded-2xl shadow-xl w-full max-w-lg font-prompt"
                        >
                            <!-- Edit Header -->
                            <div
                                class="flex items-center justify-between p-6 border-b border-border"
                            >
                                <div class="flex items-center gap-3">
                                    <div
                                        class="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center"
                                    >
                                        <Pencil
                                            :size="17"
                                            class="text-primary"
                                        />
                                    </div>
                                    <h2
                                        class="text-lg font-semibold text-textprimary font-prompt"
                                    >
                                        {{ t("svgDetail.editModal.title") }}
                                    </h2>
                                </div>
                                <button
                                    @click="closeEditModal"
                                    class="p-2 rounded-xl text-textsecondary hover:text-primary hover:bg-soft transition-all duration-200"
                                >
                                    <X :size="18" />
                                </button>
                            </div>

                            <form
                                @submit.prevent="handleUpdate"
                                class="p-6 space-y-5"
                            >
                                <!-- Name -->
                                <div>
                                    <label
                                        class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                                    >
                                        {{ t("svgDetail.editModal.nameLabel") }}
                                        <span class="text-red-500">*</span>
                                    </label>
                                    <input
                                        v-model="editForm.name"
                                        type="text"
                                        required
                                        class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                                    />
                                </div>

                                <!-- SVG Code -->
                                <div>
                                    <label
                                        class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                                    >
                                        SVG Code
                                        <span class="text-red-500">*</span>
                                    </label>
                                    <textarea
                                        v-model="editForm.svg_code"
                                        rows="5"
                                        required
                                        class="w-full px-3 py-2.5 bg-bg border border-border rounded-xl text-xs font-mono text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 resize-none transition-all duration-200"
                                    />
                                    <!-- Live preview -->
                                    <div
                                        v-if="editPreviewHtml"
                                        class="mt-2 bg-bg rounded-xl border border-border p-4 flex items-center justify-center h-24 overflow-hidden"
                                    >
                                        <div
                                            v-html="editPreviewHtml"
                                            class="flex items-center justify-center w-full h-full"
                                        />
                                    </div>
                                </div>

                                <!-- Tags -->
                                <div>
                                    <label
                                        class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                                    >
                                        {{ t("svgDetail.editModal.tagsLabel") }}
                                    </label>
                                    <input
                                        v-model="editTagsInput"
                                        type="text"
                                        :placeholder="
                                            t(
                                                'svgDetail.editModal.tagsPlaceholder',
                                            )
                                        "
                                        class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                                        @input="parseEditTags"
                                    />
                                    <div
                                        v-if="editForm.tags.length"
                                        class="flex flex-wrap gap-1.5 mt-2"
                                    >
                                        <span
                                            v-for="tag in editForm.tags"
                                            :key="tag"
                                            class="flex items-center gap-1 bg-soft text-textsecondary rounded-full px-2.5 py-0.5 text-xs font-prompt"
                                        >
                                            {{ tag }}
                                            <button
                                                type="button"
                                                @click="removeEditTag(tag)"
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
                                        class="block text-sm font-medium text-textprimary mb-1.5 font-prompt"
                                        >{{
                                            t(
                                                "svgDetail.editModal.categoryLabel",
                                            )
                                        }}</label
                                    >
                                    <div class="relative">
                                        <select
                                            v-model="editForm.category"
                                            class="w-full px-4 py-2.5 bg-bg border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 appearance-none transition-all duration-200 pr-10"
                                        >
                                            <option value="">
                                                {{
                                                    t(
                                                        "svgDetail.editModal.categoryDefault",
                                                    )
                                                }}
                                            </option>
                                            <option
                                                v-for="cat in categories"
                                                :key="cat"
                                                :value="cat"
                                            >
                                                {{ cat }}
                                            </option>
                                        </select>
                                        <ChevronDown
                                            :size="15"
                                            class="absolute right-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                                        />
                                    </div>
                                </div>

                                <!-- Edit Error -->
                                <div
                                    v-if="editError"
                                    class="flex items-start gap-2 bg-red-50 border border-red-200 rounded-xl px-4 py-3"
                                >
                                    <AlertCircle
                                        :size="15"
                                        class="text-red-500 shrink-0 mt-0.5"
                                    />
                                    <p class="text-sm text-red-600 font-prompt">
                                        {{ editError }}
                                    </p>
                                </div>

                                <!-- Actions -->
                                <div class="flex items-center gap-3 pt-1">
                                    <button
                                        type="button"
                                        @click="closeEditModal"
                                        class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200"
                                    >
                                        {{ t("svgDetail.editModal.cancel") }}
                                    </button>
                                    <button
                                        type="submit"
                                        :disabled="isUpdating"
                                        class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 shadow-sm transition-all duration-200 disabled:opacity-60 disabled:cursor-not-allowed"
                                    >
                                        <Loader2
                                            v-if="isUpdating"
                                            :size="15"
                                            class="animate-spin"
                                        />
                                        <Save v-else :size="15" />
                                        {{
                                            isUpdating
                                                ? t(
                                                      "svgDetail.editModal.saving",
                                                  )
                                                : t("svgDetail.editModal.save")
                                        }}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </Transition>
            </Teleport>

            <!-- Delete Confirm Dialog -->
            <Teleport to="body">
                <Transition name="modal">
                    <div
                        v-if="confirmDeleteOpen"
                        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                        @click.self="confirmDeleteOpen = false"
                    >
                        <div
                            class="bg-surface rounded-2xl shadow-xl w-full max-w-sm p-6 font-prompt"
                        >
                            <div class="flex items-center gap-3 mb-4">
                                <div
                                    class="w-10 h-10 rounded-xl bg-red-100 flex items-center justify-center shrink-0"
                                >
                                    <Trash2 :size="18" class="text-red-500" />
                                </div>
                                <div>
                                    <h3
                                        class="text-base font-semibold text-textprimary font-prompt"
                                    >
                                        {{ t("svgDetail.deleteModal.title") }}
                                    </h3>
                                    <p
                                        class="text-xs text-textsecondary font-prompt mt-0.5"
                                    >
                                        {{
                                            t("svgDetail.deleteModal.subtitle")
                                        }}
                                    </p>
                                </div>
                            </div>

                            <div class="bg-red-50 rounded-xl p-3 mb-5">
                                <p class="text-sm font-prompt text-red-700">
                                    {{ t("svgDetail.deleteModal.confirmText") }}
                                    <strong>"{{ asset?.name }}"</strong>?
                                </p>
                            </div>

                            <div class="flex gap-3">
                                <button
                                    @click="confirmDeleteOpen = false"
                                    :disabled="isDeleting"
                                    class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                                >
                                    {{ t("svgDetail.deleteModal.cancel") }}
                                </button>
                                <button
                                    @click="handleDelete"
                                    :disabled="isDeleting"
                                    class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-red-500 text-white text-sm font-prompt font-medium hover:bg-red-600 transition-all duration-200 disabled:opacity-60 disabled:cursor-not-allowed"
                                >
                                    <Loader2
                                        v-if="isDeleting"
                                        :size="15"
                                        class="animate-spin"
                                    />
                                    <Trash2 v-else :size="15" />
                                    {{
                                        isDeleting
                                            ? t(
                                                  "svgDetail.deleteModal.deleting",
                                              )
                                            : t("svgDetail.deleteModal.delete")
                                    }}
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>
            </Teleport>

            <!-- Admin Review Modal (Approve/Reject + public toggle) -->
            <Teleport to="body">
                <Transition name="modal">
                    <div
                        v-if="reviewModalOpen"
                        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                        @click.self="reviewModalOpen = false"
                    >
                        <div
                            class="bg-surface rounded-2xl shadow-xl w-full max-w-md p-6 font-prompt"
                        >
                            <div class="flex items-center gap-3 mb-4">
                                <div
                                    :class="[
                                        'w-10 h-10 rounded-xl flex items-center justify-center shrink-0',
                                        reviewAction === 'approve'
                                            ? 'bg-green-100'
                                            : 'bg-orange-100',
                                    ]"
                                >
                                    <Check
                                        v-if="reviewAction === 'approve'"
                                        :size="18"
                                        class="text-green-600"
                                    />
                                    <XCircle
                                        v-else
                                        :size="18"
                                        class="text-orange-500"
                                    />
                                </div>
                                <div>
                                    <h3
                                        class="text-base font-semibold text-textprimary font-prompt"
                                    >
                                        {{
                                            reviewAction === "approve"
                                                ? "Approve SVG"
                                                : "Reject SVG"
                                        }}
                                    </h3>
                                    <p
                                        class="text-xs text-textsecondary font-prompt mt-0.5"
                                    >
                                        "{{ asset?.name }}"
                                    </p>
                                </div>
                            </div>

                            <!-- Visibility toggle (only when approving) -->
                            <label
                                v-if="reviewAction === 'approve'"
                                class="flex items-start gap-3 bg-soft rounded-xl p-3 mb-5 cursor-pointer"
                            >
                                <input
                                    v-model="reviewTogglePublic"
                                    type="checkbox"
                                    class="mt-0.5 w-4 h-4 accent-accent"
                                />
                                <div>
                                    <p
                                        class="text-sm font-medium text-textprimary font-prompt"
                                    >
                                        Make this SVG public
                                    </p>
                                    <p
                                        class="text-xs text-textsecondary font-prompt mt-0.5"
                                    >
                                        If unchecked, the SVG stays private and
                                        is only visible to the owner.
                                    </p>
                                </div>
                            </label>

                            <div
                                v-else
                                class="bg-orange-50 border border-orange-200 rounded-xl p-3 mb-5"
                            >
                                <p
                                    class="text-xs font-prompt text-orange-700"
                                >
                                    The owner will see that their SVG was
                                    rejected. You can approve it later.
                                </p>
                            </div>

                            <div class="flex gap-3">
                                <button
                                    @click="reviewModalOpen = false"
                                    :disabled="adminActionLoading"
                                    class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                                >
                                    Cancel
                                </button>
                                <button
                                    @click="confirmReview"
                                    :disabled="adminActionLoading"
                                    :class="[
                                        'flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-white text-sm font-prompt font-medium transition-all duration-200 disabled:opacity-60',
                                        reviewAction === 'approve'
                                            ? 'bg-green-500 hover:bg-green-600'
                                            : 'bg-orange-500 hover:bg-orange-600',
                                    ]"
                                >
                                    <Loader2
                                        v-if="adminActionLoading"
                                        :size="15"
                                        class="animate-spin"
                                    />
                                    <Check
                                        v-else-if="reviewAction === 'approve'"
                                        :size="15"
                                    />
                                    <XCircle v-else :size="15" />
                                    {{
                                        adminActionLoading
                                            ? "Processing..."
                                            : reviewAction === "approve"
                                              ? "Approve"
                                              : "Reject"
                                    }}
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>
            </Teleport>

            <!-- Download Menu Modal -->
            <DownloadMenu
                v-if="asset"
                v-model="downloadMenuOpen"
                :svg-code="asset.svg_code"
                :filename="asset.name"
                @downloaded="handleDownloaded"
            />

            <!-- Toast -->
            <ToastNotification
                v-if="toast.message"
                :message="toast.message"
                :type="toast.type"
                @dismiss="toast.message = ''"
            />
        </div>
    </DefaultLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, onBeforeUnmount } from "vue";
import { useRoute, useRouter, RouterLink } from "vue-router";
import { useI18n } from "../composables/useI18n";
import {
    ArrowLeft,
    Download,
    Copy,
    Check,
    Pencil,
    Trash2,
    X,
    Save,
    Heart,
    Tag,
    Calendar,
    Code,
    ChevronDown,
    FileX,
    Home,
    Shield,
    LogIn,
    Loader2,
    AlertCircle,
    User2,
    ExternalLink,
    XCircle,
    Lock,
    Unlock,
    Eye,
} from "lucide-vue-next";
import DefaultLayout from "../layouts/DefaultLayout.vue";
import ToastNotification from "../components/ToastNotification.vue";
import DownloadMenu from "../components/DownloadMenu.vue";
import { useAuth } from "../composables/useAuth";
import { useSvgAssets } from "../composables/useSvgAssets";
import {
    sanitizeSvg,
    copySvgToClipboard,
} from "../utils/svgUtils";
import type { SvgAsset } from "../types";

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { user: currentUser, isAdmin } = useAuth();
const { fetchById, update, remove, toggleFavorite, adminReview } = useSvgAssets();

const asset = ref<SvgAsset | null>(null);
const loading = ref(true);
const copied = ref(false);
const showCode = ref(false);
const editModalOpen = ref(false);
const confirmDeleteOpen = ref(false);
const downloadMenuOpen = ref(false);

// Admin review modal state (mirrors AdminPage flow)
const reviewModalOpen = ref(false);
const reviewAction = ref<"approve" | "reject">("approve");
const reviewTogglePublic = ref(true);

// Lock body scroll when any modal is open so background content can't be
// scrolled, and to prevent the stacking-context issues that can cause clicks
// to land on the wrong element.
const anyModalOpen = computed(
    () =>
        editModalOpen.value ||
        confirmDeleteOpen.value ||
        downloadMenuOpen.value ||
        reviewModalOpen.value,
);
watch(anyModalOpen, (open) => {
    document.body.style.overflow = open ? "hidden" : "";
});
onBeforeUnmount(() => {
    // Always restore scroll when the component unmounts (e.g. navigating away
    // while a modal is open).
    document.body.style.overflow = "";
});
const isUpdating = ref(false);
const isDeleting = ref(false);
const favoriteLoading = ref(false);
const adminActionLoading = ref(false);
const editError = ref("");
const editTagsInput = ref("");

const categories = ["Illustration", "Icon", "Logo", "Animation", "Other"];

const toast = ref<{ message: string; type: "success" | "error" | "info" }>({
    message: "",
    type: "success",
});

const editForm = ref({
    name: "",
    svg_code: "",
    tags: [] as string[],
    category: "",
});

const showToast = (
    message: string,
    type: "success" | "error" | "info" = "success",
) => {
    toast.value = { message, type };
};

const isOwner = computed(() => {
    return (
        currentUser.value &&
        asset.value &&
        currentUser.value.id === asset.value.user_id
    );
});

const canManage = computed(() => isOwner.value || isAdmin.value);

// ── Background picker (preview only) ─────────────────────────────────────
type PreviewBg = "white" | "black" | "gray" | "gradient" | "transparent" | "checkerboard";
const backgroundOptions: {
    key: PreviewBg;
    label: string;
    swatchClass: string;
    previewStyle: string;
}[] = [
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
        key: "gray",
        label: "Gray",
        swatchClass: "bg-soft",
        previewStyle: "#DFE6E9",
    },
    {
        key: "gradient",
        label: "Gradient",
        swatchClass:
            "bg-[linear-gradient(135deg,#667eea_0%,#764ba2_100%)]",
        previewStyle:
            "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
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
            "[background-image:linear-gradient(45deg,#9ca3af_25%,transparent_25%),linear-gradient(-45deg,#9ca3af_25%,transparent_25%),linear-gradient(45deg,transparent_75%,#9ca3af_75%),linear-gradient(-45deg,transparent_75%,#9ca3af_75%)] [background-size:8px_8px] [background-position:0_0,0_4px,4px_-4px,-4px_0px] bg-white",
        previewStyle:
            "repeating-conic-gradient(#9ca3af 0 25%, #e5e7eb 0 50%) 0 0 / 16px 16px",
    },
];
const selectedBackground = ref<PreviewBg>("white");
const previewBackgroundStyle = computed(() => {
    const opt = backgroundOptions.find(
        (b) => b.key === selectedBackground.value,
    );
    return opt?.previewStyle ?? "#FFFFFF";
});

const sanitizedSvg = computed(() => {
    if (!asset.value?.svg_code) return "";
    const cleaned = sanitizeSvg(asset.value.svg_code);
    return cleaned.replace(
        /<svg/i,
        '<svg style="max-width:100%;max-height:280px;width:auto;height:auto;"',
    );
});

const editPreviewHtml = computed(() => {
    if (!editForm.value.svg_code) return "";
    const cleaned = sanitizeSvg(editForm.value.svg_code);
    return cleaned.replace(
        /<svg/i,
        '<svg style="max-width:100%;max-height:80px;width:auto;height:auto;"',
    );
});

const formatDate = (dateStr: string): string => {
    try {
        return new Intl.DateTimeFormat("th-TH", {
            year: "numeric",
            month: "long",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
        }).format(new Date(dateStr));
    } catch {
        return dateStr;
    }
};

const handleDownload = () => {
    if (!asset.value) return;
    downloadMenuOpen.value = true;
};

const handleDownloaded = () => {
    showToast(t("svgDetail.toast.downloaded"), "success");
};

const handleCopy = async () => {
    if (!asset.value) return;
    try {
        await copySvgToClipboard(asset.value.svg_code);
        copied.value = true;
        showToast(t("svgDetail.toast.copied"), "success");
        setTimeout(() => {
            copied.value = false;
        }, 2500);
    } catch {
        showToast(t("svgDetail.toast.error"), "error");
    }
};

const handleFavoriteToggle = async () => {
    if (!asset.value || !currentUser.value) return;
    favoriteLoading.value = true;
    try {
        await toggleFavorite(asset.value.id, asset.value.is_favorite);
        asset.value = { ...asset.value, is_favorite: !asset.value.is_favorite };
        showToast(
            asset.value.is_favorite
                ? t("svgDetail.toast.favoriteAdded")
                : t("svgDetail.toast.favoriteRemoved"),
            "success",
        );
    } catch {
        showToast(t("svgDetail.toast.error"), "error");
    } finally {
        favoriteLoading.value = false;
    }
};

const openEditModal = () => {
    if (!asset.value) return;
    editForm.value = {
        name: asset.value.name,
        svg_code: asset.value.svg_code,
        tags: [...(asset.value.tags ?? [])],
        category: asset.value.category ?? "",
    };
    editTagsInput.value = (asset.value.tags ?? []).join(", ");
    editError.value = "";
    editModalOpen.value = true;
};

const closeEditModal = () => {
    if (isUpdating.value) return;
    editModalOpen.value = false;
    editError.value = "";
};

const parseEditTags = () => {
    editForm.value.tags = editTagsInput.value
        .split(",")
        .map((t) => t.trim())
        .filter((t) => t.length > 0);
};

const removeEditTag = (tag: string) => {
    editForm.value.tags = editForm.value.tags.filter((t) => t !== tag);
    editTagsInput.value = editForm.value.tags.join(", ");
};

const handleUpdate = async () => {
    if (!asset.value) return;
    editError.value = "";

    if (!editForm.value.name.trim()) {
        editError.value = t("svgDetail.editModal.namePlaceholder");
        return;
    }
    if (
        !editForm.value.svg_code.trim() ||
        !editForm.value.svg_code.includes("<svg")
    ) {
        editError.value = t("svgDetail.editModal.error");
        return;
    }

    isUpdating.value = true;
    let updated = false;
    try {
        await update(asset.value.id, {
            name: editForm.value.name.trim(),
            svg_code: sanitizeSvg(editForm.value.svg_code),
            tags: editForm.value.tags,
            category: editForm.value.category || "Other",
        });
        // Refresh
        const refreshed = await fetchById(asset.value.id);
        if (refreshed) {
            asset.value = refreshed;
        }
        updated = true;
    } catch (e: unknown) {
        editError.value =
            e instanceof Error ? e.message : t("svgDetail.toast.error");
    } finally {
        // First clear updating flag so closeEditModal's guard won't block
        isUpdating.value = false;
        if (updated) {
            closeEditModal();
            showToast(t("svgDetail.toast.updated"), "success");
        }
    }
};

const handleDelete = async () => {
    if (!asset.value) return;
    isDeleting.value = true;
    try {
        await remove(asset.value.id);
        confirmDeleteOpen.value = false;
        showToast(t("svgDetail.toast.deleted"), "success");
        setTimeout(() => {
            router.push({ name: "home" });
        }, 1200);
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : t("svgDetail.toast.error"),
            "error",
        );
        confirmDeleteOpen.value = false;
    } finally {
        isDeleting.value = false;
    }
};

const openReviewModal = (action: "approve" | "reject") => {
    if (!asset.value) return;
    reviewAction.value = action;
    // Default to "make public" checked — admin can uncheck if they want the
    // SVG to stay private after approval.
    reviewTogglePublic.value = true;
    reviewModalOpen.value = true;
};

const confirmReview = async () => {
    if (!asset.value) return;
    adminActionLoading.value = true;
    try {
        const newStatus =
            reviewAction.value === "approve" ? "approved" : "rejected";
        // For approve: the checkbox is "make public" — so uncheck means private.
        // For reject: keep current visibility (the checkbox is not shown).
        const makePrivate = reviewAction.value === "approve"
            ? !reviewTogglePublic.value
            : asset.value.is_private;
        await adminReview(asset.value.id, newStatus, makePrivate);
        const refreshed = await fetchById(asset.value.id);
        if (refreshed) asset.value = refreshed;
        showToast(
            reviewAction.value === "approve"
                ? t("svgDetail.toast.approved")
                : t("svgDetail.toast.rejected"),
            "success",
        );
        reviewModalOpen.value = false;
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : t("svgDetail.toast.error"),
            "error",
        );
    } finally {
        adminActionLoading.value = false;
    }
};

const handleToggleVisibility = async () => {
    if (!asset.value) return;
    adminActionLoading.value = true;
    try {
        await adminReview(asset.value.id, asset.value.status, !asset.value.is_private);
        const refreshed = await fetchById(asset.value.id);
        if (refreshed) asset.value = refreshed;
        showToast(
            !asset.value.is_private
                ? t("svgDetail.toast.madePrivate")
                : t("svgDetail.toast.madePublic"),
            "success",
        );
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : t("svgDetail.toast.error"),
            "error",
        );
    } finally {
        adminActionLoading.value = false;
    }
};

onMounted(async () => {
    const id = route.params.id as string;
    if (!id) {
        loading.value = false;
        return;
    }
    try {
        asset.value = await fetchById(id);
    } finally {
        loading.value = false;
    }
});
</script>

<style scoped>
/*
 * Use CSS transitions (not keyframe animations) for modal enter/leave.
 *
 * Why: CSS `animation` with `animation-fill-mode: forwards` can prevent the
 * browser from firing `animationend` if the tab goes into the background or
 * the browser is under heavy load.  Vue's <Transition> waits for that event
 * before removing the element from the DOM.  If the event never fires, the
 * invisible `fixed inset-0 z-50` backdrop stays in the DOM forever and blocks
 * ALL pointer events — making the entire page appear completely frozen.
 *
 * CSS transitions use `transitionend` which fires reliably in all edge cases.
 * `pointer-events: none` on leave-active is an extra safety net so that even
 * during the brief fade-out the backdrop never intercepts user clicks.
 */
.modal-enter-active {
    transition:
        opacity 0.2s ease,
        transform 0.2s ease;
}
.modal-leave-active {
    transition:
        opacity 0.15s ease,
        transform 0.15s ease;
    pointer-events: none;
}
.modal-enter-from,
.modal-leave-to {
    opacity: 0;
    transform: scale(0.97);
}

.code-expand-enter-active,
.code-expand-leave-active {
    transition: all 0.25s ease;
    overflow: hidden;
}
.code-expand-enter-from,
.code-expand-leave-to {
    opacity: 0;
    max-height: 0;
    transform: translateY(-6px);
}
.code-expand-enter-to,
.code-expand-leave-from {
    opacity: 1;
    max-height: 600px;
}
</style>
