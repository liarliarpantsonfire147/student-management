-- Run this file if schema.sql was already run previously.
-- It adds the fields/functions required by the current student-management UI.

alter table public.profiles add column if not exists email text;

create or replace function public.add_student_to_class(target_class uuid, student_name text, student_email text default null, student_year text default null)
returns public.students language plpgsql security definer set search_path = public as $$
declare created_student public.students;
begin
  if not public.teaches_class(target_class) then raise exception 'You are not assigned to this class'; end if;
  if nullif(trim(student_name), '') is null then raise exception 'Student name is required'; end if;
  insert into public.students(full_name, email, year_group)
  values (trim(student_name), nullif(trim(student_email), ''), nullif(trim(student_year), ''))
  returning * into created_student;
  insert into public.enrollments(class_id, student_id) values (target_class, created_student.id);
  return created_student;
end; $$;
revoke all on function public.add_student_to_class(uuid, text, text, text) from public;
grant execute on function public.add_student_to_class(uuid, text, text, text) to authenticated;

create or replace function public.available_students_for_class(target_class uuid)
returns setof public.students language plpgsql security definer set search_path = public as $$
begin
  if not public.teaches_class(target_class) then raise exception 'You are not assigned to this class'; end if;
  return query select s.* from public.students s where not exists (
    select 1 from public.enrollments e where e.class_id = target_class and e.student_id = s.id
  ) order by s.full_name;
end; $$;
revoke all on function public.available_students_for_class(uuid) from public;
grant execute on function public.available_students_for_class(uuid) to authenticated;

create or replace function public.enroll_existing_student(target_class uuid, target_student uuid)
returns public.students language plpgsql security definer set search_path = public as $$
declare enrolled_student public.students;
begin
  if not public.teaches_class(target_class) then raise exception 'You are not assigned to this class'; end if;
  insert into public.enrollments(class_id, student_id) values (target_class, target_student)
  on conflict (class_id, student_id) do nothing;
  select * into enrolled_student from public.students where id = target_student;
  return enrolled_student;
end; $$;
revoke all on function public.enroll_existing_student(uuid, uuid) from public;
grant execute on function public.enroll_existing_student(uuid, uuid) to authenticated;

create or replace function public.grade_points(value text)
returns numeric language sql immutable as $$
  select case upper(trim(coalesce(value, '')))
    when 'A+' then 4.0 when 'A' then 4.0 when 'A-' then 3.7
    when 'B+' then 3.3 when 'B' then 3.0 when 'B-' then 2.7
    when 'C+' then 2.3 when 'C' then 2.0 when 'C-' then 1.7
    when 'D' then 1.0 when 'E' then 0.5 else null end;
$$;

create or replace function public.get_class_roster(target_class uuid)
returns table(student_id uuid, full_name text, email text, year_group text, grade text, feedback text, updated_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not public.teaches_class(target_class) then raise exception 'You do not have access to this class'; end if;
  return query select s.id, s.full_name, s.email, s.year_group, g.grade, g.feedback, g.updated_at
  from public.enrollments e join public.students s on s.id=e.student_id
  left join public.grades g on g.class_id=e.class_id and g.student_id=e.student_id
  where e.class_id=target_class order by s.full_name;
end; $$;
revoke all on function public.get_class_roster(uuid) from public;
grant execute on function public.get_class_roster(uuid) to authenticated;

create or replace function public.get_class_metrics()
returns table(class_id uuid, class_name text, year_group text, student_count bigint, graded_count bigint, average_gpa numeric)
language sql security definer set search_path = public as $$
  select c.id, c.name, c.year_group, count(distinct e.student_id), count(g.id), round(avg(public.grade_points(g.grade)), 2)
  from public.classes c
  left join public.enrollments e on e.class_id=c.id
  left join public.grades g on g.class_id=e.class_id and g.student_id=e.student_id
  where public.teaches_class(c.id)
  group by c.id, c.name, c.year_group order by c.name;
$$;
revoke all on function public.get_class_metrics() from public;
grant execute on function public.get_class_metrics() to authenticated;

create or replace function public.get_admin_student_directory()
returns table(student_id uuid, full_name text, email text, year_group text, class_count bigint, gpa numeric)
language sql security definer set search_path = public as $$
  select s.id, s.full_name, s.email, s.year_group, count(distinct e.class_id), round(avg(public.grade_points(g.grade)), 2)
  from public.students s
  left join public.enrollments e on e.student_id=s.id
  left join public.grades g on g.student_id=s.id and g.class_id=e.class_id
  where public.is_admin()
  group by s.id, s.full_name, s.email, s.year_group order by s.full_name;
$$;
revoke all on function public.get_admin_student_directory() from public;
grant execute on function public.get_admin_student_directory() to authenticated;
