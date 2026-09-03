<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const router = useRouter()
const { fetchProductById, updateProduct, uploadProductImage, deleteProduct } = useProducts()

const productId = route.params.id as string

const name = ref('')
const category = ref('')
const price = ref<number | null>(null)
const stock = ref<number | null>(null)
const description = ref('')
const imageFile = ref<File | null>(null)
const existingImageUrl = ref<string | null>(null)

const loading = ref(true)
const submitting = ref(false)
const errorMessage = ref('')

onMounted(async () => {
  try {
    const product = await fetchProductById(productId)
    name.value = product.name
    category.value = product.category ?? ''
    price.value = product.price
    stock.value = product.stock
    description.value = product.description ?? ''
    existingImageUrl.value = product.image_url
  } finally {
    loading.value = false
  }
})

const handleSubmit = async () => {
  errorMessage.value = ''
  if (!name.value || price.value === null || stock.value === null) {
    errorMessage.value = '상품명, 가격, 재고는 필수입니다.'
    return
  }

  submitting.value = true
  try {
    let imageUrl: string | undefined
    if (imageFile.value) imageUrl = await uploadProductImage(imageFile.value)

    await updateProduct(productId, {
      name: name.value,
      description: description.value,
      price: price.value,
      stock: stock.value,
      category: category.value,
      ...(imageUrl !== undefined && { imageUrl })
    })

    await router.push('/admin/products')
  } catch (e: any) {
    errorMessage.value = e?.message ?? '상품 수정에 실패했습니다.'
  } finally {
    submitting.value = false
  }
}

const handleDelete = async () => {
  submitting.value = true
  try {
    await deleteProduct(productId)
    await router.push('/admin/products')
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
    <h1 class="mb-6 text-2xl font-bold text-gray-900">상품 수정</h1>

    <p v-if="loading" class="py-8 text-sm text-gray-400">불러오는 중...</p>

    <template v-else>
      <AdminProductForm
        v-model:name="name"
        v-model:category="category"
        v-model:price="price"
        v-model:stock="stock"
        v-model:description="description"
        v-model:image-file="imageFile"
        :existing-image-url="existingImageUrl"
        submit-label="수정하기"
        :submitting="submitting"
        :error-message="errorMessage"
        @submit="handleSubmit"
      />
      <button type="button" class="mt-4 text-sm text-red-500 hover:underline" :disabled="submitting" @click="handleDelete">
        이 상품 삭제하기
      </button>
    </template>
  </div>
</template>
