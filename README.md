# Margin — landing page

A portfolio concept: a landing page for **Margin**, a tool that gathers scattered client feedback (email, WhatsApp, voice notes) into one thread pinned to the work.

- Single file: `index.html` (no build step)
- Fonts: Fraunces, Inter, Caveat (Google Fonts)
- Palette: `#efe6d5` · `#9dbeb7` · `#e73213`
- Includes an interactive demo: click the mock design to drop a feedback pin.

Open `index.html` in a browser to view it.

## Deploying
Hosted on GitHub Pages (static). To collect real waitlist signups, set `WAITLIST_ENDPOINT` near the bottom of `index.html` (e.g. a Formspree form URL).

The testimonials and stats are sample copy for this concept.

## The app (MVP)
`app.html` (freelancer dashboard) and `review.html` (client review page) are a working prototype that runs entirely on GitHub Pages plus a free [Supabase](https://supabase.com) project.

**Setup**
1. Create a free Supabase project.
2. In **SQL Editor**, paste and run `supabase.sql`. This creates the tables, access rules and the file bucket.
3. In **Authentication → URL Configuration**, set the Site URL to your Pages URL (e.g. `https://khingcode.github.io/margin-website/`) and add it to Redirect URLs.
4. In **Project Settings → API**, copy the Project URL and the `anon` public key into `config.js`. Never put the `service_role` key anywhere in this repo.

**How it works:** freelancers sign in with an emailed link, upload an image or PDF (max 10 MB) and copy a client link. Clients need no account. They open the link, click the work to pin notes, and can approve the version. Clients only reach a project through its secret link, via the functions in `supabase.sql`.

**Known limits:** uploaded files sit at unguessable public URLs (not strictly private); no spam/rate limiting yet; no email notifications; no payments.
