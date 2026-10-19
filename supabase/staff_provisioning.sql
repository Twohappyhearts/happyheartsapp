-- STAFF PROVISIONING (manual, trusted - NOT a migration, do not run automatically)
-- Run in the Supabase Dashboard > SQL Editor (runs as postgres/service role).
--
-- Step 1: Create the staff member's own login in Dashboard > Authentication > Users
--         > "Add user" (email + strong unique password, tick "Auto Confirm User").
--         Each staff member MUST have an individual account. Never share one.
--
-- Step 2: Grant the role by email. Replace the address below.
--         The signup trigger creates a patient role/profile first; this upgrades it.

UPDATE public.account_roles
SET role = 'staff', is_active = true
WHERE user_id = (SELECT id FROM auth.users WHERE lower(email) = lower('staff1@example.org'));

-- Verify
SELECT u.email, ar.role, ar.is_active
FROM public.account_roles ar JOIN auth.users u ON u.id = ar.user_id
WHERE ar.role IN ('staff', 'admin');

-- Deactivate a staff member (access revoked immediately, history preserved):
-- UPDATE public.account_roles SET is_active = false
-- WHERE user_id = (SELECT id FROM auth.users WHERE lower(email) = lower('staff1@example.org'));
--
-- Staff replies are plain INSERTs by the authenticated staff user; sender_id,
-- sender_role='team' and created_at are assigned by the database trigger:
--   insert into public.chat_messages (conversation_id, content) values ('<conversation uuid>', 'Hello');
