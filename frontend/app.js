import Navbar from '/static/components/Navbar.js';
import Browse from '/static/views/Browse.js';
import Login from '/static/views/Login.js';
import Register from '/static/views/Register.js';
import Requests from '/static/views/Requests.js';
import Transactions from '/static/views/Transactions.js';
import Reviews from '/static/views/Reviews.js';
import NewItem from '/static/views/NewItem.js';
import ItemDetail from '/static/views/ItemDetail.js';
import { getCurrentUser, logout } from '/static/api.js';

const { createApp, ref, computed, onMounted } = Vue;

// Hash router supporting exact matches or simple paths
const routes = {
    '/': Browse,
    '/login': Login,
    '/register': Register,
    '/requests': Requests,
    '/transactions': Transactions,
    '/reviews': Reviews,
    '/items/new': NewItem,
    '/item': ItemDetail,
};

createApp({
    components: { Navbar },
    setup() {
        const user = ref(null);
        const currentHash = ref(window.location.hash.slice(1) || '/');

        // Extract path and query params from hash routing
        const currentPath = computed(() => currentHash.value.split('?')[0]);
        const currentParams = computed(() => {
            const query = currentHash.value.split('?')[1];
            if (!query) return {};
            return Object.fromEntries(new URLSearchParams(query));
        });

        const currentView = computed(() => {
            return routes[currentPath.value] || Browse;
        });

        // Initialize User
        onMounted(async () => {
            window.addEventListener('hashchange', () => {
                currentHash.value = window.location.hash.slice(1) || '/';
            });

            if (localStorage.getItem('accessToken')) {
                try {
                    user.value = await getCurrentUser();
                } catch (err) {
                    console.error('Failed to restore session:', err);
                    handleLogout();
                }
            } else if (currentPath.value !== '/login' && currentPath.value !== '/register') {
                window.location.hash = '#/login';
            }
        });

        const handleUserUpdated = (newUser) => {
            user.value = newUser;
        };

        const handleLogout = () => {
            logout();
            user.value = null;
        };

        return {
            user,
            currentPath,
            currentParams,
            currentView,
            handleUserUpdated,
            handleLogout
        };
    },
    template: `
        <div class="min-h-screen flex flex-col relative z-10 w-full overflow-x-hidden">
            <Navbar :user="user" @logout="handleLogout" />
            <main class="flex-grow w-full pb-20">
                <component :is="currentView" :user="user" :routeParams="currentParams" @user-updated="handleUserUpdated" />
            </main>
        </div>
    `
}).mount('#app');