import { createClient } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

const CUSTOMERS = 2000; // matches the seed migration

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  { auth: { persistSession: false } },
);

// Latest 20 orders for one customer. Without an index on (customer_id, created_at)
// Postgres scans and sorts the whole table on every request.
export async function GET(req: Request) {
  const param = new URL(req.url).searchParams.get("customer");
  const customer = param ? Number(param) : 1 + Math.floor(Math.random() * CUSTOMERS);

  const { data, error } = await supabase
    .from("orders")
    .select("id, total_cents, status, created_at")
    .eq("customer_id", customer)
    .order("created_at", { ascending: false })
    .limit(20);

  if (error) return Response.json({ error: error.message }, { status: 500 });
  return Response.json({ customer, orders: data });
}
