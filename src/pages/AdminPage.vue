<template>
    <DefaultLayout>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 font-prompt">
            <!-- Header -->
            <div
                class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8"
            >
                <div>
                    <div class="flex items-center gap-3 mb-1">
                        <h1
                            class="text-2xl font-semibold text-purple-700 font-prompt"
                        >
                            {{ t('admin.title') }}
                        </h1>
                        <span
                            class="text-xs font-medium bg-purple-600 text-white px-3 py-1 rounded-full"
                            >Admin</span
                        >
                    </div>
                    <p class="text-sm text-textsecondary font-prompt">
                        {{ t('admin.subtitle') }}
                    </p>
                </div>
                <RouterLink
                    to="/collection"
                    class="inline-flex items-center gap-2 px-4 py-2.5 rounded-2xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 w-fit"
                >
                    <LayoutDashboard :size="16" />
                    {{ t('admin.backToCollection') }}
                </RouterLink>
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
                            <Users :size="18" class="text-accent" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ users.length }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t('admin.stats.totalUsers') }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-purple-50 flex items-center justify-center"
                        >
                            <ShieldCheck :size="18" class="text-purple-500" />
                        </div>
                        <div>
                            <p class="text-2xl font-semibold text-textprimary font-prompt">
                                {{ adminCount }}
                            </p>
                            <p class="text-xs text-purple-600 font-prompt">
                                {{ t('admin.stats.admins') }}
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
                            <Layers :size="18" class="text-secondary" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ allSvgs.length }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t('admin.stats.totalSvgs') }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="bg-surface rounded-2xl border border-border p-4 shadow-sm"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center"
                        >
                            <Activity :size="18" class="text-green-500" />
                        </div>
                        <div>
                            <p
                                class="text-2xl font-semibold text-textprimary font-prompt"
                            >
                                {{ activeTodayCount }}
                            </p>
                            <p class="text-xs text-textsecondary font-prompt">
                                {{ t('admin.stats.activeToday') }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab Navigation -->
            <div
                class="flex gap-1 mb-6 bg-soft p-1 rounded-xl w-fit border border-border"
            >
                <button
                    @click="activeTab = 'users'"
                    :class="[
                        'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-prompt font-medium transition-all duration-200',
                        activeTab === 'users'
                            ? 'bg-surface text-accent shadow-sm border border-border'
                            : 'text-textsecondary hover:text-primary',
                    ]"
                >
                    <Users :size="15" />
                    {{ t('admin.tabs.users') }}
                    <span
                        class="text-xs bg-accent/10 text-accent px-1.5 py-0.5 rounded-full"
                        >{{ users.length }}</span
                    >
                </button>
                <button
                    @click="activeTab = 'svgs'"
                    :class="[
                        'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-prompt font-medium transition-all duration-200',
                        activeTab === 'svgs'
                            ? 'bg-surface text-accent shadow-sm border border-border'
                            : 'text-textsecondary hover:text-primary',
                    ]"
                >
                    <Layers :size="15" />
                    {{ t('admin.tabs.svgs') }}
                    <span
                        class="text-xs bg-accent/10 text-accent px-1.5 py-0.5 rounded-full"
                        >{{ allSvgs.length }}</span
                    >
                </button>
            </div>

            <!-- ══════════════════════════════════════════ -->
            <!--  TAB: USERS                               -->
            <!-- ══════════════════════════════════════════ -->
            <div v-if="activeTab === 'users'">
                <!-- Toolbar -->
                <div class="flex flex-col sm:flex-row gap-3 mb-5">
                    <!-- Search -->
                    <div class="relative flex-1">
                        <Search
                            :size="15"
                            class="absolute left-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                        />
                        <input
                            v-model="userSearch"
                            type="text"
                            :placeholder="t('admin.users.searchPlaceholder')"
                            class="w-full pl-9 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                        />
                    </div>
                    <!-- Filter inactive -->
                    <button
                        @click="showInactiveOnly = !showInactiveOnly"
                        :class="[
                            'flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-prompt font-medium border transition-all duration-200',
                            showInactiveOnly
                                ? 'bg-orange-50 text-orange-600 border-orange-300'
                                : 'bg-surface text-textsecondary border-border hover:border-accent hover:text-accent',
                        ]"
                    >
                        <Clock :size="15" />
                        {{ t('admin.users.showInactive') }}
                        <span class="hidden sm:inline text-xs opacity-70">{{ t('admin.users.showInactiveHint') }}</span>
                        <span
                            v-if="showInactiveOnly"
                            class="text-xs bg-orange-200 text-orange-700 px-1.5 py-0.5 rounded-full"
                            >ON</span
                        >
                    </button>
                    <!-- Refresh -->
                    <button
                        @click="loadUsers"
                        :disabled="usersLoading"
                        class="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-surface border border-border text-sm font-prompt font-medium text-textsecondary hover:text-primary hover:border-accent transition-all duration-200 disabled:opacity-50"
                    >
                        <RefreshCw
                            :size="15"
                            :class="usersLoading ? 'animate-spin' : ''"
                        />
                        {{ t('admin.users.refresh') }}
                    </button>
                </div>

                <!-- Loading -->
                <div v-if="usersLoading" class="space-y-3">
                    <div
                        v-for="i in 5"
                        :key="i"
                        class="bg-surface rounded-2xl border border-border p-4 animate-pulse flex items-center gap-4"
                    >
                        <div
                            class="w-10 h-10 rounded-full bg-soft shrink-0"
                        ></div>
                        <div class="flex-1 space-y-2">
                            <div class="h-4 bg-soft rounded-full w-1/3"></div>
                            <div class="h-3 bg-soft rounded-full w-1/2"></div>
                        </div>
                        <div class="h-6 w-16 bg-soft rounded-full"></div>
                    </div>
                </div>

                <!-- Error -->
                <div
                    v-else-if="usersError"
                    class="flex flex-col items-center justify-center py-16 text-center"
                >
                    <div
                        class="w-14 h-14 rounded-2xl bg-red-50 flex items-center justify-center mb-4"
                    >
                        <AlertCircle :size="24" class="text-red-400" />
                    </div>
                    <p
                        class="text-sm font-medium text-primary font-prompt mb-1"
                    >
                        {{ t('admin.users.error') }}
                    </p>
                    <p class="text-xs text-textsecondary font-prompt mb-4">
                        {{ usersError }}
                    </p>
                    <button
                        @click="loadUsers"
                        class="px-4 py-2 rounded-xl bg-accent text-white text-sm font-prompt hover:bg-accent/90 transition-colors"
                    >
                        {{ t('admin.users.retry') }}
                    </button>
                </div>

                <!-- User Table -->
                <div
                    v-else-if="filteredUsers.length"
                    class="bg-surface rounded-2xl border border-border overflow-hidden shadow-sm"
                >
                    <table class="w-full">
                        <thead>
                            <tr class="border-b border-border bg-soft/50">
                                <th
                                    class="text-left text-xs font-medium text-textsecondary font-prompt px-5 py-3"
                                >
                                    {{ t('admin.users.columns.user') }}
                                </th>
                                <th
                                    class="text-left text-xs font-medium text-textsecondary font-prompt px-5 py-3 hidden md:table-cell"
                                >
                                    {{ t('admin.users.columns.role') }}
                                </th>
                                <th
                                    class="text-left text-xs font-medium text-textsecondary font-prompt px-5 py-3 hidden lg:table-cell"
                                >
                                    {{ t('admin.users.columns.lastSeen') }}
                                </th>
                                <th
                                    class="text-left text-xs font-medium text-textsecondary font-prompt px-5 py-3 hidden lg:table-cell"
                                >
                                    {{ t('admin.users.columns.createdAt') }}
                                </th>
                                <th
                                    class="text-right text-xs font-medium text-textsecondary font-prompt px-5 py-3"
                                >
                                    {{ t('admin.users.columns.actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-border">
                            <tr
                                v-for="u in filteredUsers"
                                :key="u.id"
                                class="hover:bg-soft/30 transition-colors duration-150"
                            >
                                <!-- User info -->
                                <td class="px-5 py-4">
                                    <div class="flex items-center gap-3">
                                        <div
                                            class="w-9 h-9 rounded-full bg-accent/10 flex items-center justify-center shrink-0 text-accent font-semibold text-sm font-prompt"
                                        >
                                            {{
                                                (
                                                    u.display_name ||
                                                    u.email ||
                                                    "?"
                                                )
                                                    .charAt(0)
                                                    .toUpperCase()
                                            }}
                                        </div>
                                        <div class="min-w-0">
                                            <component
                                                :is="u.username ? 'RouterLink' : 'span'"
                                                v-bind="u.username ? { to: `/profile/${u.username}` } : {}"
                                                :title="u.username ? t('admin.users.viewProfile') : undefined"
                                                :class="[
                                                    'text-sm font-medium font-prompt truncate block',
                                                    u.username
                                                        ? 'text-accent hover:underline cursor-pointer'
                                                        : 'text-textprimary'
                                                ]"
                                            >
                                                {{
                                                    u.display_name ||
                                                    u.email?.split("@")[0] ||
                                                    t('admin.users.noName')
                                                }}
                                            </component>
                                            <p
                                                class="text-xs text-textsecondary font-prompt truncate"
                                            >
                                                {{ u.email }}
                                            </p>
                                        </div>
                                    </div>
                                </td>

                                <!-- Role -->
                                <td class="px-5 py-4 hidden md:table-cell">
                                    <span
                                        :class="[
                                            'inline-flex items-center gap-1 text-xs font-prompt font-medium px-2.5 py-1 rounded-full',
                                            u.role === 'admin'
                                                ? 'bg-purple-100 text-purple-700'
                                                : 'bg-soft text-textsecondary',
                                        ]"
                                    >
                                        <ShieldCheck
                                            v-if="u.role === 'admin'"
                                            :size="11"
                                        />
                                        <User v-else :size="11" />
                                        {{
                                            u.role === "admin"
                                                ? "Admin"
                                                : "User"
                                        }}
                                    </span>
                                </td>

                                <!-- Last seen -->
                                <td class="px-5 py-4 hidden lg:table-cell">
                                    <span
                                        :class="[
                                            'text-xs font-prompt',
                                            isInactive(u.last_seen_at)
                                                ? 'text-orange-500'
                                                : 'text-textsecondary',
                                        ]"
                                    >
                                        {{
                                            u.last_seen_at
                                                ? formatRelativeDate(
                                                      u.last_seen_at,
                                                  )
                                                : t('admin.users.neverSeen')
                                        }}
                                    </span>
                                </td>

                                <!-- Created at -->
                                <td class="px-5 py-4 hidden lg:table-cell">
                                    <span
                                        class="text-xs text-textsecondary font-prompt"
                                    >
                                        {{ formatDate(u.created_at) }}
                                    </span>
                                </td>

                                <!-- Actions -->
                                <td class="px-5 py-4">
                                    <div
                                        class="flex items-center justify-end gap-2"
                                    >
                                        <!-- Toggle role -->
                                        <button
                                            v-if="u.id !== currentUser?.id"
                                            @click="
                                                confirmRoleChange = u;
                                                newRoleTarget =
                                                    u.role === 'admin'
                                                        ? 'user'
                                                        : 'admin';
                                            "
                                            :title="
                                                u.role === 'admin'
                                                    ? t('admin.users.demoteToUser')
                                                    : t('admin.users.promoteToAdmin')
                                            "
                                            :class="[
                                                'p-2 rounded-xl text-xs font-prompt transition-all duration-200',
                                                u.role === 'admin'
                                                    ? 'text-purple-500 hover:bg-purple-50'
                                                    : 'text-textsecondary hover:bg-soft hover:text-accent',
                                            ]"
                                        >
                                            <ShieldCheck :size="15" />
                                        </button>

                                        <!-- Delete user -->
                                        <button
                                            v-if="u.id !== currentUser?.id"
                                            @click="confirmDeleteUser = u"
                                            :title="t('admin.users.deleteUser')"
                                            class="p-2 rounded-xl text-textsecondary hover:bg-red-50 hover:text-red-500 transition-all duration-200"
                                        >
                                            <Trash2 :size="15" />
                                        </button>

                                        <!-- Self badge -->
                                        <span
                                            v-if="u.id === currentUser?.id"
                                            class="text-xs text-textsecondary font-prompt bg-soft px-2 py-1 rounded-lg"
                                            >{{ t('admin.users.youBadge') }}</span
                                        >
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Empty state -->
                <div
                    v-else
                    class="flex flex-col items-center justify-center py-20 text-center"
                >
                    <div
                        class="w-16 h-16 rounded-2xl bg-soft flex items-center justify-center mb-4"
                    >
                        <Users :size="28" class="text-textsecondary" />
                    </div>
                    <p
                        class="text-base font-semibold text-primary font-prompt mb-1"
                    >
                        {{ t('admin.users.empty.title') }}
                    </p>
                    <p class="text-sm text-textsecondary font-prompt">
                        {{ t('admin.users.empty.description') }}
                    </p>
                </div>
            </div>

            <!-- ══════════════════════════════════════════ -->
            <!--  TAB: ALL SVGs                            -->
            <!-- ══════════════════════════════════════════ -->
            <div v-if="activeTab === 'svgs'">
                <!-- Status filter pills -->
                <div
                    class="flex flex-wrap items-center gap-2 mb-4 bg-soft p-1 rounded-xl w-fit border border-border"
                >
                    <button
                        v-for="opt in statusFilterOptions"
                        :key="opt.key"
                        @click="svgStatusFilter = opt.key"
                        :class="[
                            'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-prompt font-medium transition-all duration-200',
                            svgStatusFilter === opt.key
                                ? 'bg-surface text-accent shadow-sm border border-border'
                                : 'text-textsecondary hover:text-primary',
                        ]"
                    >
                        {{ opt.label }}
                        <span
                            v-if="opt.key === 'pending' && pendingCount > 0"
                            class="text-[10px] bg-orange-500 text-white px-1.5 py-0.5 rounded-full"
                        >
                            {{ pendingCount }}
                        </span>
                    </button>
                </div>

                <!-- Toolbar -->
                <div class="flex flex-col sm:flex-row gap-3 mb-5">
                    <div class="relative flex-1">
                        <Search
                            :size="15"
                            class="absolute left-3 top-1/2 -translate-y-1/2 text-textsecondary pointer-events-none"
                        />
                        <input
                            v-model="svgSearch"
                            type="text"
                            placeholder="Search SVGs..."
                            class="w-full pl-9 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary placeholder-textsecondary focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 transition-all duration-200"
                        />
                    </div>
                    <div class="relative">
                        <select
                            v-model="svgCategory"
                            class="pl-4 pr-8 py-2.5 bg-surface border border-border rounded-xl text-sm font-prompt text-textprimary focus:outline-none focus:border-accent appearance-none transition-all duration-200 min-w-[150px]"
                        >
                            <option value="">All Categories</option>
                            <option
                                v-for="cat in categories"
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
                    <button
                        @click="loadSvgs"
                        :disabled="svgsLoading"
                        class="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-surface border border-border text-sm font-prompt font-medium text-textsecondary hover:text-primary hover:border-accent transition-all duration-200 disabled:opacity-50"
                    >
                        <RefreshCw
                            :size="15"
                            :class="svgsLoading ? 'animate-spin' : ''"
                        />
                        Refresh
                    </button>
                </div>

                <!-- Loading skeleton -->
                <div
                    v-if="svgsLoading"
                    class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5"
                >
                    <div
                        v-for="i in 8"
                        :key="i"
                        class="bg-surface rounded-2xl border border-border p-4 animate-pulse"
                    >
                        <div class="w-full h-28 bg-soft rounded-xl mb-3"></div>
                        <div class="h-4 bg-soft rounded-full w-3/4 mb-2"></div>
                        <div class="h-3 bg-soft rounded-full w-1/2"></div>
                    </div>
                </div>

                <!-- SVG Grid -->
                <div
                    v-if="filteredSvgs.length"
                    class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5"
                >
                    <div
                        v-for="svg in filteredSvgs"
                        :key="svg.id"
                        class="group bg-surface rounded-2xl border border-border p-4 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-200"
                    >
                        <!-- Preview -->
                        <div
                            class="relative w-full h-28 bg-bg rounded-xl flex items-center justify-center overflow-hidden mb-3"
                        >
                            <div
                                v-if="svg.svg_code"
                                class="w-full h-full flex items-center justify-center p-2"
                                v-html="getScopedSvg(svg)"
                            />
                            <div
                                v-else
                                class="text-textsecondary text-xs font-prompt"
                            >
                                No preview
                            </div>

                            <!-- Overlay actions -->
                            <div
                                class="absolute inset-0 bg-primary/60 rounded-xl flex items-center justify-center gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex-wrap px-2"
                                @click.stop
                            >
                                <RouterLink
                                    :to="`/svg/${svg.id}`"
                                    title="View"
                                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-accent transition-all duration-150 hover:scale-110"
                                >
                                    <ExternalLink :size="15" />
                                </RouterLink>

                                <!-- Approve (only when not already approved) -->
                                <button
                                    v-if="svg.status !== 'approved'"
                                    @click="openReview(svg, 'approve', true)"
                                    title="Approve"
                                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-green-500 transition-all duration-150 hover:scale-110"
                                >
                                    <Check :size="15" />
                                </button>

                                <!-- Reject (only when not already rejected) -->
                                <button
                                    v-if="svg.status !== 'rejected'"
                                    @click="openReview(svg, 'reject', false)"
                                    title="Reject"
                                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-orange-500 transition-all duration-150 hover:scale-110"
                                >
                                    <XCircle :size="15" />
                                </button>

                                <!-- Toggle visibility (public/private) -->
                                <button
                                    v-if="svg.status === 'approved'"
                                    @click="toggleVisibility(svg)"
                                    :title="svg.is_private ? 'Make Public' : 'Make Private'"
                                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-purple-500 transition-all duration-150 hover:scale-110"
                                >
                                    <Unlock
                                        v-if="!svg.is_private"
                                        :size="15"
                                        class="-scale-x-100"
                                    />
                                    <Lock v-else :size="15" />
                                </button>

                                <button
                                    @click="confirmDeleteSvg = svg"
                                    title="Delete"
                                    class="p-2 rounded-xl bg-white/20 text-white hover:bg-red-500 transition-all duration-150 hover:scale-110"
                                >
                                    <Trash2 :size="15" />
                                </button>
                            </div>
                        </div>

                        <!-- Info -->
                        <p
                            class="text-sm font-medium text-textprimary font-prompt truncate mb-1"
                        >
                            {{ svg.name }}
                        </p>

                        <!-- Owner badge -->
                        <div class="flex items-center gap-1 mb-2">
                            <User
                                :size="11"
                                class="text-textsecondary shrink-0"
                                title="Owner"
                            />
                            <span
                                class="text-xs text-textsecondary font-prompt truncate"
                            >
                                {{
                                    ownerMap.get(svg.user_id) ||
                                    svg.user_id.slice(0, 8) + "…"
                                }}
                            </span>
                        </div>

                        <!-- Category -->
                        <div v-if="svg.category" class="mt-2">
                            <span
                                class="text-[11px] font-prompt text-accent bg-accent/10 px-2 py-0.5 rounded-full"
                            >
                                {{ svg.category }}
                            </span>
                        </div>

                        <!-- Approval status badge -->
                        <div class="flex flex-wrap items-center gap-1.5 mt-2">
                            <span
                                v-if="svg.status === 'pending'"
                                class="inline-flex items-center gap-1 text-[10px] font-prompt font-medium text-orange-600 bg-orange-50 border border-orange-200 px-1.5 py-0.5 rounded-full"
                            >
                                <Clock :size="10" />
                                Pending
                            </span>
                            <span
                                v-else-if="svg.status === 'rejected'"
                                class="inline-flex items-center gap-1 text-[10px] font-prompt font-medium text-red-600 bg-red-50 border border-red-200 px-1.5 py-0.5 rounded-full"
                            >
                                <X :size="10" />
                                Rejected
                            </span>
                            <span
                                v-if="svg.is_private"
                                class="inline-flex items-center gap-1 text-[10px] font-prompt font-medium text-secondary bg-soft border border-border px-1.5 py-0.5 rounded-full"
                            >
                                <Lock :size="10" />
                                Private
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Empty -->
                <div
                    v-else
                    class="flex flex-col items-center justify-center py-20 text-center"
                >
                    <div
                        class="w-16 h-16 rounded-2xl bg-soft flex items-center justify-center mb-4"
                    >
                        <Layers :size="28" class="text-textsecondary" />
                    </div>
                    <p
                        class="text-base font-semibold text-primary font-prompt mb-1"
                    >
                        {{ t('admin.svgs.empty.title') }}
                    </p>
                    <p class="text-sm text-textsecondary font-prompt">
                        {{ t('admin.svgs.empty.description') }}
                    </p>
                </div>
            </div>
        </div>

        <!-- ══════════════════════════════════════════════ -->
        <!--  MODAL: Delete User                          -->
        <!-- ══════════════════════════════════════════════ -->
        <Teleport to="body">
            <Transition name="modal">
                <div
                    v-if="confirmDeleteUser"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                    @click.self="confirmDeleteUser = null"
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
                                    {{ t('admin.deleteUserModal.title') }}
                                </h3>
                                <p
                                    class="text-xs text-textsecondary font-prompt mt-0.5"
                                >
                                    {{ t('admin.deleteUserModal.subtitle') }}
                                </p>
                            </div>
                        </div>

                        <div class="bg-red-50 rounded-xl p-3 mb-3 space-y-1">
                            <p class="text-sm font-prompt text-red-700">
                                {{ t('admin.deleteUserModal.confirmText') }}
                                <strong>{{
                                    confirmDeleteUser.display_name ||
                                    confirmDeleteUser.email
                                }}</strong>?
                            </p>
                            <p class="text-xs font-prompt text-red-500">
                                {{ t('admin.deleteUserModal.warningText') }}
                            </p>
                        </div>

                        <!-- Re-register note -->
                        <div
                            class="flex items-start gap-2 bg-blue-50 border border-blue-200 rounded-xl px-3 py-2.5 mb-5"
                        >
                            <Info
                                :size="14"
                                class="text-blue-500 mt-0.5 shrink-0"
                            />
                            <p class="text-xs font-prompt text-blue-700">
                                <strong>{{ t('admin.deleteUserModal.warningTitle') }}:</strong>
                                {{ t('admin.deleteUserModal.warningText') }}
                            </p>
                        </div>

                        <div class="flex gap-3">
                            <button
                                @click="confirmDeleteUser = null"
                                :disabled="isDeleting"
                                class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                            >
                                {{ t('admin.deleteUserModal.cancel') }}
                            </button>
                            <button
                                @click="handleDeleteUser"
                                :disabled="isDeleting"
                                class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-red-500 text-white text-sm font-prompt font-medium hover:bg-red-600 transition-all duration-200 disabled:opacity-60 disabled:cursor-not-allowed"
                            >
                                <Loader2
                                    v-if="isDeleting"
                                    :size="15"
                                    class="animate-spin"
                                />
                                <Trash2 v-else :size="15" />
                                {{ isDeleting ? t('admin.deleteUserModal.deleting') : t('admin.deleteUserModal.confirm') }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>

        <!-- ══════════════════════════════════════════════ -->
        <!--  MODAL: Change Role                          -->
        <!-- ══════════════════════════════════════════════ -->
        <Teleport to="body">
            <Transition name="modal">
                <div
                    v-if="confirmRoleChange"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                    @click.self="confirmRoleChange = null"
                >
                    <div
                        class="bg-surface rounded-2xl shadow-xl w-full max-w-sm p-6 font-prompt"
                    >
                        <div class="flex items-center gap-3 mb-4">
                            <div
                                class="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center shrink-0"
                            >
                                <ShieldCheck
                                    :size="18"
                                    class="text-purple-500"
                                />
                            </div>
                            <div>
                                <h3
                                    class="text-base font-semibold text-textprimary font-prompt"
                                >
                                    {{ t('admin.changeRoleModal.title') }}
                                </h3>
                                <p
                                    class="text-xs text-textsecondary font-prompt mt-0.5"
                                >
                                    {{
                                        confirmRoleChange.display_name ||
                                        confirmRoleChange.email
                                    }}
                                </p>
                            </div>
                        </div>

                        <div
                            class="bg-soft rounded-xl p-3 mb-5 text-sm font-prompt text-textprimary flex items-center gap-2 flex-wrap"
                        >
                            <span
                                :class="
                                    confirmRoleChange.role === 'admin'
                                        ? 'text-purple-600 font-semibold'
                                        : 'text-accent font-semibold'
                                "
                            >
                                {{
                                    confirmRoleChange.role === "admin"
                                        ? t('admin.changeRoleModal.roleAdmin')
                                        : t('admin.changeRoleModal.roleUser')
                                }}
                            </span>
                            <ArrowRight :size="14" class="text-textsecondary" />
                            <span
                                :class="
                                    newRoleTarget === 'admin'
                                        ? 'text-purple-600 font-semibold'
                                        : 'text-accent font-semibold'
                                "
                            >
                                {{
                                    newRoleTarget === "admin"
                                        ? t('admin.changeRoleModal.roleAdmin')
                                        : t('admin.changeRoleModal.roleUser')
                                }}
                            </span>
                            ?
                        </div>

                        <div class="flex gap-3">
                            <button
                                @click="confirmRoleChange = null"
                                :disabled="isChangingRole"
                                class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                            >
                                {{ t('admin.changeRoleModal.cancel') }}
                            </button>
                            <button
                                @click="handleChangeRole"
                                :disabled="isChangingRole"
                                class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-accent text-white text-sm font-prompt font-medium hover:bg-accent/90 transition-all duration-200 disabled:opacity-60"
                            >
                                <Loader2
                                    v-if="isChangingRole"
                                    :size="15"
                                    class="animate-spin"
                                />
                                <ShieldCheck v-else :size="15" />
                                {{
                                    isChangingRole ? t('admin.changeRoleModal.changing') : t('admin.changeRoleModal.confirm')
                                }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>

        <!-- ══════════════════════════════════════════════ -->
        <!--  MODAL: Delete SVG                           -->
        <!-- ══════════════════════════════════════════════ -->
        <Teleport to="body">
            <Transition name="modal">
                <div
                    v-if="confirmDeleteSvg"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                    @click.self="confirmDeleteSvg = null"
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
                                    class="text-base font-semibold text-textprimary"
                                >
                                    {{ t('admin.deleteSvgModal.title') }}
                                </h3>
                                <p class="text-xs text-textsecondary mt-0.5">
                                    {{ t('admin.deleteSvgModal.subtitle') }}
                                </p>
                            </div>
                        </div>
                        <div class="bg-red-50 rounded-xl p-3 mb-5">
                            <p class="text-sm font-prompt text-red-700">
                                {{ t('admin.deleteSvgModal.confirmText') }}
                                <strong>"{{ confirmDeleteSvg.name }}"</strong>?
                            </p>
                        </div>
                        <div class="flex gap-3">
                            <button
                                @click="confirmDeleteSvg = null"
                                :disabled="isDeletingSvg"
                                class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                            >
                                {{ t('admin.deleteSvgModal.cancel') }}
                            </button>
                            <button
                                @click="handleDeleteSvg"
                                :disabled="isDeletingSvg"
                                class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-red-500 text-white text-sm font-prompt font-medium hover:bg-red-600 transition-all duration-200 disabled:opacity-60"
                            >
                                <Loader2
                                    v-if="isDeletingSvg"
                                    :size="15"
                                    class="animate-spin"
                                />
                                <Trash2 v-else :size="15" />
                                {{ isDeletingSvg ? t('admin.deleteSvgModal.deleting') : t('admin.deleteSvgModal.confirm') }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>

        <!-- ══════════════════════════════════════════════ -->
        <!--  MODAL: Review SVG (Approve/Reject + public) -->
        <!-- ══════════════════════════════════════════════ -->
        <Teleport to="body">
            <Transition name="modal">
                <div
                    v-if="reviewTarget"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4"
                    @click.self="reviewTarget = null"
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
                                    "{{ reviewTarget.name }}"
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
                                    If unchecked, the SVG stays private and is
                                    only visible to the owner.
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
                                The owner will see that their SVG was rejected.
                                You can approve it later.
                            </p>
                        </div>

                        <div class="flex gap-3">
                            <button
                                @click="reviewTarget = null"
                                :disabled="isReviewing"
                                class="flex-1 px-4 py-2.5 rounded-xl border border-border text-sm font-prompt font-medium text-secondary hover:bg-soft transition-all duration-200 disabled:opacity-50"
                            >
                                Cancel
                            </button>
                            <button
                                @click="handleReview"
                                :disabled="isReviewing"
                                :class="[
                                    'flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-white text-sm font-prompt font-medium transition-all duration-200 disabled:opacity-60',
                                    reviewAction === 'approve'
                                        ? 'bg-green-500 hover:bg-green-600'
                                        : 'bg-orange-500 hover:bg-orange-600',
                                ]"
                            >
                                <Loader2
                                    v-if="isReviewing"
                                    :size="15"
                                    class="animate-spin"
                                />
                                <Check
                                    v-else-if="reviewAction === 'approve'"
                                    :size="15"
                                />
                                <XCircle v-else :size="15" />
                                {{
                                    isReviewing
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
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { RouterLink } from "vue-router";
import { useScrollRestoration } from "../composables/useScrollRestoration";
import {
    Users,
    ShieldCheck,
    Layers,
    Activity,
    Search,
    Clock,
    RefreshCw,
    Trash2,
    AlertCircle,
    Loader2,
    User,
    LayoutDashboard,
    ChevronDown,
    ExternalLink,
    Info,
    Check,
    XCircle,
    Lock,
    Unlock,
    X,
    ArrowRight,
} from "lucide-vue-next";
import DefaultLayout from "../layouts/DefaultLayout.vue";
import ToastNotification from "../components/ToastNotification.vue";
import { supabase } from "../services/supabase";
import { useAuth } from "../composables/useAuth";
import { useSvgAssets } from "../composables/useSvgAssets";
import { sanitizeSvg } from "../utils/svgUtils";
import { useI18n } from "../composables/useI18n";
import type { SvgAsset } from "../types";

// ── Types ────────────────────────────────────────────────────
interface AdminUser {
    id: string;
    email: string;
    display_name: string | null;
    username: string | null;
    role: "user" | "admin";
    last_seen_at: string | null;
    created_at: string;
}

// ── i18n ──────────────────────────────────────────────────────
const { t } = useI18n();

// ── Auth ─────────────────────────────────────────────────────
const { user: currentUser, refreshSession } = useAuth();

// ── SVG Assets ───────────────────────────────────────────────
const {
    assets: allSvgs,
    loading: svgsLoading,
    fetchAll,
    remove: removeSvg,
    adminReview,
    update: updateSvg,
} = useSvgAssets();

// ── State ────────────────────────────────────────────────────
// ── Scroll + Tab Restoration ─────────────────────────────────
const { restoreScroll } = useScrollRestoration("admin");

// Restore active tab from sessionStorage so that navigating back from an
// SVG detail page returns the admin to the same tab they were on.
const _savedTab = sessionStorage.getItem("svgbox_admin_tab");
const activeTab = ref<"users" | "svgs">(
    _savedTab === "svgs" ? "svgs" : "users",
);

// Persist the active tab whenever it changes
watch(activeTab, (tab) => {
    sessionStorage.setItem("svgbox_admin_tab", tab);
});
const categories = ["Illustration", "Icon", "Logo", "Animation", "Other"];

const statusFilterOptions: {
    key: "all" | "pending" | "approved" | "rejected";
    label: string;
}[] = [
    { key: "all", label: "All" },
    { key: "pending", label: "Pending" },
    { key: "approved", label: "Approved" },
    { key: "rejected", label: "Rejected" },
];

// Users tab
const users = ref<AdminUser[]>([]);
const usersLoading = ref(false);
const usersError = ref<string | null>(null);
const userSearch = ref("");
const showInactiveOnly = ref(false);

// SVGs tab
const svgSearch = ref("");
const svgCategory = ref("");
const svgStatusFilter = ref<"all" | "pending" | "approved" | "rejected">("all");

// Modals
const confirmDeleteUser = ref<AdminUser | null>(null);
const confirmRoleChange = ref<AdminUser | null>(null);
const newRoleTarget = ref<"user" | "admin">("user");
const confirmDeleteSvg = ref<SvgAsset | null>(null);

// Pending review modal — when admin clicks Approve/Reject on a card
const reviewTarget = ref<SvgAsset | null>(null);
const reviewAction = ref<"approve" | "reject">("approve");
const reviewTogglePublic = ref(false);

// Loading states
const isDeleting = ref(false);
const isChangingRole = ref(false);
const isDeletingSvg = ref(false);
const isReviewing = ref(false);

// Toast
const toast = ref<{ message: string; type: "success" | "error" | "info" }>({
    message: "",
    type: "success",
});

// ── Computed ─────────────────────────────────────────────────
const adminCount = computed(
    () => users.value.filter((u) => u.role === "admin").length,
);

const activeTodayCount = computed(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return users.value.filter((u) => {
        if (!u.last_seen_at) return false;
        return new Date(u.last_seen_at) >= today;
    }).length;
});

const filteredUsers = computed(() => {
    let list = [...users.value];

    if (showInactiveOnly.value) {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 30);
        list = list.filter((u) => {
            if (!u.last_seen_at) return true; // never logged in
            return new Date(u.last_seen_at) < cutoff;
        });
    }

    if (userSearch.value.trim()) {
        const q = userSearch.value.toLowerCase();
        list = list.filter(
            (u) =>
                u.email?.toLowerCase().includes(q) ||
                u.display_name?.toLowerCase().includes(q) ||
                u.username?.toLowerCase().includes(q),
        );
    }

    return list;
});

const filteredSvgs = computed(() => {
    let list = [...allSvgs.value];

    if (svgSearch.value.trim()) {
        const q = svgSearch.value.toLowerCase();
        list = list.filter(
            (s) =>
                s.name.toLowerCase().includes(q) ||
                s.tags?.some((t) => t.toLowerCase().includes(q)),
        );
    }

    if (svgCategory.value) {
        list = list.filter((s) => s.category === svgCategory.value);
    }

    if (svgStatusFilter.value !== "all") {
        list = list.filter((s) => s.status === svgStatusFilter.value);
    }

    // เรียงตามสถานะ: pending ก่อน แล้วตามด้วย created_at
    list.sort((a, b) => {
        const order: Record<string, number> = {
            pending: 0,
            rejected: 1,
            approved: 2,
        };
        const oa = order[a.status] ?? 3;
        const ob = order[b.status] ?? 3;
        if (oa !== ob) return oa - ob;
        return (
            new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        );
    });

    return list;
});

const pendingCount = computed(
    () => allSvgs.value.filter((s) => s.status === "pending").length,
);

// Map from userId → display label (for SVG owner column)
const ownerMap = computed(() => {
    const m = new Map<string, string>();
    users.value.forEach((u) => {
        m.set(
            u.id,
            u.display_name || u.email?.split("@")[0] || u.id.slice(0, 8),
        );
    });
    return m;
});

// ── Helpers ──────────────────────────────────────────────────
const showToast = (
    message: string,
    type: "success" | "error" | "info" = "success",
) => {
    toast.value = { message, type };
};

const formatDate = (dateStr: string | null): string => {
    if (!dateStr) return "-";
    try {
        return new Intl.DateTimeFormat("th-TH", {
            year: "numeric",
            month: "short",
            day: "numeric",
        }).format(new Date(dateStr));
    } catch {
        return dateStr;
    }
};

const formatRelativeDate = (dateStr: string): string => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const days = Math.floor(diff / 86_400_000);
    if (days === 0) return "วันนี้";
    if (days === 1) return "เมื่อวาน";
    if (days < 30) return `${days} วันที่แล้ว`;
    const months = Math.floor(days / 30);
    if (months < 12) return `${months} เดือนที่แล้ว`;
    return `${Math.floor(months / 12)} ปีที่แล้ว`;
};

const isInactive = (lastSeen: string | null): boolean => {
    if (!lastSeen) return true;
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    return new Date(lastSeen) < cutoff;
};

/** Produce a namespaced SVG for the mini-card preview */
/**
 * Rewrite every `id="…"` definition and every `url(#…)` / `href="#…"` /
 * `xlink:href="#…"` reference inside the SVG so they are namespaced with a
 * per-card prefix.  This prevents gradient/filter/clip collisions when many
 * cards are visible at the same time (same bug fix as SVGCard.vue).
 */
function scopeSvgIds(svg: string, prefix: string): string {
    const idRegex = /\bid="([^"]+)"/g;
    const ids: string[] = [];
    let m: RegExpExecArray | null;
    while ((m = idRegex.exec(svg)) !== null) {
        ids.push(m[1]);
    }
    if (ids.length === 0) return svg;

    const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    let result = svg;
    for (const id of ids) {
        const escapedId = escape(id);
        const newId = `${prefix}${id}`;
        result = result.replace(new RegExp(`\\bid="${escapedId}"`, "g"), `id="${newId}"`);
        result = result.replace(new RegExp(`url\\(#${escapedId}\\)`, "g"), `url(#${newId})`);
        result = result.replace(new RegExp(`href="#${escapedId}"`, "g"), `href="#${newId}"`);
        result = result.replace(new RegExp(`xlink:href="#${escapedId}"`, "g"), `xlink:href="#${newId}"`);
    }
    return result;
}

const getScopedSvg = (svg: SvgAsset): string => {
    if (!svg.svg_code) return "";
    const cleaned = sanitizeSvg(svg.svg_code);
    const prefix = `adm-${svg.id}-`;
    const scoped = scopeSvgIds(cleaned, prefix);
    return scoped.replace(
        /<svg/i,
        '<svg style="max-width:100%;max-height:100%;width:auto;height:auto;"',
    );
};

// ── Data Fetching ─────────────────────────────────────────────
const loadUsers = async () => {
    usersLoading.value = true;
    usersError.value = null;
    try {
        const { data, error } = await supabase.rpc("svgbox_admin_list_users");
        if (error) throw error;
        users.value = (data as AdminUser[]) ?? [];
    } catch (e: unknown) {
        usersError.value =
            e instanceof Error ? e.message : "ไม่สามารถโหลดข้อมูลผู้ใช้ได้";
    } finally {
        usersLoading.value = false;
    }
};

const loadSvgs = async () => {
    await fetchAll();
};

// ── User Actions ──────────────────────────────────────────────
const handleDeleteUser = async () => {
    if (!confirmDeleteUser.value) return;
    isDeleting.value = true;
    try {
        const { error } = await supabase.rpc("svgbox_admin_delete_user", {
            target_user_id: confirmDeleteUser.value.id,
        });
        if (error) throw error;
        showToast(
            `User ${confirmDeleteUser.value.display_name || confirmDeleteUser.value.email} deleted`,
            "success",
        );
        confirmDeleteUser.value = null;
        await loadUsers();
        await loadSvgs(); // refresh svg count
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : "An error occurred",
            "error",
        );
    } finally {
        isDeleting.value = false;
    }
};

const handleChangeRole = async () => {
    if (!confirmRoleChange.value) return;
    isChangingRole.value = true;
    try {
        const { error } = await supabase
            .from("svgbox_profiles")
            .update({ role: newRoleTarget.value })
            .eq("id", confirmRoleChange.value.id);
        if (error) throw error;

        // Update local state immediately
        const u = users.value.find((u) => u.id === confirmRoleChange.value!.id);
        if (u) u.role = newRoleTarget.value;

        showToast("Role updated", "success");
        confirmRoleChange.value = null;
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : "An error occurred",
            "error",
        );
    } finally {
        isChangingRole.value = false;
    }
};

// ── SVG Actions ───────────────────────────────────────────────
const handleDeleteSvg = async () => {
    if (!confirmDeleteSvg.value) return;
    isDeletingSvg.value = true;
    try {
        await removeSvg(confirmDeleteSvg.value.id);
        showToast("SVG deleted", "success");
        confirmDeleteSvg.value = null;
        await loadSvgs();
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : "An error occurred",
            "error",
        );
    } finally {
        isDeletingSvg.value = false;
    }
};

/** Open the review modal so admin can choose approve/reject + public toggle. */
const openReview = (
    svg: SvgAsset,
    action: "approve" | "reject",
    makePublic: boolean,
) => {
    reviewTarget.value = svg;
    reviewAction.value = action;
    // If approving and the SVG is currently private, default to "make public".
    // If rejecting, keep the current visibility (don't change it).
    reviewTogglePublic.value =
        action === "approve" && svg.is_private ? makePublic : !svg.is_private;
};

/** Confirm review from the modal — apply status + visibility atomically. */
const handleReview = async () => {
    if (!reviewTarget.value) return;
    isReviewing.value = true;
    try {
        await adminReview(
            reviewTarget.value.id,
            reviewAction.value === "approve" ? "approved" : "rejected",
            !reviewTogglePublic.value, // checkbox means "make public"
        );
        showToast(
            reviewAction.value === "approve" ? "SVG approved" : "SVG rejected",
            "success",
        );
        reviewTarget.value = null;
        await loadSvgs();
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : "An error occurred",
            "error",
        );
    } finally {
        isReviewing.value = false;
    }
};

/** Toggle a single SVG's visibility (public ↔ private) without changing status. */
const toggleVisibility = async (svg: SvgAsset) => {
    try {
        // Use adminReview to keep the guard trigger happy; status stays the same.
        await adminReview(svg.id, svg.status, !svg.is_private);
        showToast(
            !svg.is_private ? "Set to Private" : "Set to Public",
            "success",
        );
        await loadSvgs();
    } catch (e: unknown) {
        showToast(
            e instanceof Error ? e.message : "An error occurred",
            "error",
        );
    }
};

// Suppress unused warning — kept for future use
void updateSvg;

// ── Lifecycle ─────────────────────────────────────────────────
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
        await Promise.all([loadUsers(), loadSvgs()]);
    } catch {
        // Swallow errors — the page keeps showing whatever data it already has
    } finally {
        isRecovering = false;
    }
};

onMounted(async () => {
    await Promise.all([loadUsers(), loadSvgs()]);
    restoreScroll();
    document.addEventListener("visibilitychange", handleVisibilityChange);
});

onUnmounted(() => {
    document.removeEventListener("visibilitychange", handleVisibilityChange);
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
 * CSS transitions fire `transitionend` reliably in all these edge cases.
 * `pointer-events: none` on leave-active is an extra safety net so that even
 * during the brief fade-out, the backdrop never intercepts clicks.
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
</style>
