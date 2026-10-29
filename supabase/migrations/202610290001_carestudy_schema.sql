-- CareStudy student-owned data. Apply via Supabase migrations after the database is healthy.
create extension if not exists pgcrypto;

create table if not exists public.student_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.study_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  lessons_completed integer not null default 0 check (lessons_completed >= 0),
  progress_percent integer not null default 0 check (progress_percent between 0 and 100),
  current_streak integer not null default 0 check (current_streak >= 0),
  last_study_date date,
  updated_at timestamptz not null default now()
);
create table if not exists public.study_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_key text not null,
  task_date date not null default current_date,
  completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(user_id, task_key, task_date)
);
create table if not exists public.student_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Untitled note' check (char_length(title) <= 180),
  body text not null default '' check (char_length(body) <= 50000),
  subject_slug text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_slug text not null,
  score integer not null check (score between 0 and 100),
  answers jsonb not null default '[]'::jsonb,
  attempted_at timestamptz not null default now()
);
create index if not exists study_tasks_user_date_idx on public.study_tasks(user_id, task_date desc);
create index if not exists student_notes_user_updated_idx on public.student_notes(user_id, updated_at desc);
create index if not exists quiz_attempts_user_date_idx on public.quiz_attempts(user_id, attempted_at desc);

alter table public.student_profiles enable row level security;
alter table public.study_progress enable row level security;
alter table public.study_tasks enable row level security;
alter table public.student_notes enable row level security;
alter table public.quiz_attempts enable row level security;
drop policy if exists "Students manage their own profile" on public.student_profiles;
create policy "Students manage their own profile" on public.student_profiles for all to authenticated using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "Students manage their own progress" on public.study_progress;
create policy "Students manage their own progress" on public.study_progress for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Students manage their own tasks" on public.study_tasks;
create policy "Students manage their own tasks" on public.study_tasks for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Students manage their own notes" on public.student_notes;
create policy "Students manage their own notes" on public.student_notes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Students manage their own quiz attempts" on public.quiz_attempts;
create policy "Students manage their own quiz attempts" on public.quiz_attempts for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
grant select, insert, update, delete on public.student_profiles, public.study_progress, public.study_tasks, public.student_notes, public.quiz_attempts to authenticated;

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path = '' as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists student_profiles_updated_at on public.student_profiles;
create trigger student_profiles_updated_at before update on public.student_profiles for each row execute function public.set_updated_at();
drop trigger if exists study_progress_updated_at on public.study_progress;
create trigger study_progress_updated_at before update on public.study_progress for each row execute function public.set_updated_at();
drop trigger if exists student_notes_updated_at on public.student_notes;
create trigger student_notes_updated_at before update on public.student_notes for each row execute function public.set_updated_at();

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$ begin
  insert into public.student_profiles (id, display_name) values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1))) on conflict (id) do nothing;
  insert into public.study_progress (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
