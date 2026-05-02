import { getIncomingRentalRequests, acceptRentalRequest, rejectRentalRequest } from "/static/api.js?v=20260420f";

export default {
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12">
        <header class="mb-12">
            <p class="font-label text-sm uppercase tracking-widest text-[#6c6152] mb-3">Local Inbox</p>
            <h1 class="text-4xl md:text-5xl font-headline font-bold text-[#34322a] leading-tight">
                Local <span class="text-[#5a46d6] italic">Requests</span>
            </h1>
        </header>

        <div v-if="loading" class="text-center py-20 font-label text-on-surface-variant">Loading requests...</div>
        <div v-else-if="error" class="text-center py-20 text-error">{{ error }}</div>
        
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 relative z-10 w-full">
            <div v-if="requests.length === 0" class="col-span-full py-16 text-center font-label text-[#6c6152] bg-surface-container-high rounded-xl">
                No local requests found. You're all caught up!
            </div>
            
            <!-- Cards (surface-container-lowest) popping over surface-container-low -->
            <div v-for="req in requests" :key="req.id" class="bg-surface-container-lowest rounded-xl p-8 relative overflow-hidden shadow-[0_16px_32px_-4px_rgba(52,50,42,0.05)] transition-transform hover:-translate-y-1">
                <div class="absolute top-0 right-0 px-4 py-2 text-xs font-bold font-label uppercase"
                    :class="{
                        'bg-yellow-100 text-yellow-800': req.status === 'pending',
                        'bg-green-100 text-green-800': req.status === 'accepted' || req.status === 'approved',
                        'bg-red-100 text-red-800': req.status === 'rejected',
                        'bg-gray-100 text-gray-800': req.status === 'canceled'
                    }">
                    {{ req.status }}
                </div>
                
                <div class="flex flex-col gap-4">
                    <div>
                        <h3 class="font-headline font-bold text-xl text-on-surface mb-1">Request for Item #{{ req.item_id.substring(0,8) }}</h3>
                        <p class="font-label text-sm text-[#6c6152]">Requested by Student: {{ req.borrower_id.substring(0,8) }}</p>
                    </div>

                    <div class="bg-surface-container-high rounded-lg p-4 font-label text-sm text-on-surface-variant">
                        <div class="flex justify-between mb-2">
                            <span>Dates</span>
                            <span class="font-bold text-on-surface">{{ new Date(req.start_date).toLocaleDateString() }} - {{ new Date(req.end_date).toLocaleDateString() }}</span>
                        </div>
                        <div class="flex justify-between" v-if="req.message">
                            <span>Message:</span>
                            <span class="italic">"{{ req.message }}"</span>
                        </div>
                    </div>
                    
                    <!-- Actions -->
                    <div class="mt-4 flex gap-3" v-if="req.status === 'pending'">
                        <button @click="acceptReq(req.id)" class="flex-1 bg-gradient-to-b from-primary to-primary-dim text-on-primary font-headline font-bold py-2 rounded-full shadow-sm hover:opacity-90 transition-opacity">
                            Approve
                        </button>
                        <button @click="rejectReq(req.id)" class="flex-1 bg-secondary-container text-on-secondary-container font-headline font-bold py-2 rounded-full hover:bg-[#d8ceff] transition-colors">
                            Decline
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            requests: [],
            loading: true,
            error: null
        };
    },
    async mounted() {
        await this.loadData();
    },
    methods: {
        async loadData() {
            this.loading = true;
            this.error = null;
            try {
                this.requests = await getIncomingRentalRequests();
            } catch (err) {
                this.error = err.message || "Failed to load requests.";
            } finally {
                this.loading = false;
            }
        },
        async acceptReq(id) {
            try {
                await acceptRentalRequest(id);
                await this.loadData();
            } catch (err) {
                alert(err.message);
            }
        },
        async rejectReq(id) {
            try {
                await rejectRentalRequest(id);
                await this.loadData();
            } catch (err) {
                alert(err.message);
            }
        }
    }
};