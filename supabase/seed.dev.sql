-- DEVELOPMENT ONLY. Run supabase/schema.sql first.
-- This creates 50 fictional students, 3 classes, and enrollments for testing.

insert into public.students (full_name, email, year_group)
select * from (values
  ('Amina Yusuf','student01@school.test','Year 7'),
  ('Ben Carter','student02@school.test','Year 7'),
  ('Chiamaka Eze','student03@school.test','Year 7'),
  ('Daniel Mensah','student04@school.test','Year 7'),
  ('Elena Rossi','student05@school.test','Year 7'),
  ('Farouk Bello','student06@school.test','Year 7'),
  ('Grace Williams','student07@school.test','Year 7'),
  ('Hassan Ibrahim','student08@school.test','Year 7'),
  ('Ivy Thompson','student09@school.test','Year 7'),
  ('James Okoro','student10@school.test','Year 7'),
  ('Kemi Adeyemi','student11@school.test','Year 8'),
  ('Liam Murphy','student12@school.test','Year 8'),
  ('Maya Johnson','student13@school.test','Year 8'),
  ('Nadia Khan','student14@school.test','Year 8'),
  ('Owen Taylor','student15@school.test','Year 8'),
  ('Priya Shah','student16@school.test','Year 8'),
  ('Quinn Anderson','student17@school.test','Year 8'),
  ('Rafael Silva','student18@school.test','Year 8'),
  ('Sara Ibrahim','student19@school.test','Year 8'),
  ('Theo Brown','student20@school.test','Year 8'),
  ('Ada Nwosu','student21@school.test','Year 9'),
  ('Bola Akinyemi','student22@school.test','Year 9'),
  ('Clara Evans','student23@school.test','Year 9'),
  ('Dayo Fashola','student24@school.test','Year 9'),
  ('Eva Martin','student25@school.test','Year 9'),
  ('Felix Green','student26@school.test','Year 9'),
  ('Halima Sani','student27@school.test','Year 9'),
  ('Isaac Lewis','student28@school.test','Year 9'),
  ('Jade Wilson','student29@school.test','Year 9'),
  ('Kofi Boateng','student30@school.test','Year 9'),
  ('Lara Smith','student31@school.test','Year 10'),
  ('Michael Adekunle','student32@school.test','Year 10'),
  ('Nneka Obi','student33@school.test','Year 10'),
  ('Oscar Wright','student34@school.test','Year 10'),
  ('Penny Clarke','student35@school.test','Year 10'),
  ('Rahim Musa','student36@school.test','Year 10'),
  ('Sofia Garcia','student37@school.test','Year 10'),
  ('Tunde Balogun','student38@school.test','Year 10'),
  ('Uma Patel','student39@school.test','Year 10'),
  ('Victor King','student40@school.test','Year 10'),
  ('Wale Adebayo','student41@school.test','Year 11'),
  ('Xara Collins','student42@school.test','Year 11'),
  ('Yemi Lawal','student43@school.test','Year 11'),
  ('Zainab Abdullahi','student44@school.test','Year 11'),
  ('Aaron Hughes','student45@school.test','Year 11'),
  ('Bianca Costa','student46@school.test','Year 11'),
  ('Chidi Nnamdi','student47@school.test','Year 11'),
  ('Daisy Cooper','student48@school.test','Year 11'),
  ('Emeka Udo','student49@school.test','Year 11'),
  ('Fatima Sule','student50@school.test','Year 11')
) as seed(full_name, email, year_group)
where not exists (select 1 from public.students s where s.email = seed.email);

insert into public.classes (id, name, year_group, room)
values
  ('11111111-1111-4111-8111-111111111111','Mathematics · Year 7','Year 7','Room 101'),
  ('22222222-2222-4222-8222-222222222222','Science · Year 9','Year 9','Room 203'),
  ('33333333-3333-4333-8333-333333333333','English · Year 10','Year 10','Room 305')
on conflict (id) do nothing;

insert into public.enrollments (class_id, student_id)
select case
  when cast(substring(s.email from 8 for 2) as integer) <= 17 then '11111111-1111-4111-8111-111111111111'::uuid
  when cast(substring(s.email from 8 for 2) as integer) <= 34 then '22222222-2222-4222-8222-222222222222'::uuid
  else '33333333-3333-4333-8333-333333333333'::uuid
end, s.id
from public.students s
where s.email like 'student%@school.test'
on conflict (class_id, student_id) do nothing;

-- If the default development teacher exists, assign them to all seeded classes.
-- This is what allows the teacher account to see the seeded rosters through RLS.
insert into public.class_teachers (class_id, teacher_id)
select c.id, p.id
from public.classes c
join public.profiles p on p.role = 'teacher'
join auth.users u on u.id = p.id
where u.email = 'teacher@school.edu'
  and c.id in (
    '11111111-1111-4111-8111-111111111111'::uuid,
    '22222222-2222-4222-8222-222222222222'::uuid,
    '33333333-3333-4333-8333-333333333333'::uuid
  )
on conflict (class_id, teacher_id) do nothing;

-- Optional cleanup for this seed set:
-- delete from public.enrollments where student_id in (select id from public.students where email like 'student%@school.test');
-- delete from public.students where email like 'student%@school.test';
