-- Run in Supabase SQL Editor. Create the first auth user in Dashboard or with
-- the server's POST /api/users route, then replace the email below if needed.
create type public.user_role as enum ('admin', 'teacher');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text,
  role public.user_role not null default 'teacher',
  created_at timestamptz not null default now()
);
alter table public.profiles add column if not exists email text;
create table public.classes (
  id uuid primary key default gen_random_uuid(), name text not null,
  year_group text not null, room text, created_at timestamptz not null default now()
);
create table public.class_teachers (
  class_id uuid references public.classes(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete cascade,
  primary key (class_id, teacher_id)
);
create table public.students (
  id uuid primary key default gen_random_uuid(), full_name text not null,
  email text, year_group text, created_at timestamptz not null default now()
);
create table public.enrollments (
  class_id uuid references public.classes(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  primary key (class_id, student_id)
);
create table public.grades (
  id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  grade text, feedback text, updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(), unique(class_id, student_id)
);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin'); $$;
create or replace function public.teaches_class(target uuid) returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists(select 1 from public.class_teachers where class_id = target and teacher_id = auth.uid()); $$;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_teachers enable row level security;
alter table public.students enable row level security;
alter table public.enrollments enable row level security;
alter table public.grades enable row level security;
create policy "staff can read profiles" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "admins manage profiles" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "staff read assigned classes" on public.classes for select to authenticated using (public.teaches_class(id));
create policy "admins manage classes" on public.classes for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "staff read assignments" on public.class_teachers for select to authenticated using (teacher_id=auth.uid() or public.is_admin());
create policy "admins manage assignments" on public.class_teachers for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "staff read assigned students" on public.students for select to authenticated using (exists(select 1 from public.enrollments e where e.student_id=id and public.teaches_class(e.class_id)));
create policy "admins manage students" on public.students for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "staff read enrollments" on public.enrollments for select to authenticated using (public.teaches_class(class_id));
create policy "admins manage enrollments" on public.enrollments for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "staff manage assigned grades" on public.grades for all to authenticated using (public.teaches_class(class_id)) with check (public.teaches_class(class_id));

-- Teachers can add a student only through this scoped function. It creates the
-- student and enrollment atomically, and checks the teacher's class assignment.
create or replace function public.add_student_to_class(target_class uuid, student_name text, student_email text default null, student_year text default null)
returns public.students
language plpgsql security definer set search_path = public
as $$
declare created_student public.students;
begin
  if not public.teaches_class(target_class) then
    raise exception 'You are not assigned to this class';
  end if;
  if nullif(trim(student_name), '') is null then
    raise exception 'Student name is required';
  end if;
  insert into public.students(full_name, email, year_group)
  values (trim(student_name), nullif(trim(student_email), ''), nullif(trim(student_year), ''))
  returning * into created_student;
  insert into public.enrollments(class_id, student_id) values (target_class, created_student.id);
  return created_student;
end;
$$;
revoke all on function public.add_student_to_class(uuid, text, text, text) from public;
grant execute on function public.add_student_to_class(uuid, text, text, text) to authenticated;

-- Initial admin: create this user first with POST /api/users (service role), then run:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='admin@school.edu');
