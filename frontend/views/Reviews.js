import { getUserReviews } from "/static/api.js";

export default {
    props: ["user"],
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12">
        <header class="mb-12">
            <p class="font-label text-sm uppercase tracking-widest text-[#6c6152] mb-3">Community Trust</p>
            <h1 class="text-4xl md:text-5xl font-headline font-bold text-[#34322a] leading-tight">
                My <span class="text-[#5a46d6] italic">Reviews</span>
            </h1>
        </header>

        <div v-if="loading" class="text-center py-20 font-label text-on-surface-variant">Loading reviews...</div>
        <div v-else-if="error" class="text-center py-20 text-error">{{ error }}</div>

        <div v-else class="relative z-10 w-full bg-surface-container-lowest rounded-2xl shadow-[0_16px_32px_-4px_rgba(52,50,42,0.05)] border border-outline-variant/10 overflow-hidden">
            <div v-if="reviews.length === 0" class="py-16 text-center font-label text-[#6c6152]">
                You have not received any reviews yet.
            </div>
            
            <div v-else class="overflow-x-auto">
                <table class="w-full text-left font-label border-collapse">
                    <thead>
                        <tr class="bg-surface-container-low text-on-surface-variant text-sm uppercase tracking-wider border-b border-outline-variant/20">
                            <th class="px-6 py-4 font-bold">Reviewer</th>
                            <th class="px-6 py-4 font-bold">Rating</th>
                            <th class="px-6 py-4 font-bold">Comment</th>
                            <th class="px-6 py-4 font-bold">Transaction</th>
                        </tr>
                    </thead>
                    <tbody class="text-on-surface">
                        <tr v-for="rev in reviews" :key="rev.id" class="border-b border-outline-variant/10 hover:bg-surface-container transition-colors">
                            <td class="px-6 py-4 truncate max-w-[120px]">{{ shortId(rev.reviewer_id) }}</td>
                            <td class="px-6 py-4 text-primary font-bold">
                                {{ rev.rating }} / 5
                            </td>
                            <td class="px-6 py-4 max-w-md break-words">{{ rev.comment || "No comment provided." }}</td>
                            <td class="px-6 py-4 text-on-surface-variant text-xs">#{{ shortId(rev.transaction_id) }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            reviews: [],
            loading: true,
            error: null,
        };
    },
    computed: {
        currentUserId() {
            return this.user?.id || this.user?.user_id || null;
        }
    },
    async mounted() {
        if (!this.currentUserId) {
            this.loading = false;
            return;
        }
        await this.loadData();
    },
    methods: {
        shortId(id) {
            return String(id || "").substring(0, 8);
        },
        async loadData() {
            this.loading = true;
            this.error = null;
            try {
                this.reviews = await getUserReviews(this.currentUserId);
            } catch (err) {
                this.error = err.message || "Failed to load reviews.";
            } finally {
                this.loading = false;
            }
        }
    }
};