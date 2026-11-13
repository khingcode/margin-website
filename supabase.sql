-- Margin MVP schema. Paste this whole file into Supabase → SQL Editor → Run.
create extension if not exists pgcrypto;

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  file_path text not null,
  file_type text not null check (file_type in ('image','pdf')),
  share_token uuid not null unique default gen_random_uuid(),
  rounds_total int not null default 3,
  rounds_used int not null default 1,
  status text not null default 'open' check (status in ('open','approved')),
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  page int not null default 1,
  x numeric not null check (x between 0 and 100),
  y numeric not null check (y between 0 and 100),
  author text not null check (char_length(author) between 1 and 60),
  body text not null check (char_length(body) between 1 and 1000),
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists comments_project_idx on comments(project_id, created_at);

alter table projects enable row level security;
alter table comments enable row level security;

-- Owners manage their own projects and the comments on them.
create policy "owner all projects" on projects for all to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());
create policy "owner read comments" on comments for select to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.owner = auth.uid()));
create policy "owner update comments" on comments for update to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.owner = auth.uid()));
create policy "owner delete comments" on comments for delete to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.owner = auth.uid()));

-- Clients have no accounts: they reach a project only through its secret share token,
-- via these functions (the tables themselves stay closed to anonymous users).
create or replace function get_project_by_token(t uuid) returns json
language sql security definer set search_path = public as $$
  select json_build_object('id',id,'name',name,'file_path',file_path,'file_type',file_type,
    'rounds_total',rounds_total,'rounds_used',rounds_used,'status',status,
    'approved_by',approved_by,'approved_at',approved_at,'is_owner',(owner = auth.uid()))
  from projects where share_token = t;
$$;

create or replace function list_comments_by_token(t uuid)
returns table(id uuid, page int, x numeric, y numeric, author text, body text, resolved boolean, created_at timestamptz)
language sql security definer set search_path = public as $$
  select c.id,c.page,c.x,c.y,c.author,c.body,c.resolved,c.created_at
  from comments c join projects p on p.id = c.project_id
  where p.share_token = t order by c.created_at;
$$;

create or replace function add_comment_by_token(t uuid, p_page int, p_x numeric, p_y numeric, p_author text, p_body text)
returns void language plpgsql security definer set search_path = public as $$
declare pid uuid;
begin
  select id into pid from projects where share_token = t and status = 'open';
  if pid is null then raise exception 'project not open'; end if;
  if (select count(*) from comments where project_id = pid) >= 500 then raise exception 'comment limit reached'; end if;
  insert into comments(project_id,page,x,y,author,body)
  values (pid, greatest(p_page,1), p_x, p_y, left(trim(p_author),60), left(trim(p_body),1000));
end $$;

create or replace function approve_by_token(t uuid, p_name text) returns void
language sql security definer set search_path = public as $$
  update projects set status='approved', approved_by=left(trim(p_name),60), approved_at=now()
  where share_token = t and status = 'open' and char_length(trim(p_name)) > 0;
$$;

grant execute on function get_project_by_token(uuid), list_comments_by_token(uuid),
  add_comment_by_token(uuid,int,numeric,numeric,text,text), approve_by_token(uuid,text) to anon, authenticated;

-- File storage: public-read bucket (files live at unguessable paths), 10 MB cap, images + PDF only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('files','files',true,10485760, array['image/png','image/jpeg','image/webp','image/gif','application/pdf'])
on conflict (id) do nothing;
create policy "owners upload to own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "owners delete own files" on storage.objects for delete to authenticated
  using (bucket_id = 'files' and (storage.foldername(name))[1] = auth.uid()::text);
