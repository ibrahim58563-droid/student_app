import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const { email, password, full_name, grade, group_name, notes, avatar_index } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data: userData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    user_metadata: { full_name },
    email_confirm: true,
  })

  if (authError) {
    return new Response(JSON.stringify({ error: authError.message }), { status: 400 })
  }

  const userId = userData.user.id

  await supabase.from('profiles').upsert({
    id: userId,
    full_name,
    role: 'student',
    grade,
    group_name,
    notes,
    avatar_index: avatar_index ?? 0,
  }, { onConflict: 'id' })

  return new Response(JSON.stringify({ user_id: userId }), { status: 200 })
})
