import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) throw new Error('Missing SUPABASE_URL or a Supabase server key in .env.');
const supabase = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });

const classesToCreate = [
  { name: 'AP Calculus AB', year_group: 'Year 12', room: 'STEM 401' },
  { name: 'AP Physics C', year_group: 'Year 12', room: 'STEM 402' },
  { name: 'AP English Literature', year_group: 'Year 12', room: 'Humanities 301' },
  { name: 'Advanced Research Seminar', year_group: 'Year 12', room: 'Library Lab' },
];
const highAchievers = [
  'Aaliyah Okafor', 'Bryce Coleman', 'Celine Adewale', 'Darius Grant',
  'Eloise Martin', 'Femi Akintola', 'Gianna Russo', 'Harper Davis',
  'Imani Bello', 'Jonah Reid', 'Kiara Thompson', 'Leon Chen',
  'Mira Okonkwo', 'Nolan Brooks', 'Olivia James', 'Parker Mensah',
];

const { data: okhale, error: teacherError } = await supabase
  .from('profiles')
  .select('id')
  .ilike('full_name', 'okhale')
  .eq('role', 'teacher')
  .single();
if (teacherError || !okhale) throw new Error('Could not find the teacher profile for Okhale.');

const { data: existingClasses, error: existingClassError } = await supabase.from('classes').select('id,name');
if (existingClassError) throw existingClassError;
const classIds = new Map(existingClasses.map((item) => [item.name, item.id]));
for (const item of classesToCreate) {
  if (!classIds.has(item.name)) {
    const { data, error } = await supabase.from('classes').insert(item).select('id,name').single();
    if (error) throw error;
    classIds.set(data.name, data.id);
  }
}

const { data: allClasses, error: classError } = await supabase.from('classes').select('id,name');
if (classError) throw classError;
const english = allClasses.find((item) => item.name === 'English · Year 10');
if (!english) throw new Error('Could not find English · Year 10.');
const seniorClassIds = classesToCreate.map((item) => allClasses.find((row) => row.name === item.name)?.id).filter(Boolean);

const { data: englishEnrollments, error: englishError } = await supabase.from('enrollments').select('student_id').eq('class_id', english.id);
if (englishError) throw englishError;
const englishGrades = englishEnrollments.map((item) => ({
  class_id: english.id, student_id: item.student_id, grade: 'A', gpa: 4.0,
  feedback: 'Outstanding performance. Consistently insightful, precise, and well supported.', updated_at: new Date().toISOString(),
}));
if (englishGrades.length) {
  const { error } = await supabase.from('grades').upsert(englishGrades, { onConflict: 'class_id,student_id' });
  if (error) throw error;
}

const { data: existingStudents, error: studentError } = await supabase.from('students').select('id,email');
if (studentError) throw studentError;
const studentIds = new Map(existingStudents.map((item) => [item.email, item.id]));
for (const [index, full_name] of highAchievers.entries()) {
  const email = `senior${String(index + 1).padStart(2, '0')}@school.test`;
  if (!studentIds.has(email)) {
    const { data, error } = await supabase.from('students').insert({ full_name, email, year_group: 'Year 12' }).select('id,email').single();
    if (error) throw error;
    studentIds.set(data.email, data.id);
  }
}

const seniorStudents = [...studentIds.entries()]
  .filter(([email]) => email?.startsWith('senior'))
  .map(([, id]) => id);
const assignments = [...seniorClassIds, english.id].map((class_id) => ({ class_id, teacher_id: okhale.id }));
const { error: assignmentError } = await supabase.from('class_teachers').upsert(assignments, { onConflict: 'class_id,teacher_id' });
if (assignmentError) throw assignmentError;

const enrollments = seniorClassIds.flatMap((class_id) => seniorStudents.map((student_id) => ({ class_id, student_id })));
const { error: enrollmentError } = await supabase.from('enrollments').upsert(enrollments, { onConflict: 'class_id,student_id' });
if (enrollmentError) throw enrollmentError;
const grades = enrollments.map(({ class_id, student_id }) => ({
  class_id, student_id, grade: 'A+', gpa: 4.0,
  feedback: 'Exceptional achievement. Demonstrates independent thinking and mastery of advanced material.', updated_at: new Date().toISOString(),
}));
const { error: gradeError } = await supabase.from('grades').upsert(grades, { onConflict: 'class_id,student_id' });
if (gradeError) throw gradeError;

console.log(`Okhale's English class is now 4.0. Added ${seniorClassIds.length} senior/AP classes and ${seniorStudents.length} high-achieving students.`);
