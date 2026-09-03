// DB 마이그레이션 직접 적용용 스크립트 (SUPABASE_DB_URL 사용, 서버 전용)
// 사용: node scripts/run-migrations.mjs [파일1.sql 파일2.sql ...]
// 인자가 없으면 supabase/migrations/*.sql 전체를 파일명 순서대로 실행.
import { readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join, resolve } from 'node:path'
import pg from 'pg'
import 'dotenv/config'

const __dirname = dirname(fileURLToPath(import.meta.url))
const migDir = resolve(__dirname, '..', 'supabase', 'migrations')

const args = process.argv.slice(2)
const files = args.length
  ? args.map((a) => (a.includes('/') || a.includes('\\') ? a : join(migDir, a)))
  : readdirSync(migDir).filter((f) => f.endsWith('.sql')).sort().map((f) => join(migDir, f))

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false }
})

const run = async () => {
  await client.connect()
  for (const file of files) {
    const sql = readFileSync(file, 'utf8')
    process.stdout.write(`▶ ${file.replace(migDir + '\\', '').replace(migDir + '/', '')} ... `)
    try {
      await client.query(sql)
      console.log('OK')
    } catch (e) {
      console.log('FAIL')
      console.error(`   ${e.message}`)
    }
  }
  // PostgREST(REST API) 스키마 캐시 갱신
  await client.query("notify pgrst, 'reload schema'")
  console.log('▶ PostgREST 스키마 캐시 reload 요청 완료')
  await client.end()
}

run().catch((e) => {
  console.error(e)
  process.exit(1)
})
