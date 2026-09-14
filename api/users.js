import { createClient } from '@supabase/supabase-js';

function respond(response, status, body) {
  response.status(status).json(body);
}

function getAdminClient() {
  const secretKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!process.env.SUPABASE_URL || !secretKey) {
    throw new Error('Supabase server credentials are not configured.');
  }
  return createClient(process.env.SUPABASE_URL, secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    return respond(response, 405, { error: 'Method not allowed.' });
  }

  try {
    const token = request.headers.authorization?.replace(/^Bearer\s+/i, '');
    if (!token) return respond(response, 401, { error: 'Authentication required.' });

    const admin = getAdminClient();
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) return respond(response, 401, { error: 'Invalid session.' });

    const { data: caller, error: callerError } = await admin
      .from('profiles')
      .select('role')
      .eq('id', authData.user.id)
      .single();
    if (callerError || caller?.role !== 'admin') {
      return respond(response, 403, { error: 'Admin access required.' });
    }

    const { email, password, fullName, role = 'teacher' } = request.body || {};
    const cleanEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
    const cleanName = typeof fullName === 'string' ? fullName.trim() : '';
    if (!cleanEmail || !cleanName || typeof password !== 'string' || password.length < 8 || !['admin', 'teacher'].includes(role)) {
      return respond(response, 400, { error: 'Provide a name, valid email, password of at least 8 characters, and role.' });
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: cleanEmail,
      password,
      email_confirm: true,
      user_metadata: { full_name: cleanName, role },
    });
    if (createError || !created.user) return respond(response, 400, { error: createError?.message || 'Could not create account.' });

    const { error: profileError } = await admin.from('profiles').insert({
      id: created.user.id,
      full_name: cleanName,
      email: cleanEmail,
      role,
    });
    if (profileError) {
      await admin.auth.admin.deleteUser(created.user.id);
      return respond(response, 400, { error: profileError.message });
    }

    return respond(response, 201, { user: { id: created.user.id, email: cleanEmail, fullName: cleanName, role } });
  } catch (error) {
    console.error('POST /api/users failed', error);
    return respond(response, 500, { error: 'Unable to create the account.' });
  }
}
