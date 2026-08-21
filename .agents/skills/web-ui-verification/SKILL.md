---
name: web-ui-verification
description: Verifies web UI claims hands-on with Playwright headless screenshots, scrolling stepwise to trigger IntersectionObserver-gated reveals; load before claiming any web page renders, animates, or works.
license: Proprietary
---

# Web UI verification

Binding rule (railway): **"UI claims verified hands-on … Playwright headless screenshots for web."** A clean build is not visual proof — you must look at rendered output.

## Procedure

1. **Run the real dev server** on a dedicated port so it doesn't collide with anything the user has open — railway convention: `npx next dev --port 3111`. For Vite projects use the project's own dev command.
2. **Capture with Playwright headless screenshots**, not full-page dumps alone:
   - **"Full-page captures miss IO-gated reveals — screenshot stepwise while scrolling."** Content behind `IntersectionObserver` (fade-ins, counters, lazy sections) only mounts/animates once scrolled into view, so a single `fullPage: true` shot shows it un-triggered or blank.
   - Scroll in viewport-height steps, waiting briefly after each step for reveal animations to fire, and screenshot each step. Assemble the sequence to judge the whole page.
3. **Check the console, not just pixels.** website-new quality gate: "verify in a real browser with 0 console errors." Collect `page.on('console')` / `page.on('pageerror')` during the run; any error fails the verification.
4. **Verify at the states that matter:** hover states (website-new: portfolio cards fill with their sector colour, black type), reduced motion (motion must be off under `prefers-reduced-motion` or a coarse pointer), and both content-present and empty states.
5. **Build gate still applies:** `next build` + eslint clean (railway) / `npm run build` clean including prerender + Zod content-schema validation (website-new). Screenshots verify appearance; the build verifies integrity. Both are required.
6. **Known layout traps to check visually** (railway):
   - maplibre CSS forces `position:relative` on map containers — wrap for absolute positioning.
   - Use `overflow-x-clip` (never `-hidden`) on the landing root or sticky bars break; padding not margin on the root (margin-collapse).
7. **Verify links behave, not just render.** Internal links must be router links, "never raw `<a href="/...">` in components" (website-new) — a full page reload on click is a visual verification failure even if the destination loads.
8. **Report with evidence:** name the URL/route, viewport, and scroll position of each screenshot, and state explicitly which reveals you saw fire. If you couldn't render it, say the claim is unverified.
9. **Respect design sign-off boundaries:** Yash reviews visual changes locally before more work — "when he says 'wants to talk first', stop iterating on that surface." Verified ≠ approved.

## For a shareable review URL

10. To give Yash a review URL without merging (website-new): deploy a Cloudflare Pages branch preview with the local wrangler login (see `topics/cloudflare-pages-branch-previews.md`). Warning: "previews share production's D1, so forms submitted there hit the real inbox" — never submit test form data on a branch preview.
11. Note that "PRs get no preview URL — deploy.yml triggers on push to `main` only", and merge to `main` IS the deploy. Don't merge just to see the result.

## Hard stops

- Never claim a web UI works from code or build output alone — screenshot it.
- Never rely on a single full-page screenshot for a page with scroll-triggered reveals.
- Never sign off with console errors present.
