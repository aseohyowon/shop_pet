<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const router = useRouter()
const { createProduct, uploadProductImage } = useProducts()

const name = ref('')
const category = ref('')
const price = ref<number | null>(null)
const stock = ref<number | null>(null)
const description = ref('')
const imageFile = ref<File | null>(null)

const submitting = ref(false)
const errorMessage = ref('')

const handleSubmit = async () => {
  errorMessage.value = ''
  if (!name.value || price.value === null || stock.value === null) {
    errorMessage.value = '상품명, 가격, 재고는 필수입니다.'
    return
  }

  submitting.value = true
  try {
    let imageUrl: string | null = null
    if (imageFile.value) imageUrl = await uploadProductImage(imageFile.value)

    await createProduct({
      name: name.value,
      description: description.value,
      price: price.value,
      stock: stock.value,
      category: category.value,
      imageUrl
    })

    await router.push('/admin/products')
  } catch (e: any) {
    errorMessage.value = e?.message ?? '상품 등록에 실패했습니다.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div>
    <NuxtLink to="/admin/products" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">
      ← 상품 목록으로
    </NuxtLink>
    <h1 class="mb-6 text-2xl font-bold text-gray-900">상품 등록</h1>
    <AdminProductForm
      v-model:name="name"
      v-model:category="category"
      v-model:price="price"
      v-model:stock="stock"
      v-model:description="description"
      v-model:image-file="imageFile"
      submit-label="등록하기"
      :submitting="submitting"
      :error-message="errorMessage"
      @submit="handleSubmit"
    />
  </div>
</template>
