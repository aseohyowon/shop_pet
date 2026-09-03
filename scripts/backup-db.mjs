// Supabase(public 스키마) 데이터 백업 — SUPABASE_DB_URL로 직접 접속해 테이블별 JSON으로 저장.
//   node scripts/backup-db.mjs        (또는 npm run db:backup)
//
// 스키마 자체는 supabase/migrations/*.sql 에 이미 버전관리되므로, 여기서는 "데이터"만 받는다.
// 복구: 새 Supabase 프로젝트에 마이그레이션 순서대로 실행 → node scripts/restore-db.mjs <백업폴더>
//
// auth.users(로그인 계정)는 Supabase가 관리하는 별도 스키마라 여기 포함되지 않는다.
// 앱에서 쓰는 사용자 정보는 public.profiles 에 있고 그건 백업된다.
import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import pg from 'pg'
import 'dotenv/config'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const stamp = new Date()
  .toISOString()
  .replace(/[:T]/g, '-')
  .replace(/\..+/, '')
const outDir = resolve(root, 'backups', stamp)

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false }
})

const run = async () => {
  if (!process.env.SUPABASE_DB_URL) {
    console.error('SUPABASE_DB_URL 이 .env 에 없습니다.')
    process.exit(1)
  }
  await client.connect()
  mkdirSync(outDir, { recursive: true })

  const { rows: tables } = await client.query(`
    select table_name
    from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
    order by table_name
  `)

  const manifest = { createdAt: new Date().toISOString(), tables: {} }

  for (const { table_name } of tables) {
    const { rows } = await client.query(`select * from public."${table_name}"`)
    writeFileSync(resolve(outDir, `${table_name}.json`), JSON.stringify(rows, null, 2))
    manifest.tables[table_name] = rows.length
    console.log(`  ${table_name.padEnd(20)} ${rows.length} rows`)
  }

  writeFileSync(resolve(outDir, '_manifest.json'), JSON.stringify(manifest, null, 2))
  await client.end()

  const total = Object.values(manifest.tables).reduce((a, b) => a + b, 0)
  console.log(`\n✔ 백업 완료: backups/${stamp}  (테이블 ${tables.length}개, 총 ${total} rows)`)
}

run().catch((e) => {
  console.error('백업 실패:', e.message)
  process.exit(1)
})
