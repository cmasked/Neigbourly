# Design System Document: The Curated Hearth

## 1. Overview & Creative North Star
This design system is built upon the **Creative North Star: "The Curated Hearth."** 

The objective is to transcend the transactional nature of rental platforms, moving instead toward a digital experience that feels like browsing a high-end interior design editorial. We reject the rigid, "boxed-in" layout of traditional marketplaces. Instead, we embrace the "Shared Home Interface"—a philosophy where the UI mimics the physical world through "shelving" units, soft golden-hour lighting, and intentional asymmetry. 

By utilizing overlapping elements, expansive white space, and a sophisticated typography scale, the design system creates a sense of calm, trust, and neighborly invitation. It is not a grid; it is a space.

---

## 2. Colors & Atmospheric Depth
Our palette is rooted in the warmth of a late afternoon. We use light not just as a visual aid, but as a structural material.

### Palette Strategy
*   **Foundation:** The `background` (#fef9f1) and `surface` (#fef9f1) act as our "warm plaster walls." 
*   **The Primary Signature:** `primary` (#5a46d6) and `primary-container` (#c1b9ff) provide the "Muted Lavender" soul of the brand. These should be used for moments of action and curation.
*   **The Golden Accent:** `tertiary-container` (#fbecd8) and `on-tertiary-fixed` (#4e4537) mimic the beige wood and matte shelf elements, grounding the ethereal lavender.

### The "No-Line" Rule
**Strict Prohibition:** Designers are forbidden from using 1px solid borders to define sections or cards. 
Boundaries must be created through:
1.  **Tonal Shifts:** Placing a `surface-container-lowest` card on top of a `surface-container-low` background.
2.  **Soft Light:** Using shadows to define edges rather than ink.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
*   **Base:** `surface` (The Wall)
*   **Sectioning:** `surface-container-low` (The Recess)
*   **Interaction/Cards:** `surface-container-lowest` (The Floating Sheet)
*   **Pop-overs/Modals:** `surface-bright` with Glassmorphism.

### The "Glass & Gradient" Rule
To ensure a premium feel, main CTAs and hero headers should utilize a subtle linear gradient transitioning from `primary` to `primary-dim`. For floating navigation or over-image labels, use **Glassmorphism**: 
*   **Fill:** `surface` at 70% opacity.
*   **Blur:** 12px–20px backdrop-filter.
*   **Effect:** This allows the "golden hour" background colors to bleed through, integrating the UI into the atmosphere.

---

## 3. Typography: Editorial Authority
The type system uses a dual-font approach to balance modern friendliness with professional curation.

*   **Display & Headlines (Plus Jakarta Sans):** These are our "statement pieces." Use `display-lg` and `headline-lg` with generous tracking and intentional asymmetry (e.g., left-aligned headers with wide right margins) to create a sense of breath.
*   **Body & Titles (Plus Jakarta Sans):** The rounded nature of Jakarta Sans ensures the "friendly neighbor" vibe remains intact even in dense information.
*   **Labels (Manrope):** We switch to Manrope for `label-md` and `label-sm`. The slightly more technical, architectural feel of Manrope provides a "caption" quality to metadata, making it feel like a catalog entry.

---

## 4. Elevation & Depth: Tonal Layering
We do not use elevation to "pop" elements; we use it to "lift" them gently.

### The Layering Principle
Depth is achieved by "stacking" the `surface-container` tiers. A `surface-container-lowest` object placed on a `surface-container-highest` background creates a natural, soft contrast that mimics a paper sheet on a wooden desk.

### Ambient Shadows
Where floating depth is required (e.g., a primary action card), use "Golden Hour" shadows:
*   **Color:** A tinted version of `on-surface` (#34322a) at 5% opacity.
*   **Blur:** 32px to 64px.
*   **Spread:** -4px (to keep the shadow tucked and organic).

### The "Ghost Border" Fallback
If a border is required for accessibility (e.g., in high-contrast modes), use the **Ghost Border**:
*   **Token:** `outline-variant`
*   **Opacity:** 15% maximum.
*   **Weight:** 1px.

---

## 5. Components
Primitive components must feel like tactile objects, not digital buttons.

*   **Buttons:**
    *   **Primary:** A gradient-filled pill (Rounded `full`) using `primary` to `primary-dim`. No shadow; use a 2px "inner light" stroke of `on-primary` at 10% opacity.
    *   **Secondary:** `secondary-container` fill with `on-secondary-container` text.
*   **Shelf Cards:**
    *   Cards must use `xl` (1.5rem) roundedness.
    *   **Forbid dividers.** Separate content blocks within cards using `surface-variant` backgrounds or vertical 24px/32px spacing increments.
*   **Shelving Elements:**
    *   Incorporate horizontal "Shelf" lines using the `tertiary-fixed-dim` token. These are not dividers, but stylistic anchors that items "sit" on, mimicking the reference images.
*   **Input Fields:**
    *   Use `surface-container-highest` fills. 
    *   On focus, the background shifts to `surface-lowest` with a soft `primary` glow (8px blur).
*   **Chips:**
    *   Filter chips should feel like small ceramic tokens. Use `tertiary-container` with `md` (0.75rem) roundedness.

---

## 6. Do's and Don'ts

### Do:
*   **Do use asymmetrical margins.** Allow a header to sit further to the left than the body text to create a high-end magazine feel.
*   **Do use "Golden Hour" imagery.** Ensure all photography has warm color temperatures to complement the `#F6F1E9` background.
*   **Do prioritize white space.** If a section feels crowded, increase the `surface` padding rather than adding a divider.

### Don't:
*   **Don't use pure black.** Use `on-surface` (#34322a) for all text to maintain the warm, organic feel.
*   **Don't use hard drop shadows.** If the shadow looks like it was made in 2010, it's too heavy. It should be barely perceptible.
*   **Don't use 90-degree corners.** Everything in a home has a softened edge; the digital interface must follow suit.
*   **Don't use "standard" 12-column grids for everything.** Experiment with offset "shelf" placements where images and text are slightly staggered.

---

*Note to Junior Designers: This system is about "The Breath." If the layout feels tight, let it out. If it feels flat, add a layer, not a line.*