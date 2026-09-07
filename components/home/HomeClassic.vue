<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'

const { createInquiry } = useInquiries()
const { contactEnabled } = useSiteTheme()

const services = [
  { title: '호텔 숙박', desc: '여행 중에도 안심할 수 있는 1:1 케어 숙박 서비스', icon: '🏨' },
  { title: '데이케어', desc: '하루 동안 안전하게 뛰어놀 수 있는 놀이 공간', icon: '☀️' },
  { title: '펫샵', desc: '엄선된 사료와 용품을 온라인으로 편리하게', icon: '🛍️' }
]

const contact = reactive({ name: '', phone: '', message: '' })
const sending = ref(false)
const sent = ref(false)
const contactError = ref('')

const sendContact = async () => {
  contactError.value = ''
  if (!contact.name.trim() || !contact.message.trim()) {
    contactError.value = '이름과 문의 내용을 입력해주세요.'
    return
  }
  sending.value = true
  try {
    await createInquiry({ name: contact.name, phone: contact.phone, message: contact.message })
    sent.value = true
  } catch (e: any) {
    contactError.value = e?.message ?? '문의 접수에 실패했습니다. 잠시 후 다시 시도해주세요.'
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-b from-brand-50 to-white">
      <div class="container-page flex flex-col items-center gap-6 py-16 text-center sm:py-20">
        <img src="/images/logo-full.png" alt="댕이를 부탁해 — 애견호텔&데이케어" class="h-48 w-auto object-contain sm:h-64" />
        <h1 class="text-3xl font-extrabold leading-tight text-gray-900 sm:text-5xl">
          우리 아이가 편안한<br class="sm:hidden" />
          <span class="text-brand-600">두 번째 집</span>
        </h1>
        <p class="max-w-xl text-gray-600">
          호텔 숙박부터 데이케어, 사료·용품 쇼핑까지. 반려동물을 위한 모든 것을 한 곳에서 예약하고 관리하세요.
        </p>
        <div class="flex gap-3">
          <NuxtLink to="/reservation" class="btn-primary">예약하기</NuxtLink>
          <NuxtLink to="/shop" class="btn-secondary">쇼핑몰 둘러보기</NuxtLink>
        </div>
      </div>
    </section>

    <!-- Services -->
    <section class="container-page py-16">
      <h2 class="mb-8 text-center text-2xl font-bold text-gray-900">서비스 안내</h2>
      <div class="grid gap-5 sm:grid-cols-3">
        <div v-for="s in services" :key="s.title" class="card text-center">
          <p class="mb-3 text-3xl">{{ s.icon }}</p>
          <p class="mb-1 font-semibold text-gray-900">{{ s.title }}</p>
          <p class="text-sm text-gray-500">{{ s.desc }}</p>
        </div>
      </div>
    </section>

    <!-- Location -->
    <section class="bg-gray-50 py-16">
      <div class="container-page grid gap-8 lg:grid-cols-2">
        <div>
          <h2 class="mb-4 text-2xl font-bold text-gray-900">오시는 길</h2>
          <p class="mb-1 text-gray-600">{{ BUSINESS_INFO.name }}</p>
          <p class="mb-1 text-gray-600">{{ BUSINESS_INFO.address }}</p>
          <p class="mb-1 text-gray-600">영업시간 {{ BUSINESS_INFO.hours }}</p>
          <p v-if="BUSINESS_INFO.phone" class="text-gray-600">대표전화 {{ BUSINESS_INFO.phone }}</p>
        </div>
        <CommonLocationMap height="h-64" />
      </div>
    </section>

    <!-- Contact -->
    <section v-if="contactEnabled" class="container-page py-16">
      <h2 class="mb-6 text-center text-2xl font-bold text-gray-900">문의하기</h2>
      <div v-if="sent" class="mx-auto max-w-lg rounded-xl border border-gray-200 bg-white p-8 text-center">
        <p class="mb-1 font-bold text-gray-900">문의가 접수되었습니다</p>
        <p class="text-sm text-gray-500">빠른 시일 내에 답변드리겠습니다.</p>
      </div>
      <form v-else class="mx-auto max-w-lg space-y-4" @submit.prevent="sendContact">
        <div>
          <label class="label-field" for="contact-name">이름</label>
          <input id="contact-name" v-model="contact.name" type="text" class="input-field" placeholder="홍길동" />
        </div>
        <div>
          <label class="label-field" for="contact-phone">연락처</label>
          <input id="contact-phone" v-model="contact.phone" type="tel" class="input-field" placeholder="010-0000-0000" />
        </div>
        <div>
          <label class="label-field" for="contact-message">문의 내용</label>
          <textarea id="contact-message" v-model="contact.message" rows="4" class="input-field" placeholder="문의하실 내용을 입력해주세요" />
        </div>
        <p v-if="contactError" class="text-sm text-red-500">{{ contactError }}</p>
        <button type="submit" class="btn-primary w-full" :disabled="sending">
          {{ sending ? '접수 중...' : '문의 보내기' }}
        </button>
      </form>
    </section>
  </div>
</template>
