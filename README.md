# وصاية توفيق — Restaurant website

An Arabic-first, right-to-left restaurant landing page built with React, TypeScript and Vite. It uses the supplied restaurant video and menu artwork. Menu records, offers and administrator-authored testimonials connect to Supabase when configured.

## Local development

1. Install Node.js 20.19+ or 22.12+.
2. Run `npm install` and `npm run dev`.
3. Copy `.env.example` to `.env.local` and add the Supabase project URL and public anon/publishable key. The key is safe for browser use only when the included RLS policies are applied. Never put a service-role key in this app.
4. Run `npm run build` for a production build and `npm test` for the component tests.

Without Supabase, the landing page reads its design-review menu from `src/data.ts`; it does not switch to this data if a configured production database fails. Offers and testimonials are intentionally not fabricated. The admin route shows connection instructions until credentials are configured.

## Supabase setup

1. Create a Supabase project. In its SQL editor, run all migrations in order: `supabase/migrations/202610120001_initial_schema.sql`, `supabase/migrations/202610130001_admin_testimonials_and_menu_review.sql`, then `supabase/migrations/202610130002_featured_menu_items.sql`.
2. In Supabase Authentication, create the administrator user with an individual email and strong password. Do not create a shared or default account.
3. Grant that account admin access from the SQL editor by replacing the example email below with the exact email used above:

   ```sql
   insert into public.admin_users (user_id)
   select id from auth.users where email = 'admin@example.com';
   ```

   Confirm one row was inserted. The `admin_users` table has no client insert/update/delete policy, so promotion must happen through this trusted setup step.
4. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` (or the Supabase publishable key) to `.env.local` and restart Vite.
5. Visit `/admin`, sign in, and manage menu items, categories, offers and testimonials. New testimonials are drafts until an administrator publishes them. Uploaded files are limited to JPEG, PNG and WebP up to 5 MB and stored in the public `restaurant-images` bucket. Public images are readable; only administrators can upload or alter files.

The migrations enable RLS on every application table, protect writes using a database-side admin membership check, allow only administrators to create or manage testimonials, and remove anonymous feedback insertion and public access to legacy feedback. Existing feedback rows are retained but are not copied into testimonials. Verify the RLS policies in the Supabase dashboard after applying both migrations. Never expose the Supabase service-role key in frontend variables.

## Current content status

Both supplied menu-page images and the brand/hotline artwork are preserved in `public/menu-images/`. The local design-review catalog contains **86 rows transcribed from the two menu pages**, including visible price and variation data. **26 rows have blurred or uncertain names flagged for manual review**; they remain visible in local review mode with their printed prices and are excluded from public menu reads in Supabase until corrected. No per-dish photographs were supplied, so local cards use replaceable food illustrations; source menu scans remain available for reference. No descriptions, ingredients, hours, offers, ratings or testimonials are invented. The verified hotline is `15801`, and the slogan is `طعم ❤️ حتحبه`.

## Cloudflare Pages deployment

1. Push this project to a GitHub repository you control; check `.gitignore` and ensure `.env.local` is not staged.
2. In Cloudflare Pages, create a project from that repository using build command `npm run build` and output directory `dist`.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as Pages build environment variables, then deploy.
4. Add the deployed `https://<project>.pages.dev` origin to the Supabase Auth site URL and allowed redirect URL settings.
5. Test the deployed public site, admin login, testimonial publication and image upload using the authorized Supabase account. A Pages URL is not available until the project is actually connected and deployed.

Cloudflare's free Pages hosting is the intended target. No repository remote, Supabase project, GitHub authorization or Cloudflare deployment is configured in this workspace yet.
