export default {
    props: ['user'],
    template: `
    <header class="w-full top-0 sticky z-[60] bg-[#F6F1E9]/40 backdrop-blur-lg shadow-[0_1px_4px_-1px_rgba(0,0,0,0.05)] border-b border-black/5">
        <div class="flex justify-between items-center px-4 sm:px-8 py-4 max-w-screen-2xl mx-auto">
            <div class="flex items-center gap-8">
                <a href="#/" class="text-2xl font-bold text-[#5a46d6] italic font-headline flex items-center gap-2">
                    <span class="material-symbols-outlined">handshake</span>
                    Neighborly
                </a>
                
                <nav class="hidden md:flex gap-6 items-center" v-if="user">
                    <a class="text-[#5a46d6] font-bold font-headline text-sm tracking-tight transition-opacity hover:opacity-80" href="#/">Listings</a>
                    <a class="text-[#4e4537] font-headline text-sm tracking-tight transition-opacity hover:opacity-80" href="#/requests">Local Requests</a>
                    <a class="text-[#4e4537] font-headline text-sm tracking-tight transition-opacity hover:opacity-80" href="#/transactions">Neighborhood Ledger</a>
                    <a class="text-[#4e4537] font-headline text-sm tracking-tight transition-opacity hover:opacity-80" href="#/reviews">Reviews</a>
                </nav>
            </div>
            
            <div class="flex items-center gap-4 sm:gap-6">
                <!-- Search bar hidden on mobile -->
                <div class="relative hidden lg:block" v-if="user">
                    <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#625f55]">search</span>
                    <input class="bg-[#e7e2d5]/50 border-none rounded-full py-2 pl-10 pr-4 text-sm w-64 focus:ring-2 focus:ring-[#5a46d6]/20 bg-[#e7e2d5] transition-all font-body text-[#34322a]" placeholder="Find a study lamp, kettle, books..." type="text"/>
                </div>

                <template v-if="user">
                    <div class="flex items-center gap-3">
                        <div class="hidden sm:flex flex-col items-end">
                            <span class="text-sm font-headline font-bold text-on-surface">{{ user.username }}</span>
                            <span class="text-xs font-label text-primary flex items-center gap-1">
                                <span class="material-symbols-outlined text-[12px]">workspace_premium</span>
                                {{ user.trust_score?.score !== undefined ? user.trust_score.score : 'N/A' }} Neighborhood Trust
                            </span>
                        </div>
                        <button @click="$emit('logout')" class="text-[#625f55] hover:text-[#ac3149] transition-colors p-2 rounded-full hover:bg-black/5" title="Logout">
                            <span class="material-symbols-outlined">logout</span>
                        </button>
                    </div>
                </template>
                <template v-else>
                    <a href="#/login" class="font-headline font-bold text-sm text-[#4e4537] hover:text-[#5a46d6] transition-colors">Sign in</a>
                    <a href="#/register" class="bg-[#e6deff] text-[#544694] font-headline font-bold text-sm px-4 py-2 rounded-full hover:bg-[#c1b9ff] transition-colors">Join</a>
                </template>
            </div>
        </div>
    </header>
    `
};