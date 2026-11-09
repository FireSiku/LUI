# LUI Guide

Static files for the LUI Guide. No build step or framework is required.

## Structure

- `index.html` — guide content and page structure
- `style.css` — theme, layout and responsive styles
- `script.js` — table-of-contents state and back-to-top button
- `assets/` — screenshots

## Editing

### Colors
The theme variables are at the top of `style.css`. Change those first; component styles reuse them.

### Text and sections
Edit `index.html`. Each guide chapter is a `<section id="...">`. The table-of-contents links use the same IDs.

### Screenshots
Replace the matching file in `assets/`, or update its `src` in `index.html`. Keep useful `alt` text.

Screenshots also link to their original-size asset. Update both the image source and its link when changing a filename. Keep the image's width and height accurate, and cap its displayed width at the original pixel width so small captures are not stretched. The added v2611 captures use lossless WebP.

### Layout
Desktop layout lives under **Page layout and table of contents** in `style.css`. Responsive rules are at the bottom.

## GitHub Pages
Publish from **Settings → Pages → Deploy from a branch**, using the `master` branch and `/docs` folder. `index.html`, `style.min.css`, `script.min.js` and `assets/` must stay together. After a successful deployment, the guide is available at https://firesiku.github.io/LUI/ unless a custom domain is configured.
