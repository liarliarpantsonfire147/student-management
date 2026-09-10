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
