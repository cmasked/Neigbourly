import { getItem, createRentalRequest } from "/static/api.js";
import { resolveItemImage, buildItemPlaceholder } from "/static/utils/itemImage.js";

export default {
    props: ['user', 'routeParams'],
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12 flex justify-center">
        <div v-if="loading" class="text-center py-20 font-label text-on-surface-variant">Loading item details...</div>
        <div v-else-if="error" class="text-center py-20 text-error">{{ error }}</div>
        
        <div v-else-if="item" class="w-full grid grid-cols-1 md:grid-cols-2 gap-12 bg-surface-container-lowest rounded-2xl p-10 shadow-[0_16px_32px_-4px_rgba(52,50,42,0.05)]">
            
            <!-- Left Side: Image -->
            <div class="bg-surface-container-high rounded-xl aspect-square flex items-center justify-center relative p-8">
                <img :src="getItemImage(item)"
                     :alt="item.title"
                     @error="onItemImageError($event, item)"
                     class="w-[80%] h-[80%] object-contain drop-shadow-2xl" />
                
                <div class="absolute top-4 left-4 bg-surface/80 backdrop-blur-md rounded-full px-4 py-2 flex items-center gap-2 border border-white/20">
                    <span class="w-2.5 h-2.5 rounded-full" :class="isRentable(item) ? 'bg-green-500' : 'bg-red-500'"></span>
                    <span class="text-sm font-bold font-label text-on-surface uppercase">{{ isRentable(item) ? 'Available' : 'Currently Borrowed' }}</span>
                </div>
            </div>

            <!-- Right Side: Details & Request Form -->
            <div class="flex flex-col">
                <p class="font-label text-sm uppercase tracking-widest text-[#6c6152] mb-2">{{ item.category }}</p>
                <h1 class="text-4xl font-headline font-bold text-on-surface mb-4 leading-tight">{{ item.title }}</h1>
                
                <div class="flex items-center gap-4 mb-6">
                    <div class="bg-primary/10 text-primary px-4 py-2 rounded-full font-headline font-bold text-lg">
                        \${{ item.daily_rate }} / day
                    </div>
                    <div v-if="item.weekly_rate" class="bg-surface-container text-on-surface-variant px-4 py-2 rounded-full font-headline font-bold text-lg">
                        \${{ item.weekly_rate }} / week
                    </div>
                </div>

                <div class="text-on-surface-variant font-label leading-relaxed mb-8 flex-grow">
                    <p class="mb-4">{{ item.description || "No description provided." }}</p>
                    <p class="text-sm"><strong>Condition:</strong> {{ item.condition_description || "Good" }}</p>
                    <p class="text-sm mt-1"><strong>Required Deposit:</strong> \${{ item.deposit_required }}</p>
                </div>
                
                <div v-if="user && !isOwner(item)" class="bg-surface-container-low p-6 rounded-xl border border-outline-variant/20">
                    <h3 class="font-headline font-bold text-lg mb-4 text-on-surface">Borrow from Neighborhood</h3>
                    
                    <form @submit.prevent="submitRequest" class="flex flex-col gap-4">
                        <div class="grid grid-cols-2 gap-4">
                            <div class="flex flex-col gap-2">
                                <label class="font-label text-xs font-bold text-primary uppercase">Start Date</label>
                                <input v-model="form.start_date" type="date" required :min="today"
                                    class="bg-surface-container-lowest border-transparent rounded-lg py-2 px-3 text-sm focus:ring-primary w-full" />
                            </div>
                            <div class="flex flex-col gap-2">
                                <label class="font-label text-xs font-bold text-primary uppercase">End Date</label>
                                <input v-model="form.end_date" type="date" required :min="form.start_date || today"
                                    class="bg-surface-container-lowest border-transparent rounded-lg py-2 px-3 text-sm focus:ring-primary w-full" />
                            </div>
                        </div>

                        <div class="flex flex-col gap-2">
                            <label class="font-label text-xs font-bold text-primary uppercase">Message to Owner (Optional)</label>
                            <textarea v-model="form.message" rows="2" placeholder="Hi! I'd like to borrow this for a class project..."
                                class="bg-surface-container-lowest border-transparent rounded-lg py-2 px-3 text-sm focus:ring-primary w-full"></textarea>
                        </div>
                        
                        <div v-if="requestError" class="text-error text-sm font-label text-center">{{ requestError }}</div>

                        <button type="submit" :disabled="submitting" 
                            class="w-full bg-gradient-to-b from-primary to-primary-dim text-on-primary font-headline font-bold py-3 rounded-lg shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50 mt-2">
                            {{ submitting ? 'Sending Request...' : 'Send Request' }}
                        </button>
                    </form>
                </div>
                
                <div v-else-if="!user" class="text-center bg-surface-container p-6 rounded-xl">
                    <p class="font-label text-on-surface-variant mb-4">You need to sign in to request a neighborhood item.</p>
                    <a href="#/login" class="bg-primary text-on-primary font-headline font-bold px-6 py-2 rounded-full inline-block">Sign In</a>
                </div>
                
                <div v-else class="text-center bg-surface-container p-6 rounded-xl font-label text-on-surface-variant">
                    This item is listed by you.
                </div>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            item: null,
            loading: true,
            error: null,
            submitting: false,
            requestError: null,
            form: {
                start_date: '',
                end_date: '',
                message: ''
            }
        };
    },
    computed: {
        today() {
            return new Date().toISOString().split('T')[0];
        }
    },
    async mounted() {
        const itemId = this.routeParams?.id;
        if (!itemId) {
            this.error = "No item ID provided.";
            this.loading = false;
            return;
        }

        try {
            this.item = await getItem(itemId);
        } catch (err) {
            this.error = err.message || "Failed to load item.";
        } finally {
            this.loading = false;
        }
    },
    methods: {
        currentUserId() {
            return this.user?.id || this.user?.user_id || null;
        },
        isOwner(item) {
            const uid = this.currentUserId();
            return !!uid && uid === item?.owner_id;
        },
        isRentable(item) {
            const status = (item?.status || "").toLowerCase();
            return !["rented", "inactive", "removed"].includes(status);
        },
        getItemImage(item) {
            return resolveItemImage(item);
        },
        onItemImageError(event, item) {
            // Prevent error loops and use generated placeholder if URL fails.
            event.currentTarget.onerror = null;
            event.currentTarget.src = buildItemPlaceholder(item);
        },
        async submitRequest() {
            this.submitting = true;
            this.requestError = null;

            try {
                await createRentalRequest({
                    item_id: this.item.id,
                    start_date: this.form.start_date,
                    end_date: this.form.end_date,
                    proposed_daily_rate: this.item.daily_rate,
                    message: this.form.message
                });
                
                alert("Request sent successfully! Check your local requests.");
                window.location.hash = '#/requests';
            } catch (err) {
                this.requestError = err.message || "Failed to send request.";
                this.submitting = false;
            }
        }
    }
};