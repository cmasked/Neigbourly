import { login, logout } from "/static/api.js";

export default {
    template: `
    <div class="min-h-[80vh] flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-md">
            <h2 class="mt-6 text-center text-3xl font-headline tracking-tight text-primary font-bold italic">Neighborly</h2>
            <h2 class="mt-2 text-center text-2xl font-headline tracking-tight text-on-surface">Welcome back to Neighborly</h2>
        </div>

        <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md relative z-10">
            <div class="bg-surface-container-lowest py-8 px-4 shadow-[0_32px_64px_-4px_rgba(52,50,42,0.05)] sm:rounded-xl sm:px-10 border border-outline-variant/10">
                <form class="space-y-6" @submit.prevent="handleLogin">
                    <div v-if="error" class="bg-error-container text-on-error p-3 rounded-lg text-sm">
                        {{ error }}
                    </div>
                    <div>
                        <label for="email" class="block text-sm font-medium font-label text-on-surface">Email address</label>
                        <div class="mt-1">
                            <input id="email" v-model="email" name="email" type="email" required
                                class="appearance-none block w-full px-3 py-2 border-none bg-surface-container-highest rounded-lg shadow-sm placeholder-on-surface-variant focus:outline-none focus:ring-2 focus:ring-primary focus:bg-surface-lowest transition-all sm:text-sm">
                        </div>
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-medium font-label text-on-surface">Password</label>
                        <div class="mt-1">
                            <input id="password" v-model="password" name="password" type="password" required
                                class="appearance-none block w-full px-3 py-2 border-none bg-surface-container-highest rounded-lg shadow-sm placeholder-on-surface-variant focus:outline-none focus:ring-2 focus:ring-primary focus:bg-surface-lowest transition-all sm:text-sm">
                        </div>
                    </div>

                    <div>
                        <button type="submit" :disabled="loading"
                            class="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-full shadow-sm text-sm font-headline font-bold text-on-primary bg-gradient-to-b from-primary to-primary-dim ring-1 ring-inset ring-white/10 hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all">
                            <span v-if="loading">Signing in...</span>
                            <span v-else>Sign in</span>
                        </button>
                    </div>
                </form>
                
                <div class="mt-6 text-center text-sm font-label">
                    <a href="#/register" class="text-primary hover:text-primary-dim">Don't have an account? Create one</a>
                </div>
            </div>
        </div>
    </div>
    `,
    data() {
        return {
            email: "student@neighborhood.edu", // default pre-fill for ease of use
            password: "password123",
            error: null,
            loading: false
        };
    },
    methods: {
        async handleLogin() {
            this.loading = true;
            this.error = null;
            try {
                const user = await login(this.email, this.password);
                this.$emit("user-updated", user);
                window.location.hash = "#/";
            } catch (err) {
                this.error = err.message;
            } finally {
                this.loading = false;
            }
        }
    }
};