const API_URL = "http://localhost:8000/api/v1";

export async function fetchAPI(endpoint, options = {}) {
    const token = localStorage.getItem("accessToken");
    
    const headers = {
        "Content-Type": "application/json",
        ...options.headers,
    };
    
    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    try {
        let response = await fetch(`${API_URL}${endpoint}`, {
            ...options,
            headers,
        });

        // Handle 401 Unauthorized (attempt refresh or logout)
        if (response.status === 401) {
            localStorage.removeItem("accessToken");
            // Reload to clear state if unauthorized
            if (!endpoint.includes("/auth/login") && !endpoint.includes("/auth/me")) {
                window.location.hash = "#/login";
            }
        }

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.detail || err.message || `An error occurred: ${response.statusText}`);
        }

        if (response.status === 204) return null;
        return await response.json();
    } catch (error) {
        console.error("API Error:", error);
        throw error;
    }
}

// ─── AUTHENTICATION ──────────────────────────────────────────────

export async function login(email, password, communityId = "c1000000-0000-0000-0000-000000000001") {
    const response = await fetch(`${API_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, community_id: communityId }),
    });
    if (!response.ok) {
        const err = await response.json().catch(() => ({}));
        throw new Error(err.detail || "Login failed");
    }
    const data = await response.json();
    if (data.access_token) {
        localStorage.setItem("accessToken", data.access_token);
        localStorage.setItem("refreshToken", data.refresh_token);
        return await getCurrentUser();
    }
}

export async function register(userData) {
    return await fetchAPI("/auth/register", {
        method: "POST",
        body: JSON.stringify(userData),
    });
}

export async function getCurrentUser() {
    return await fetchAPI("/auth/me");
}

export function logout() {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    window.location.hash = "#/login";
}

// ─── ITEMS ───────────────────────────────────────────────────────

export async function getItems(skip = 0, limit = 50, category = "") {
    let url = `/items?skip=${skip}&limit=${limit}`;
    if (category) url += `&category=${category}`;
    return await fetchAPI(url);
}

export async function getItem(id) {
    return await fetchAPI(`/items/${id}`);
}

export async function createItem(itemData) {
    return await fetchAPI("/items", {
        method: "POST",
        body: JSON.stringify(itemData),
    });
}

export async function deleteItem(id) {
    return await fetchAPI(`/items/${id}`, { method: "DELETE" });
}

// ─── REQUESTS & TRANSACTIONS ─────────────────────────────────────

export async function getRentalRequests() {
    return await fetchAPI("/rental-requests/incoming");
}

export async function getIncomingRentalRequests() {
    return await fetchAPI("/rental-requests/incoming");
}

export async function createRentalRequest(data) {
    return await fetchAPI("/rental-requests", {
        method: "POST",
        body: JSON.stringify(data),
    });
}

export async function acceptRentalRequest(id) {
    return await fetchAPI(`/rental-requests/${id}/accept`, { method: "PATCH" });
}

export async function rejectRentalRequest(id) {
    return await fetchAPI(`/rental-requests/${id}/reject`, { method: "PATCH" });
}

export async function confirmTransaction(requestId) {
    return await fetchAPI(`/transactions/confirm`, {
        method: "POST",
        body: JSON.stringify({
            rental_request_id: requestId,
            idempotency_key: `manual:${requestId}`,
        }),
    });
}

export async function getTransactions() {
    return await fetchAPI("/transactions");
}

export async function advanceTransactionStatus(id, newStatus) {
    return await fetchAPI(`/transactions/${id}/status`, {
        method: "PATCH",
        body: JSON.stringify({ status: newStatus }),
    });
}

// â”€â”€â”€ RATINGS & DISPUTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

export async function createReview(data) {
    return await fetchAPI("/reviews", {
        method: "POST",
        body: JSON.stringify(data),
    });
}

export async function createDispute(data) {
    return await fetchAPI("/disputes", {
        method: "POST",
        body: JSON.stringify(data),
    });
}

export async function getUserReviews(userId) {
    return await fetchAPI(`/reviews/user/${userId}`);
}
