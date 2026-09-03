<template>
  <footer class="border-t border-gray-200 bg-gray-50">
    <div class="container-page grid gap-6 py-10 text-sm text-gray-500 sm:grid-cols-2 lg:grid-cols-3">
      <div>
        <p class="mb-2 flex items-center gap-2 text-base font-bold text-gray-800">
          <img src="/images/logo-icon.png" alt="댕이를 부탁해" class="h-8 w-8 object-contain" /> 댕이를 부탁해
        </p>
        <p>반려동물 호텔 · 데이케어 예약과 용품 쇼핑을 한 곳에서.</p>
      </div>
      <div>
        <p class="mb-2 font-semibold text-gray-700">오시는 길</p>
        <p>서울특별시 ○○구 ○○로 123</p>
        <p>영업시간 매일 09:00 - 19:00</p>
      </div>
      <div>
        <p class="mb-2 font-semibold text-gray-700">문의</p>
        <p>대표전화 02-000-0000</p>
        <p>이메일 hello@daengyi.example</p>
        <NuxtLink to="/contact" class="mt-1 inline-block font-medium text-brand-600 hover:underline">1:1 문의하기</NuxtLink>
      </div>
    </div>
    <div class="border-t border-gray-200 py-4 text-center text-xs text-gray-400">
      <div class="mb-2 flex justify-center gap-4">
        <NuxtLink to="/terms" class="hover:text-gray-600">이용약관</NuxtLink>
        <NuxtLink to="/privacy" class="font-semibold hover:text-gray-600">개인정보처리방침</NuxtLink>
      </div>
      © {{ new Date().getFullYear() }} 댕이를 부탁해. All rights reserved.
    </div>
  </footer>
</template>
