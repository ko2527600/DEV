-- One-time setup in Supabase SQL editor
-- Creates a SECURITY DEFINER function to insert into public.books bypassing RLS

create or replace function public.create_book_basic(
  p_id uuid default gen_random_uuid(),
  p_title text,
  p_author text,
  p_category text default 'life',
  p_subject_id uuid default null,
  p_isbn text default null,
  p_description text default null,
  p_cover_image_url text default null,
  p_book_file_url text,
  p_book_format text default 'pdf',
  p_file_size integer default 0,
  p_total_copies integer default 1,
  p_available_copies integer default 1,
  p_location text default 'Digital Library'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := coalesce(p_id, gen_random_uuid());
begin
  insert into public.books (
    id, title, author, category, subject_id, isbn, description,
    cover_image_url, book_file_url, book_format, file_size,
    total_copies, available_copies, location, created_at, updated_at
  ) values (
    v_id, p_title, p_author, p_category, p_subject_id, p_isbn, p_description,
    p_cover_image_url, p_book_file_url, p_book_format, coalesce(p_file_size, 0),
    coalesce(p_total_copies, 1), coalesce(p_available_copies, 1), coalesce(p_location, 'Digital Library'),
    now(), now()
  ) on conflict (id) do nothing;

  return v_id;
end;
$$;

revoke all on function public.create_book_basic(uuid, text, text, text, uuid, text, text, text, text, text, integer, integer, integer, text) from public;
grant execute on function public.create_book_basic(uuid, text, text, text, uuid, text, text, text, text, text, integer, integer, integer, text) to authenticated;


