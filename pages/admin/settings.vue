<script setup lang="ts">
import type { SiteTheme, HomeVariant } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { siteTheme, homeVariant, contactEnabled, updateSetting } = useSiteTheme()

const selectedTheme = ref<SiteTheme>(siteTheme.value)
const selectedHome = ref<HomeVariant>(homeVariant.value)
const selectedContact = ref<boolean>(contactEnabled.value)

watch(siteTheme, (v) => (selectedTheme.value = v))
watch(homeVariant, (v) => (selectedHome.value = v))
watch(contactEnabled, (v) => (selectedContact.value = v))

const savingContact = ref(false)
const contactMessage = ref<{ type: 'ok' | 'err'; text: string } | null>(null)

const toggleContact = async () => {
  savingContact.value = true
  contactMessage.value = null
  try {
    await updateSetting('contact_enabled', selectedContact.value ? 'on' : 'off')
    contactMessage.value = {
      type: 'ok',
      text: selectedContact.value
        ? '1:1 문의 메뉴를 활성화했습니다.'
        : '1:1 문의 메뉴를 비활성화했습니다. 고객 화면에서 숨겨집니다.'
    }
  } catch (e: any) {
    selectedContact.value = contactEnabled.value
    contactMessage.value = { type: 'err', text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    savingContact.value = false
  }
}

const themeOptions: { value: SiteTheme; label: string; desc: string }[] = [
  { value: 'default', label: '지금 테마', desc: '현재 기본 디자인 (오렌지 톤). 홈·예약·쇼핑몰·마이페이지 모두 기존 화면.' },
  { value: 'theme1', label: '테마 1', desc: 'Warm Paw Prints 디자인 (브라운/핑크/크림). 기본 홈은 메인화면 1.' },
  { value: 'theme2', label: '테마 2', desc: 'Warm Paw Prints 디자인 (브라운/핑크/크림). 기본 홈은 메인화면 2.' }
]

const homeOptions: { value: HomeVariant; label: string; desc: string }[] = [
  { value: 'auto', label: '테마 기본', desc: '선택한 사이트 테마의 기본 홈 화면을 그대로 사용합니다.' },
  { value: 'main1', label: '메인화면 1', desc: '중앙 정렬 히어로 + 프리미엄 환경 + 오시는 길 구성.' },
  { value: 'main2', label: '메인화면 2', desc: '좌우 분할 히어로 + 3가지 서비스 카드 구성.' }
]

const saving = ref(false)
const message = ref<{ type: 'ok' | 'err'; text: string } | null>(null)

const dirty = computed(
  () => selectedTheme.value !== siteTheme.value || selectedHome.value !== homeVariant.value
)

const save = async () => {
  saving.value = true
  message.value = null
  try {
    if (selectedTheme.value !== siteTheme.value) await updateSetting('site_theme', selectedTheme.value)
    if (selectedHome.value !== homeVariant.value) await updateSetting('home_variant', selectedHome.value)
    message.value = { type: 'ok', text: '저장되었습니다. 고객 화면에 바로 반영됩니다.' }
  } catch (e: any) {
    message.value = { type: 'err', text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    saving.value = false
  }
}

const homePreviewName = computed(() => {
  if (selectedHome.value === 'main1') return '메인화면 1'
  if (selectedHome.value === 'main2') return '메인화면 2'
  if (selectedTheme.value === 'theme1') return '메인화면 1 (테마 기본)'
  if (selectedTheme.value === 'theme2') return '메인화면 2 (테마 기본)'
  return '기존 홈 (테마 기본)'
})
</script>

<template>
  <div class="max-w-3xl">
    <h1 class="mb-1 text-2xl font-bold text-gray-900">사이트 설정</h1>
    <p class="mb-8 text-sm text-gray-500">고객에게 보여지는 화면 디자인(테마)을 선택합니다.</p>

    <!-- 사이트 테마 -->
    <section class="mb-8">
      <h2 class="mb-3 text-sm font-semibold text-gray-700">사이트 테마</h2>
      <div class="space-y-3">
        <label
          v-for="opt in themeOptions"
          :key="opt.value"
          class="flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition"
          :class="selectedTheme === opt.value ? 'border-brand-500 bg-brand-50' : 'border-gray-200 hover:bg-gray-50'"
        >
          <input v-model="selectedTheme" type="radio" :value="opt.value" class="mt-1 text-brand-500" />
          <span>
            <span class="block font-semibold text-gray-900">{{ opt.label }}</span>
            <span class="block text-sm text-gray-500">{{ opt.desc }}</span>
          </span>
        </label>
      </div>
    </section>

    <!-- 메인 화면 -->
    <section class="mb-8">
      <h2 class="mb-3 text-sm font-semibold text-gray-700">메인 화면 (홈)</h2>
      <div class="space-y-3">
        <label
          v-for="opt in homeOptions"
          :key="opt.value"
          class="flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition"
          :class="selectedHome === opt.value ? 'border-brand-500 bg-brand-50' : 'border-gray-200 hover:bg-gray-50'"
        >
          <input v-model="selectedHome" type="radio" :value="opt.value" class="mt-1 text-brand-500" />
          <span>
            <span class="block font-semibold text-gray-900">{{ opt.label }}</span>
            <span class="block text-sm text-gray-500">{{ opt.desc }}</span>
          </span>
        </label>
      </div>
      <p class="mt-2 text-xs text-gray-400">현재 적용될 홈: <strong>{{ homePreviewName }}</strong></p>
    </section>

    <!-- 1:1 문의 메뉴 -->
    <section class="mb-8">
      <h2 class="mb-3 text-sm font-semibold text-gray-700">1:1 문의 메뉴</h2>
      <div class="rounded-xl border border-gray-200 p-4">
        <label class="flex cursor-pointer items-start gap-3">
          <input
            v-model="selectedContact"
            type="checkbox"
            class="mt-1 h-4 w-4 rounded text-brand-500"
            @change="toggleContact"
          />
          <span>
            <span class="block font-semibold text-gray-900">
              문의 메뉴 {{ selectedContact ? '활성화' : '비활성화' }}
            </span>
            <span class="block text-sm text-gray-500">
              헤더·푸터의 "문의", 마이페이지 "문의 내역" 탭, 홈 화면 문의 폼, /contact 페이지를 표시할지 결정합니다.
              꺼두면 고객에게 노출되지 않습니다.
            </span>
          </span>
        </label>
        <p
          v-if="contactMessage"
          class="mt-3 text-sm"
          :class="contactMessage.type === 'ok' ? 'text-green-600' : 'text-red-500'"
        >
          {{ savingContact ? '저장 중...' : contactMessage.text }}
        </p>
      </div>
    </section>

    <div class="flex items-center gap-3">
      <button type="button" class="btn-primary" :disabled="saving || !dirty" @click="save">
        {{ saving ? '저장 중...' : '저장' }}
      </button>
      <NuxtLink to="/" target="_blank" class="btn-secondary text-sm">고객 화면 새 탭으로 보기</NuxtLink>
      <p
        v-if="message"
        class="text-sm"
        :class="message.type === 'ok' ? 'text-green-600' : 'text-red-500'"
      >
        {{ message.text }}
      </p>
    </div>
  </div>
</template>
