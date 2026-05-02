function encodeSvg(svg) {
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

function initialsFromTitle(title) {
    const words = (title || "Item").trim().split(/\s+/).slice(0, 2);
    return words.map((w) => w[0]?.toUpperCase() || "").join("") || "IT";
}

function colorIndex(seed) {
    let hash = 0;
    for (let i = 0; i < seed.length; i += 1) {
        hash = (hash * 31 + seed.charCodeAt(i)) >>> 0;
    }
    return hash;
}

export function buildItemPlaceholder(item) {
    const title = item?.title || "Neighborhood Item";
    const category = item?.category || "Neighborly";
    const initials = initialsFromTitle(title);
    const seed = `${title}|${category}`;

    const palettes = [
        ["#c1b9ff", "#5a46d6"],
        ["#fbecd8", "#685e4e"],
        ["#e6deff", "#6153a2"],
        ["#d8f3dc", "#2d6a4f"],
        ["#ffe8d6", "#bc6c25"],
    ];
    const pair = palettes[colorIndex(seed) % palettes.length];

    const safeTitle = String(title).replace(/[&<>"']/g, "");
    const safeCategory = String(category).replace(/[&<>"']/g, "");

    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800" role="img" aria-label="${safeTitle}">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0%" stop-color="${pair[0]}"/>
<stop offset="100%" stop-color="${pair[1]}"/>
</linearGradient>
</defs>
<rect width="800" height="800" fill="url(#g)"/>
<circle cx="680" cy="140" r="120" fill="#ffffff22"/>
<circle cx="120" cy="700" r="160" fill="#ffffff1a"/>
<text x="400" y="380" text-anchor="middle" font-size="180" font-family="'Plus Jakarta Sans', Arial, sans-serif" font-weight="800" fill="#ffffff">${initials}</text>
<text x="400" y="470" text-anchor="middle" font-size="34" font-family="Manrope, Arial, sans-serif" fill="#ffffffdd">${safeCategory}</text>
<text x="400" y="525" text-anchor="middle" font-size="26" font-family="Manrope, Arial, sans-serif" fill="#ffffffcc">${safeTitle}</text>
</svg>`;

    return encodeSvg(svg);
}

export function resolveItemImage(item) {
    if (item?.image_urls?.length && item.image_urls[0]) {
        return item.image_urls[0];
    }
    return buildItemPlaceholder(item);
}