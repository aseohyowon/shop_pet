<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'

useHead({ title: '이용약관 — 댕이를 부탁해' })
</script>

<template>
  <div class="container-page max-w-3xl py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">이용약관</h1>
    <p class="mb-4 text-sm text-gray-400">
      시행일: [시행일자 입력, 예: 2026년 O월 O일]
    </p>
    <dl class="mb-10 grid grid-cols-[5rem_1fr] gap-y-1 rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm text-gray-600">
      <dt class="text-gray-400">상호</dt><dd>{{ BUSINESS_INFO.name }}</dd>
      <dt class="text-gray-400">대표자</dt><dd>{{ BUSINESS_INFO.owner }}</dd>
      <dt class="text-gray-400">소재지</dt><dd>{{ BUSINESS_INFO.address }}</dd>
      <template v-if="BUSINESS_INFO.bizRegNo"><dt class="text-gray-400">사업자번호</dt><dd>{{ BUSINESS_INFO.bizRegNo }}</dd></template>
      <template v-if="BUSINESS_INFO.onlineSalesNo"><dt class="text-gray-400">통신판매업</dt><dd>{{ BUSINESS_INFO.onlineSalesNo }}</dd></template>
    </dl>

    <div class="space-y-10 text-sm leading-relaxed text-gray-700">
      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제1장 총칙</h2>

        <p class="mb-4 font-medium">제1조 (목적)</p>
        <p class="mb-6">
          이 약관은 <strong>댕이를 부탁해</strong>(이하 "회사")가 운영하는 인터넷 웹사이트
          "댕이를 부탁해"(이하 "몰")에서 제공하는 반려동물 호텔·데이케어 예약 서비스 및 반려동물 용품 판매
          서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.
        </p>

        <p class="mb-4 font-medium">제2조 (정의)</p>
        <ul class="mb-6 list-disc space-y-1 pl-5">
          <li>"이용자"란 몰에 접속하여 이 약관에 따라 몰이 제공하는 서비스를 받는 회원 및 비회원을 말합니다.</li>
          <li>"회원"이란 몰에 개인정보를 제공하여 회원등록을 한 자로서, 몰의 정보를 지속적으로 제공받으며 몰이 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.</li>
          <li>"예약"이란 회원이 몰을 통해 호텔 숙박 또는 데이케어 서비스 이용을 신청하는 행위를 말합니다.</li>
          <li>"주문"이란 회원이 몰이 판매하는 상품(사료, 용품 등)의 구매를 신청하는 행위를 말합니다.</li>
        </ul>

        <p class="mb-4 font-medium">제3조 (약관의 효력 및 변경)</p>
        <p class="mb-2">① 이 약관은 몰에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.</p>
        <p>
          ② 회사는 「전자상거래 등에서의 소비자보호에 관한 법률」 등 관련 법을 위배하지 않는 범위에서 이 약관을
          개정할 수 있으며, 개정 시 적용일자 및 개정사유를 명시하여 현행 약관과 함께 몰의 초기화면에 그 적용일자
          7일 이전부터 적용일자 전일까지 공지합니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제2장 회원가입 및 관리</h2>

        <p class="mb-4 font-medium">제4조 (회원가입)</p>
        <p class="mb-6">
          이용자는 회사가 정한 가입 양식(이메일 또는 카카오 소셜 로그인)에 따라 회원정보를 기입한 후 이 약관에
          동의한다는 의사표시를 함으로써 회원가입을 신청하며, 회사는 이러한 신청에 대하여 승낙함으로써 회원으로
          등록됩니다.
        </p>

        <p class="mb-4 font-medium">제5조 (회원 탈퇴 및 자격 상실)</p>
        <p>
          회원은 언제든지 마이페이지를 통해 이용계약 해지(탈퇴)를 신청할 수 있으며, 회사는 관련 법령이 정하는 바에
          따라 이를 즉시 처리합니다. 다만, 진행 중인 예약이나 주문이 있는 경우 해당 건의 처리가 완료된 이후 탈퇴가
          처리될 수 있습니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제3장 예약 서비스</h2>

        <p class="mb-4 font-medium">제6조 (예약의 신청 및 성립)</p>
        <p class="mb-2">
          ① 회원은 몰이 정한 방법에 따라 호텔 숙박 또는 데이케어 서비스의 날짜·시간을 선택하고 반려동물 정보를
          입력하여 예약을 신청할 수 있습니다.
        </p>
        <p class="mb-2">
          ② 예약은 신청만으로 확정되지 않으며, 날짜별 정원 및 회사의 승인을 거쳐 최종 확정됩니다. 회사는 정원
          초과, 반려동물의 건강상태, 기타 운영상 사유로 예약을 거절할 수 있습니다.
        </p>
        <p>
          ③ 예약 확정을 위해서는 몰이 정한 예약금 결제가 필요할 수 있습니다.
        </p>

        <p class="mt-6 mb-4 font-medium">제7조 (반려동물 정보의 정확성)</p>
        <p>
          회원은 예약 시 입력하는 반려동물의 견종, 나이, 체중, 백신 접종 여부, 건강상 특이사항 등을 사실대로
          정확히 제공해야 합니다. 회원이 제공한 정보가 사실과 달라 발생하는 문제(다른 반려동물 또는 직원의 안전
          문제 포함)에 대한 책임은 회원에게 있을 수 있습니다.
        </p>

        <p class="mt-6 mb-4 font-medium">제8조 (예약금 및 환불 규정)</p>
        <p class="mb-2">
          ① 예약 취소 시점에 따른 환불 규정은 다음과 같습니다. (아래는 예시이며, 실제 운영 정책에 맞게 확정하여
          기재해야 합니다.)
        </p>
        <ul class="list-disc space-y-1 pl-5">
          <li>이용일 [O]일 전 취소: 예약금의 [100]% 환불</li>
          <li>이용일 [O]일 전 취소: 예약금의 [O]% 환불</li>
          <li>이용 당일 취소 또는 노쇼(No-show): 환불 불가</li>
        </ul>
        <p class="mt-2">② 회사의 사정으로 예약이 거절되거나 서비스 제공이 불가능한 경우 예약금 전액을 환불합니다.</p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제4장 상품 구매 서비스</h2>

        <p class="mb-4 font-medium">제9조 (구매신청 및 결제)</p>
        <p class="mb-2">① 회원은 몰이 제공하는 화면을 통해 장바구니에 상품을 담고 아래와 같은 방법으로 구매를 신청합니다.</p>
        <ul class="mb-2 list-disc space-y-1 pl-5">
          <li>상품 및 수량의 선택</li>
          <li>결제방법 선택 (신용카드, 카카오페이 등 몰이 제공하는 결제수단)</li>
          <li>이 약관에 대한 동의 및 구매신청에 대한 확인</li>
        </ul>
        <p>
          ② 결제는 전자지급결제대행업체인 토스페이먼츠(주)를 통해 처리되며, 회사는 결제와 관련한 카드번호,
          계좌정보 등 민감한 결제정보를 직접 저장하지 않습니다.
        </p>

        <p class="mt-6 mb-4 font-medium">제10조 (청약철회 및 계약 해제)</p>
        <p>
          회원은 「전자상거래 등에서의 소비자보호에 관한 법률」 제17조에 따라 상품 수령일로부터 7일 이내에 청약을
          철회할 수 있습니다. 다만, 회원의 책임 있는 사유로 상품이 멸실 또는 훼손된 경우, 시간의 경과로 재판매가
          곤란할 정도로 상품의 가치가 현저히 감소한 경우 등 법령이 정한 사유에 해당하는 경우에는 청약철회가
          제한될 수 있습니다.
        </p>

        <p class="mt-6 mb-4 font-medium">제11조 (배송)</p>
        <p>
          회사는 회원이 구매한 상품에 대해 배송수단, 수령자 정보 등을 확인하여 정해진 기간 내 배송이 이루어지도록
          조치합니다. 구체적인 배송 정책(배송비, 배송기간 등)은 별도로 안내합니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제5장 기타</h2>

        <p class="mb-4 font-medium">제12조 (회원의 의무)</p>
        <p class="mb-6">
          회원은 관계법령, 이 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항 등을 준수하여야 하며,
          기타 회사의 업무에 방해되는 행위를 하여서는 안 됩니다.
        </p>

        <p class="mb-4 font-medium">제13조 (회사의 의무)</p>
        <p class="mb-6">
          회사는 법령과 이 약관이 금지하거나 미풍양속에 반하는 행위를 하지 않으며, 계속적이고 안정적으로 서비스를
          제공하기 위하여 최선을 다하여 노력합니다.
        </p>

        <p class="mb-4 font-medium">제14조 (분쟁해결)</p>
        <p>
          이 약관과 관련하여 회사와 회원 간에 발생한 분쟁에 대해서는 대한민국 법을 준거법으로 하며,
          회사의 주소지를 관할하는 법원을 관할 법원으로 합니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">부칙</h2>
        <p>이 약관은 [시행일자 입력]부터 적용됩니다.</p>
      </section>
    </div>
  </div>
</template>
