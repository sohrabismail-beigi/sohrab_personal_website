# Sohrab Ismail-Beigi: personal pages

Source for https://sohrabismail-beigi.github.io/sohrab_personal_website/, built by GitHub Pages (Jekyll) from the Markdown files here.

## Editing

- **Home page:** `index.md`
- **Gravity Wars page:** `gravity-wars/index.md`
- **Site title, tagline, and top menu:** `_config.yml`
- **Look and colors:** `assets/css/style.css` and `_layouts/default.html`

You can edit any of these on github.com (click the file, then the pencil icon) and commit. The live site updates a minute or two later.

## Adding a file for download

Put it in `files/` (or next to the page it belongs to), then link to it from a page, for example:

```markdown
[My notes (PDF)](files/my-notes.pdf)
```

## Adding a new page

Create a folder with an `index.md` inside, e.g. `books/index.md`, starting with:

```markdown
---
title: Books
---
```

To put it in the top menu, add it under `nav:` in `_config.yml`.

## Previewing locally (optional)

With Jekyll installed:

```bash
jekyll serve
```

Then open http://127.0.0.1:4000/sohrab_personal_website/
