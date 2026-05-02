import { createItem } from "/static/api.js";

export default {
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12 flex justify-center">
        <div class="w-full max-w-2xl bg-surface-container-lowest rounded-2xl p-10 shadow-[0_16px_32px_-4px_rgba(52,50,42,0.05)] relative overflow-hidden">
            
            <header class="mb-10 text-center relative z-10">
                <p class="font-label text-sm uppercase tracking-widest text-primary mb-2">Share with the Neighborhood</p>
                <h1 class="text-4xl font-headline font-bold text-on-surface leading-tight">
                    List a <span class="text-primary italic">Local Item</span>
                </h1>
            </header>

            <form @submit.prevent="submitItem" class="flex flex-col gap-6 relative z-10">
                <div v-if="error" class="bg-error-container/20 text-error p-4 rounded-xl text-sm font-label text-center border border-error-container">
                    {{ error }}
                </div>

                <div class="flex flex-col gap-2">
                    <label class="font-label text-sm font-bold text-on-surface-variant">Title</label>
                    <input v-model="form.title" required minlength="3" placeholder="e.g. DeWalt 12ft Ladder" type="text"
                        class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                </div>

                <div class="flex flex-col gap-2">
                    <label class="font-label text-sm font-bold text-on-surface-variant">Description</label>
                    <textarea v-model="form.description" rows="3" placeholder="Describe the item and any particulars..."
                        class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full"></textarea>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Category</label>
                        <select v-model="form.category" required class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full">
                            <option value="" disabled>Select category</option>
                            <option value="Study Gear">Study Gear</option>
                            <option value="Outdoors">Sports & Weekend Gear</option>
                            <option value="Kitchen">Kitchen Appliances</option>
                            <option value="Electronics">Electronics</option>
                            <option value="Furniture">Furniture</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Daily Rate ($)</label>
                        <input v-model.number="form.daily_rate" required type="number" step="0.01" min="0.01" placeholder="15.00"
                            class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Weekly Rate ($) (Optional)</label>
                        <input v-model.number="form.weekly_rate" type="number" step="0.01" min="0.01" placeholder="70.00"
                            class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                    </div>
                    <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Deposit Required ($)</label>
                        <input v-model.number="form.deposit_required" type="number" step="0.01" min="0" placeholder="0.00" required
                            class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                    </div>
                </div>

                <div class="flex flex-col gap-2">
                        <label class="font-label text-sm font-bold text-on-surface-variant">Condition Notes (Optional)</label>
                    <input v-model="form.condition_description" type="text" placeholder="e.g. Scratched but works perfectly."
                        class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                </div>
                
                <div class="flex flex-col gap-2">
                    <label class="font-label text-sm font-bold text-on-surface-variant">Image URL (Optional)</label>
                    <input v-model="imageUrlInput" type="url" placeholder="https://example.com/image.jpg"
                        class="bg-surface-container border-transparent rounded-xl py-3 px-4 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors text-on-surface w-full" />
                </div>

                <div class="mt-4">
                    <button type="submit" :disabled="loading" class="w-full bg-gradient-to-b from-primary to-primary-dim text-on-primary font-headline font-bold py-4 rounded-xl shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50 text-lg">
                        {{ loading ? 'Posting...' : 'Post Listing' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
    `,
    data() {
        return {
            form: {
                title: '',
                description: '',
                category: '',
                daily_rate: null,
                weekly_rate: null,
                deposit_required: 0,
                condition_description: ''
            },
            imageUrlInput: '',
            loading: false,
            error: null
        };
    },
    methods: {
        async submitItem() {
            this.loading = true;
            this.error = null;

            const payload = { ...this.form };
            if (this.imageUrlInput) {
                payload.image_urls = [this.imageUrlInput];
            } else {
                payload.image_urls = [];
            }
            if (!payload.weekly_rate) {
                delete payload.weekly_rate;
            }

            try {
                await createItem(payload);
                window.location.hash = '#/';
            } catch (err) {
                this.error = err.message || "Failed to post listing.";
            } finally {
                this.loading = false;
            }
        }
    }
};