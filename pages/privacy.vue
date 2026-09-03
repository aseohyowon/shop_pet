<script setup lang="ts">
useHead({ title: '개인정보처리방침 — 댕이를 부탁해' })
</script>

<template>
  <div class="container-page max-w-3xl py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">개인정보처리방침</h1>
    <p class="mb-10 text-sm text-gray-400">
      시행일: [시행일자 입력, 예: 2026년 O월 O일]
    </p>

    <div class="space-y-10 text-sm leading-relaxed text-gray-700">
      <section>
        <p>
          <strong>[상호명 입력, 예: 댕이를 부탁해]</strong>(이하 "회사")는 이용자의 개인정보를 중요시하며,
          「개인정보보호법」 등 관련 법령을 준수하고 있습니다. 회사는 개인정보처리방침을 통하여
          이용자가 제공하는 개인정보가 어떠한 목적과 방식으로 이용되고 있으며, 개인정보보호를 위해
          어떠한 조치가 취해지고 있는지 알려드립니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제1조 (수집하는 개인정보 항목 및 수집 방법)</h2>
        <p class="mb-2 font-medium">1. 수집 항목</p>
        <ul class="list-disc space-y-1 pl-5">
          <li>회원가입(이메일) 시: 이메일, 비밀번호, 이름, 휴대전화번호</li>
          <li>카카오 소셜 로그인 시: 이메일, 닉네임 (카카오 계정으로부터 이용자의 동의를 받은 항목에 한함)</li>
          <li>예약 신청 시: 반려동물 정보(이름, 견종, 나이, 체중, 백신 접종 여부, 특이사항), 예약 요청사항</li>
          <li>상품 주문 시: 배송에 필요한 정보(추후 배송 기능 도입 시 수집)</li>
          <li>결제 시: 결제는 토스페이먼츠(PG사)를 통해 이루어지며, <strong>카드번호·계좌번호 등 결제수단 정보는 회사가 직접 수집·저장하지 않습니다.</strong> 회사는 결제 성사 여부, 결제수단 종류(예: 카드, 카카오페이), 결제 승인번호만 보유합니다.</li>
          <li>서비스 이용 과정에서 자동 생성되는 정보: 접속 로그, 접속 IP, 쿠키</li>
        </ul>
        <p class="mt-2 mb-2 font-medium">2. 수집 방법</p>
        <p>홈페이지 회원가입, 예약·주문 신청, 고객센터 문의, 카카오 등 소셜 로그인 연동을 통해 수집합니다.</p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제2조 (개인정보의 수집 및 이용 목적)</h2>
        <ul class="list-disc space-y-1 pl-5">
          <li>회원 가입 의사 확인, 본인 식별·인증, 회원자격 유지·관리</li>
          <li>호텔·데이케어 예약 접수, 예약 확인 및 안내, 예약금 결제 처리</li>
          <li>상품 주문 접수, 결제 처리, 주문/배송 상태 안내</li>
          <li>반려동물의 건강·안전한 케어를 위한 정보(견종, 체중, 백신여부, 특이사항 등) 확인</li>
          <li>민원사항 처리, 공지사항 전달</li>
        </ul>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제3조 (개인정보의 보유 및 이용 기간)</h2>
        <p class="mb-2">
          회사는 원칙적으로 개인정보 수집 및 이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.
          다만, 관계 법령의 규정에 의하여 보존할 필요가 있는 경우 회사는 아래와 같이 관계 법령에서 정한
          일정한 기간 동안 회원정보를 보관합니다.
        </p>
        <ul class="list-disc space-y-1 pl-5">
          <li>계약 또는 청약철회 등에 관한 기록: 5년 (전자상거래 등에서의 소비자보호에 관한 법률)</li>
          <li>대금결제 및 재화 등의 공급에 관한 기록: 5년 (전자상거래 등에서의 소비자보호에 관한 법률)</li>
          <li>소비자의 불만 또는 분쟁처리에 관한 기록: 3년 (전자상거래 등에서의 소비자보호에 관한 법률)</li>
          <li>부정 이용 방지를 위한 최소한의 정보: 회원 탈퇴 후 [기간 입력]</li>
        </ul>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제4조 (개인정보의 제3자 제공)</h2>
        <p>
          회사는 이용자의 개인정보를 제2조에서 명시한 목적 범위 내에서만 처리하며, 이용자의 사전 동의 없이는
          동 범위를 초과하여 처리하거나 제3자에게 제공하지 않습니다. 다만, 법령에 근거가 있거나 수사 목적으로
          법령에서 정한 절차와 방법에 따라 수사기관의 요구가 있는 경우에는 예외로 합니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제5조 (개인정보 처리의 위탁)</h2>
        <p class="mb-2">회사는 서비스 제공을 위해 아래와 같이 개인정보 처리업무를 위탁하고 있습니다.</p>
        <div class="overflow-x-auto">
          <table class="w-full min-w-[480px] border-collapse text-left text-sm">
            <thead>
              <tr class="border-b border-gray-200 text-gray-500">
                <th class="py-2 pr-4 font-medium">수탁업체</th>
                <th class="py-2 pr-4 font-medium">위탁업무 내용</th>
                <th class="py-2 font-medium">보유·이용 기간</th>
              </tr>
            </thead>
            <tbody>
              <tr class="border-b border-gray-100">
                <td class="py-2 pr-4">토스페이먼츠(주)</td>
                <td class="py-2 pr-4">결제 처리 및 결제 관련 본인 확인</td>
                <td class="py-2">위탁계약 종료 시 또는 회원 탈퇴 시까지</td>
              </tr>
              <tr class="border-b border-gray-100">
                <td class="py-2 pr-4">Supabase, Inc.</td>
                <td class="py-2 pr-4">회원 정보 및 서비스 데이터의 저장·관리(클라우드 서버, 해외 소재)</td>
                <td class="py-2">위탁계약 종료 시 또는 회원 탈퇴 시까지</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p class="mt-2 text-xs text-gray-400">
          ※ Supabase 서버는 국외에 소재할 수 있어 개인정보의 국외 이전이 발생할 수 있습니다.
          이전 항목, 이전 국가, 이전 일시 및 방법 등은 관련 법령에 따라 별도로 고지합니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제6조 (이용자 및 법정대리인의 권리와 그 행사방법)</h2>
        <p>
          이용자는 언제든지 등록되어 있는 자신의 개인정보를 조회하거나 수정할 수 있으며, 가입 해지(동의 철회)를
          요청할 수도 있습니다. 마이페이지를 통해 직접 열람·정정하거나, 개인정보 보호책임자에게 서면, 전화 또는
          이메일로 연락하시면 지체 없이 조치하겠습니다.
        </p>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제7조 (개인정보의 안전성 확보조치)</h2>
        <ul class="list-disc space-y-1 pl-5">
          <li>비밀번호는 암호화되어 저장·관리되며, 본인만이 알고 있음</li>
          <li>데이터베이스 접근 권한을 최소한의 인원으로 제한하고, 데이터 접근 시 행 단위 접근 제어(Row Level Security)를 적용</li>
          <li>결제정보(카드번호 등)는 회사 서버에 저장하지 않고 PG사(토스페이먼츠)를 통해서만 처리</li>
        </ul>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제8조 (개인정보 보호책임자)</h2>
        <p class="mb-2">
          회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 이용자의 불만처리 및
          피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.
        </p>
        <ul class="list-disc space-y-1 pl-5">
          <li>성명: [보호책임자 이름 입력]</li>
          <li>연락처: [전화번호 입력]</li>
          <li>이메일: [이메일 입력]</li>
        </ul>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제9조 (권익침해 구제방법)</h2>
        <p class="mb-2">
          이용자는 아래의 기관에 개인정보 침해에 대한 신고나 상담을 하실 수 있습니다.
        </p>
        <ul class="list-disc space-y-1 pl-5">
          <li>개인정보침해신고센터 (privacy.kisa.or.kr / 국번없이 118)</li>
          <li>개인정보분쟁조정위원회 (www.kopico.go.kr / 1833-6972)</li>
          <li>대검찰청 사이버범죄수사단 (www.spo.go.kr / 국번없이 1301)</li>
          <li>경찰청 사이버안전국 (cyberbureau.police.go.kr / 국번없이 182)</li>
        </ul>
      </section>

      <section>
        <h2 class="mb-3 text-lg font-semibold text-gray-900">제10조 (고지의 의무)</h2>
        <p>
          현 개인정보처리방침 내용의 추가, 삭제 및 수정이 있을 경우에는 개정 최소 7일 전부터 홈페이지의
          '공지사항'을 통해 고지할 것입니다.
        </p>
      </section>
    </div>
  </div>
</template>
