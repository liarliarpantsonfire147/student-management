import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) throw new Error('Missing SUPABASE_URL or a Supabase server key in .env.');

const supabase = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
const results = [
  { grade: 'A', gpa: 4.0, feedback: 'Excellent work. Shows strong understanding and consistent effort.' },
  { grade: 'A-', gpa: 3.7, feedback: 'Very good work. A little more detail would make this excellent.' },
  { grade: 'B+', gpa: 3.3, feedback: 'Good progress. Keep building confidence in the harder topics.' },
  { grade: 'B', gpa: 3.0, feedback: 'Solid work overall. Review the feedback and practise regularly.' },
  { grade: 'B-', gpa: 2.7, feedback: 'A satisfactory result. Focus on accuracy and completing all sections.' },
  { grade: 'C+', gpa: 2.3, feedback: 'Making progress. Ask questions early when a topic is unclear.' },
  { grade: 'C', gpa: 2.0, feedback: 'More consistent practice is needed to strengthen core skills.' },
];
const hash = (value) => [...value].reduce((total, char) => ((total * 31) + char.charCodeAt(0)) >>> 0, 7);

const { data: enrollments, error: enrollmentError } = await supabase
  .from('enrollments')
  .select('class_id, student_id');
if (enrollmentError) throw enrollmentError;

const rows = (enrollments || []).map((enrollment) => {
  const result = results[hash(`${enrollment.class_id}${enrollment.student_id}`) % results.length];
  return { ...enrollment, ...result, updated_at: new Date().toISOString() };
});
const { error: gradeError } = await supabase
  .from('grades')
  .upsert(rows, { onConflict: 'class_id,student_id' });
if (gradeError) throw gradeError;

console.log(`Added or refreshed grades, GPAs, and feedback for ${rows.length} class enrollments.`);
