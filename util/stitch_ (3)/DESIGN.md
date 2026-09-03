---
name: Warm Paw Prints
colors:
  surface: '#fff8f5'
  surface-dim: '#e7d7ce'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ea'
  surface-container: '#fbebe2'
  surface-container-high: '#f5e5dc'
  surface-container-highest: '#efdfd7'
  on-surface: '#221a15'
  on-surface-variant: '#4f453c'
  inverse-surface: '#382f29'
  inverse-on-surface: '#feeee5'
  outline: '#81756b'
  outline-variant: '#d3c4b9'
  surface-tint: '#78583a'
  primary: '#442a10'
  on-primary: '#ffffff'
  primary-container: '#5d4024'
  on-primary-container: '#d5ac89'
  inverse-primary: '#e9bf9a'
  secondary: '#864e5a'
  on-secondary: '#ffffff'
  secondary-container: '#feb6c4'
  on-secondary-container: '#7a4450'
  tertiary: '#31302c'
  on-tertiary: '#ffffff'
  tertiary-container: '#474642'
  on-tertiary-container: '#b7b4ae'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcbf'
  primary-fixed-dim: '#e9bf9a'
  on-primary-fixed: '#2c1601'
  on-primary-fixed-variant: '#5e4125'
  secondary-fixed: '#ffd9df'
  secondary-fixed-dim: '#fbb3c1'
  on-secondary-fixed: '#360c19'
  on-secondary-fixed-variant: '#6b3743'
  tertiary-fixed: '#e6e2dc'
  tertiary-fixed-dim: '#c9c6c1'
  on-tertiary-fixed: '#1c1c18'
  on-tertiary-fixed-variant: '#484743'
  background: '#fff8f5'
  on-background: '#221a15'
  surface-variant: '#efdfd7'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1200px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

The brand personality is rooted in the "Safe Haven" archetype—protective, nurturing, and deeply reliable. This design system bridges the gap between a playful pet community and a professional service provider. The goal is to evoke an immediate emotional response of "my pet is in good hands."

The visual style is **Modern-Organic**. It prioritizes soft, tactile interfaces that feel approachable rather than clinical. It avoids sharp corners and harsh contrasts in favor of a "squishy" and comforting aesthetic. By utilizing generous whitespace and a "hand-drawn" precision, the system maintains a boutique, high-end feel while remaining accessible to all pet owners.

## Colors

The palette is derived directly from the warmth of the brand's mascot. 

- **Primary (Bark Brown):** Used for grounding the interface. It is the color of authority and stability, applied to primary typography, navigation icons, and heavy-duty buttons.
- **Secondary (Blossom Pink):** A soft, energetic accent used to highlight "moments of joy," such as active states, call-to-action buttons, and celebratory notifications.
- **Tertiary (Cream Foam):** The base of the entire UI. This warm off-white reduces eye strain and feels more premium and "organic" than pure white.
- **Neutral (Slate Fur):** A desaturated brown-grey used for secondary text, borders, and inactive states to maintain harmony with the primary brown.

## Typography

This system uses **Plus Jakarta Sans** for headlines to provide a friendly, modern, and slightly rounded geometric feel that echoes the "bubbly" nature of a happy dog. For body text, **Be Vietnam Pro** is selected for its exceptional legibility and contemporary, open letterforms that feel warm and inviting.

- **Scale:** Headlines use a tight tracking to feel cohesive, while body text uses a generous line height (1.5x) to ensure readability for users who may be scanning for service details quickly.
- **Color:** Typography should rarely be pure black. Use the Primary Brown for all major headings and the Neutral Slate for body copy to maintain the "warmth" of the brand.

## Layout & Spacing

The layout philosophy is a **Fluid-Fixed Hybrid**. While the grid adapts to screen width, the content container is capped at 1200px on desktop to maintain a boutique, curated feel.

- **Grid:** Use a 12-column grid for desktop and a 4-column grid for mobile.
- **Rhythm:** An 8px base unit drives all spacing. For "Pet Profile" cards or "Product" grids, use a 24px gutter to provide ample breathing room, reflecting the "spaciousness" of a high-end pet hotel.
- **Safe Areas:** On mobile, a 16px horizontal margin is mandatory. On desktop, this expands to 40px to prevent content from touching the edges of the viewport.

## Elevation & Depth

To maintain the soft and trustworthy atmosphere, this design system uses **Tonal Layers** combined with **Ambient Shadows**. 

- **Surface Tiers:** Backgrounds are the Tertiary Cream. Cards and containers use a pure White (#FFFFFF) to pop forward.
- **Shadows:** Shadows must be very soft and "diffused." Use the Primary Brown color at a very low opacity (5-10%) for shadow tints instead of grey. This keeps the depth feeling warm. 
- **Interaction:** Upon hover, elements should not just change color but slightly lift (move -4px on the Y-axis) with an increased shadow spread to simulate a tactile, physical response.

## Shapes

The shape language is **Rounded**. Sharp corners are strictly avoided as they represent "danger" or "edges" in a pet-focused context.

- **Standard Elements:** Buttons, input fields, and small cards use a 0.5rem (8px) radius.
- **Feature Elements:** Large banners and "Daycare Activity" cards use a 1rem (16px) radius to emphasize softness.
- **Iconography:** Use icons with rounded terminals and thick strokes (2px+) to match the weight and friendliness of the typography and logo.

## Components

- **Buttons:** Primary buttons use a solid Bark Brown background with White text. Secondary "soft" buttons use a light version of Blossom Pink (10% opacity) with Pink text. All buttons have a minimum height of 48px to be "finger-friendly."
- **Input Fields:** Use a subtle Slate Fur border (1px). When focused, the border should thicken and change to Blossom Pink, accompanied by a soft pink outer glow.
- **Cards:** Product and Room cards must feature a "floating" style with 16px padding and the 1rem rounded corner. 
- **Chips/Badges:** Used for "Available Now" or "Sale" tags. These should be fully pill-shaped (rounded-full) to look like small treats or toys.
- **Progressive Disclosure:** For the booking process, use a "Steppers" component that uses dog paw icons as markers to keep the experience delightful.
- **Pet Profiles:** Dedicated circular avatars with a 2px Bark Brown border to make user pet photos feel integrated into the design system.