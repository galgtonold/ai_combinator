# Factorio Button Implementation

This directory contains supporting assets for the button implementation, but we're now using a better approach with border-image.

## Current Implementation

We're now using:

- `button.png` - A dedicated button image that's designed for 9-slice scaling with CSS border-image

This image is being used with the CSS border-image property to achieve proper 9-slice scaling:

```css
border: 8px solid transparent;
border-image-source: url('/graphics/button.png');
border-image-slice: 8 8 8 8;
border-image-width: 8px;
border-image-repeat: stretch;
```

## How Border-Image 9-Slice Works

The border-image-slice property divides the image into 9 regions:
- 4 corners
- 4 edges
- 1 middle region

When you specify `border-image-slice: 8 8 8 8`:
1. The top 8px of the image become the top edge
2. The right 8px become the right edge
3. The bottom 8px become the bottom edge
4. The left 8px become the left edge
5. The 4 intersections of these regions become the corners
6. The remaining center portion is either shown or discarded (use 'fill' to show)

This allows the button to scale to any size while maintaining the proper corner appearance.
