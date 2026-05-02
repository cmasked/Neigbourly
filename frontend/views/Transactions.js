import { getTransactions, createReview } from "/static/api.js";

export default {
    props: ["user"],
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12 relative">
        <!-- Review Modal -->
        <div v-if="reviewingTx" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div class="bg-surface-container-lowest rounded-2xl p-8 max-w-md w-full shadow-2xl relative">
                <button @click="closeReviewModal" class="absolute top-4 right-4 text-on-surface-variant hover:text-on-surface">
                    <span class="material-symbols-outlined">close</span>
                </button>
                <h2 class="text-2xl font-headline font-bold mb-6 text-on-surface">Leave a Review</h2>
                
                <div v-if="reviewError" class="mb-4 bg-error-container/20 text-error p-3 rounded-lg text-sm font-label text-center border border-error-container">
                    {{ reviewError }}
                </div>
                
                <form @submit.prevent="submitReview" class="flex flex-col gap-4">
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Rating (1-5)</label>
                        <select v-model.number="reviewForm.rating" required class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 text-on-surface w-full">
                            <option value="5">5 - Excellent</option>
                            <option value="4">4 - Good</option>
                            <option value="3">3 - Average</option>
                            <option value="2">2 - Poor</option>
                            <option value="1">1 - Terrible</option>
                        </select>
                    </div>
                    
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Comment</label>
                        <textarea v-model="reviewForm.comment" rows="3" placeholder="Tell the community how it went..."
                            class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 text-on-surface w-full"></textarea>
                    </div>
                    
                    <button type="submit" :disabled="submittingReview" 
                        class="mt-4 w-full bg-gradient-to-b from-primary to-primary-dim text-on-primary font-headline font-bold py-3 rounded-xl shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50">
                        {{ submittingReview ? 'Submitting...' : 'Submit Review' }}
                    </button>
                </form>
            </div>
        </div>

        <header class="mb-12">
            <p class="font-label text-sm uppercase tracking-widest text-[#6c6152] mb-3">Neighborhood Ledger</p>
            <h1 class="text-4xl md:text-5xl font-headline font-bold text-[#34322a] leading-tight">
                My <span class="text-[#5a46d6] italic">Neighborhood Ledger</span>
            </h1>
        </header>

        <div v-if="loading" class="text-center py-20 font-label text-on-surface-variant">Loading transactions...</div>
        <div v-else-if="error" class="text-center py-20 text-error">{{ error }}</div>

        <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-8 relative z-10 w-full">
            <div v-if="decoratedTransactions.length === 0" class="col-span-full py-16 text-center font-label text-[#6c6152] bg-surface-container-high rounded-xl">
                No local transactions found for your account.
            </div>

            <div v-for="tx in decoratedTransactions" :key="tx.id" class="bg-surface-container-lowest flex flex-col gap-4 p-6 rounded-xl shadow-[0_16px_32px_-4px_rgba(52,50,42,0.05)] border border-outline-variant/10">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h3 class="font-headline font-bold text-[18px] text-on-surface">Ledger #{{ shortId(tx.id) }}</h3>
                        <p class="text-sm font-label text-on-surface-variant">Item #{{ shortId(tx.item_id) }}</p>
                    </div>
                    <div class="text-right">
                        <p class="font-label text-xs font-bold uppercase tracking-wider"
                           :class="tx.perspectiveType === 'student_payment' ? 'text-primary' : 'text-[#3f7a4b]'">
                            {{ tx.perspectiveLabel }}
                        </p>
                        <p class="font-label text-xs font-bold uppercase tracking-wider text-on-surface-variant">{{ prettifyStatus(tx.status) }}</p>
                    </div>
                </div>

                <div class="text-sm font-label text-on-surface-variant flex flex-col gap-1">
                    <p><strong>Total:</strong> \${{ money(tx.total_rental_fee) }}</p>
                    <p><strong>Period:</strong> {{ formatDate(tx.start_date) }} - {{ formatDate(tx.end_date) }}</p>
                </div>

                <div class="h-1 w-full bg-surface-container-highest rounded-full overflow-hidden">
                    <div class="h-full bg-primary transition-all" :style="{ width: getProgressWidth(tx.status) }"></div>
                </div>
                
                <!-- Review Button for completed transactions -->
                <div v-if="tx.status === 'completed'" class="mt-2 text-right">
                    <button @click="openReviewModal(tx)" class="text-sm font-headline font-bold text-primary hover:text-primary-dim transition-colors">
                        Leave a Review
                    </button>
                </div>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            transactions: [],
            loading: true,
            error: null,
            reviewingTx: null,
            reviewError: null,
            submittingReview: false,
            reviewForm: {
                rating: 5,
                comment: ''
            }
        };
    },
    computed: {
        currentUserId() {
            return this.user?.id || this.user?.user_id || null;
        },
        decoratedTransactions() {
            return this.transactions.map((tx) => {
                const isBorrower = this.currentUserId && tx.borrower_id === this.currentUserId;
                return {
                    ...tx,
                    perspectiveType: isBorrower ? "student_payment" : "local_income",
                    perspectiveLabel: isBorrower ? "Student Payment" : "Local Income",
                };
            });
        },
    },
    async mounted() {
        await this.loadData();
    },
    methods: {
        async loadData() {
            this.loading = true;
            this.error = null;
            try {
                this.transactions = await getTransactions();
            } catch (err) {
                this.error = err.message || "Failed to load transactions.";
            } finally {
                this.loading = false;
            }
        },
        shortId(id) {
            return String(id || "").substring(0, 8);
        },
        money(v) {
            const n = Number(v || 0);
            return Number.isFinite(n) ? n.toFixed(2) : "0.00";
        },
        formatDate(d) {
            return new Date(d).toLocaleDateString();
        },
        prettifyStatus(status) {
            return String(status || "").replace(/_/g, " ");
        },
        getProgressWidth(status) {
            const flow = {
                pending_payment: "10%",
                booking_confirmed: "30%",
                active: "60%",
                completed: "100%",
                disputed: "100%",
                canceled: "100%",
                accepted: "40%",
                rejected: "100%",
            };
            return flow[status] || "20%";
        },
        openReviewModal(tx) {
            this.reviewingTx = tx;
            this.reviewError = null;
            this.reviewForm.rating = 5;
            this.reviewForm.comment = '';
        },
        closeReviewModal() {
            this.reviewingTx = null;
        },
        async submitReview() {
            if (!this.reviewingTx) return;
            
            this.submittingReview = true;
            this.reviewError = null;
            
            const isBorrower = this.currentUserId === this.reviewingTx.borrower_id;
            const revieweeId = isBorrower ? this.reviewingTx.owner_id : this.reviewingTx.borrower_id;
            
            try {
                await createReview({
                    transaction_id: this.reviewingTx.id,
                    reviewee_id: revieweeId,
                    rating: this.reviewForm.rating,
                    comment: this.reviewForm.comment || undefined
                });
                alert("Review submitted successfully!");
                this.closeReviewModal();
            } catch (err) {
                this.reviewError = err.message || "Failed to submit review.";
            } finally {
                this.submittingReview = false;
            }
        }
    },
};