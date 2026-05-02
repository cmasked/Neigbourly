import { getItems } from "/static/api.js";
import { resolveItemImage, buildItemPlaceholder } from "/static/utils/itemImage.js";

export default {
    template: `
    <div class="px-8 max-w-screen-2xl mx-auto py-12">
        <header class="mb-16 md:flex justify-between items-end">
            <div class="max-w-2xl">
                <p class="font-label text-sm uppercase tracking-widest text-[#6c6152] mb-3">Neighborhood Rentals</p>
                <h1 class="text-5xl md:text-6xl font-headline font-bold text-[#34322a] leading-tight flex flex-col">
                    <span>Borrow from</span>
                    <span class="text-[#5a46d6] italic pr-8 md:text-right">your local mates.</span>
                </h1>
            </div>
            <div class="mt-8 md:mt-0">
                <button
                    class="bg-gradient-to-b from-[#5a46d6] to-[#4e37ca] text-[#fcf7ff] font-headline font-bold px-8 py-3 rounded-full flex items-center gap-2 shadow-[inset_0_2px_4px_rgba(252,247,255,0.1)] transition-transform hover:scale-105"
                    @click="goToNewItem">
                    <span class="material-symbols-outlined text-[20px]">add</span>
                    List an Item
                </button>
            </div>
        </header>

        <!-- Filter Chips (Neighborhood Board) -->
        <div class="flex gap-3 mb-10 overflow-x-auto pb-4 hide-scrollbar">
            <button v-for="cat in categories" :key="cat"
                @click="filterItems(cat)"
                class="px-5 py-2 rounded-xl text-sm font-label whitespace-nowrap transition-colors border"
                :class="cat === activeCategory ? 'bg-[#5a46d6] text-[#fcf7ff] border-transparent' : 'bg-[#fbecd8] text-[#5c5243] border-[#edddca] hover:bg-[#edddca]'">
                {{ cat }}
            </button>
        </div>

        <div v-if="loading" class="text-center py-20 font-label text-on-surface-variant">Loading neighborhood listings...</div>
        <div v-else-if="error" class="text-center py-20 text-error">{{ error }}</div>

        <!-- Neighborhood Board Layout -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-x-8 gap-y-14 relative z-10" v-else>
            <div v-for="item in items" :key="item.id" class="item-container relative group cursor-pointer group"
                @click="openItem(item.id)">
                <div class="ambient-shadow"></div>
                <div class="item-image-wrapper aspect-square mb-4 bg-surface-container-high flex items-center justify-center relative">
                    <img :src="getItemImage(item)"
                         :alt="item.title"
                         @error="onItemImageError($event, item)"
                         class="item-image w-[80%] h-[80%] object-contain drop-shadow-xl" />
                    
                    <!-- Availability Pill -->
                    <div class="absolute top-4 left-4 bg-surface/80 backdrop-blur-md rounded-full px-3 py-1 flex items-center gap-1 border border-white/20">
                        <span class="w-2 h-2 rounded-full" :class="isRentable(item) ? 'bg-green-500' : 'bg-red-500'"></span>
                        <span class="text-xs font-bold font-label text-on-surface uppercase">{{ isRentable(item) ? 'Available' : 'Rented' }}</span>
                    </div>
                </div>

                <div class="shelf-plank"></div>
                <div class="contact-shadow"></div>

                <div class="mt-6 px-2">
                    <div class="flex justify-between items-start mb-1">
                        <h3 class="font-headline font-bold text-lg text-on-surface truncate">{{ item.title }}</h3>
                        <span class="font-label font-bold text-primary">\${{ item.daily_rate }}/d</span>
                    </div>
                    <p class="font-label text-sm text-on-surface-variant line-clamp-2">{{ item.description }}</p>
                    
                    <div class="mt-3 flex items-center gap-2 text-xs font-label text-[#6c6152]">
                        <span class="material-symbols-outlined text-[16px]">person</span>
                        {{ item.owner?.username || 'Neighborhood Member' }}
                    </div>
                </div>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            items: [],
            loading: true,
            error: null,
            categories: ["All", "Study Gear", "Electronics", "Kitchen", "Sports", "Books", "Furniture"],
            activeCategory: "All"
        };
    },
    async mounted() {
        await this.loadItems();
    },
    methods: {
        categoryRank(category) {
            const order = {
                "study gear": 1,
                "electronics": 2,
                "kitchen": 3,
                "sports": 4,
                "books": 5,
                "furniture": 6,
            };
            return order[String(category || "").trim().toLowerCase()] ?? 99;
        },
        sortItems(items) {
            return [...items].sort((left, right) => {
                const categoryDiff = this.categoryRank(left.category) - this.categoryRank(right.category);
                if (categoryDiff !== 0) return categoryDiff;
                return String(left.title || "").localeCompare(String(right.title || ""));
            });
        },
        isRentable(item) {
            const status = (item?.status || "").toLowerCase();
            return !["rented", "inactive", "removed"].includes(status);
        },
        async loadItems() {
            this.loading = true;
            this.error = null;
            try {
                let catFilter = this.activeCategory === "All" ? "" : this.activeCategory;
                const fetchedItems = await getItems(0, 50);
                let filtered = fetchedItems;
                if (catFilter) {
                    filtered = fetchedItems.filter(item => (item.category || "").toLowerCase() === catFilter.toLowerCase());
                }
                this.items = this.sortItems(filtered);
            } catch (err) {
                this.error = err.message || "Failed to load items. Make sure backend is running.";
            } finally {
                this.loading = false;
            }
        },
        filterItems(cat) {
            this.activeCategory = cat;
            this.loadItems();
        },
        goToNewItem() {
            window.location.hash = '#/items/new';
        },
        getItemImage(item) {
            return resolveItemImage(item);
        },
        onItemImageError(event, item) {
            // Prevent error loops and force an always-available generated placeholder.
            event.currentTarget.onerror = null;
            event.currentTarget.src = buildItemPlaceholder(item);
        },
        openItem(itemId) {
            window.location.hash = `#/item?id=${itemId}`;
        }
    }
};