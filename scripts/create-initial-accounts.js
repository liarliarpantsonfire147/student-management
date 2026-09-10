import { createClient } from '@supabase/supabase-js';

const required = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
for (const key of required) {
  if (!process.env[key]) throw new Error(`Missing ${key} in .env`);
}

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const accounts = [
  { email: process.env.INITIAL_ADMIN_EMAIL || 'admin@school.edu', password: process.env.INITIAL_ADMIN_PASSWORD || 'ChangeMe_Admin_2025!', full_name: 'School Administrator', role: 'admin' },
  { email: process.env.INITIAL_TEACHER_EMAIL || 'teacher@school.edu', password: process.env.INITIAL_TEACHER_PASSWORD || 'ChangeMe_Teacher_2025!', full_name: 'Class Teacher', role: 'teacher' },
];

for (const account of accounts) {
  const { data: users, error: listError } = await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (listError) throw listError;
  let user = users.users.find((item) => item.email?.toLowerCase() === account.email.toLowerCase());
  if (!user) {
    const result = await supabase.auth.admin.createUser({ email: account.email, password: account.password, email_confirm: true });
    if (result.error) throw result.error;
    user = result.data.user;
  } else {
    const result = await supabase.auth.admin.updateUserById(user.id, { password: account.password, email_confirm: true });
    if (result.error) throw result.error;
  }
  const { error: profileError } = await supabase.from('profiles').upsert({ id: user.id, full_name: account.full_name, email: account.email, role: account.role }, { onConflict: 'id' });
  if (profileError) throw profileError;
  console.log(`${account.role}: ${account.email} / ${account.password}`);
}

console.log('Accounts are ready. Change these passwords after the first login.');
