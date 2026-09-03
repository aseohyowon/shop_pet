// 백업 폴더의 JSON 데이터를 DB에 복원한다. ⚠️ 대상 테이블을 비우고 다시 넣는다(TRUNCATE + INSERT).
//   node scripts/restore-db.mjs backups/2026-09-03-12-00-00 --confirm
//
// 먼저 대상 DB에 supabase/migrations/*.sql 을 순서대로 실행해 스키마가 있어야 한다.
// FK/트리거는 복원 중 잠시 비활성화(session_replication_role=replica)한다.
import { readFileSync, readdirSync } from 'node:fs'
import { resolve } from 'node:path'
import pg from 'pg'
import 'dotenv/config'

const dir = process.argv[2]
const confirmed = process.argv.includes('--confirm')

if (!dir) {
  console.error('사용법: node scripts/restore-db.mjs <백업폴더> --confirm')
  process.exit(1)
}
if (!confirmed) {
  console.error('⚠️ 이 작업은 대상 테이블을 비우고 덮어씁니다. 확실하면 끝에 --confirm 을 붙이세요.')
  process.exit(1)
}

// FK 의존성 순서 (부모 → 자식). 목록에 없는 테이블은 마지막에 알파벳 순.
const ORDER = [
  'site_settings',
  'categories',
  'service_settings',
  'daily_capacity',
  'profiles',
  'pets',
  'products',
  'reservations',
  'orders',
  'order_items',
  'cart_items',
  'payments',
  'inquiries'
]

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false }
})

const quoteVal = (v) => {
  if (v === null) return 'null'
  if (typeof v === 'number') return String(v)
  if (typeof v === 'boolean') return v ? 'true' : 'false'
  if (v instanceof Date) return `'${v.toISOString()}'`
  if (typeof v === 'object') return `'${JSON.stringify(v).replace(/'/g, "''")}'::jsonb`
  return `'${String(v).replace(/'/g, "''")}'`
}

const run = async () => {
  const files = readdirSync(resolve(dir)).filter((f) => f.endsWith('.json') && f !== '_manifest.json')
  const tableNames = files.map((f) => f.replace(/\.json$/, ''))
  const ordered = [
    ...ORDER.filter((t) => tableNames.includes(t)),
    ...tableNames.filter((t) => !ORDER.includes(t)).sort()
  ]

  await client.connect()
  await client.query('begin')
  await client.query("set session_replication_role = 'replica'") // FK/트리거 우회

  try {
    // 자식 → 부모 역순으로 비우기
    for (const t of [...ordered].reverse()) {
      await client.query(`truncate table public."${t}" cascade`)
    }
    // 부모 → 자식 순으로 삽입
    for (const t of ordered) {
      const rows = JSON.parse(readFileSync(resolve(dir, `${t}.json`), 'utf8'))
      if (!rows.length) {
        console.log(`  ${t.padEnd(20)} 0`)
        continue
      }
      const cols = Object.keys(rows[0])
      const colList = cols.map((c) => `"${c}"`).join(', ')
      for (const row of rows) {
        const vals = cols.map((c) => quoteVal(row[c])).join(', ')
        await client.query(`insert into public."${t}" (${colList}) values (${vals})`)
      }
      console.log(`  ${t.padEnd(20)} ${rows.length}`)
    }
    await client.query("set session_replication_role = 'origin'")
    await client.query('commit')
    console.log('\n✔ 복원 완료')
  } catch (e) {
    await client.query('rollback')
    console.error('복원 실패, 롤백함:', e.message)
    process.exit(1)
  } finally {
    await client.end()
  }
}

run().catch((e) => {
  console.error(e.message)
  process.exit(1)
})
