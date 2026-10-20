import type { Category, MenuItem } from './lib/supabase'

export type MenuSeedItem = MenuItem & {
  variation_ar?: string[]
  needs_review: boolean
  review_note_ar?: string
  source_page: 1 | 2
}

export const initialCategories: Category[] = [
  { id: 'pizza', name_ar: 'بيتزا', slug: 'pizza', sort_order: 1 },
  { id: 'salads', name_ar: 'سلطات وإضافات', slug: 'salads', sort_order: 2 },
  { id: 'pizza-sandwiches', name_ar: 'ساندوتش بيتزا', slug: 'pizza-sandwiches', sort_order: 3 },
  { id: 'rice-pasta', name_ar: 'المعجنات والأرز', slug: 'rice-pasta', sort_order: 4 },
  { id: 'crepes', name_ar: 'كريب', slug: 'crepes', sort_order: 5 },
  { id: 'potatoes', name_ar: 'بطاطس', slug: 'potatoes', sort_order: 6 },
  { id: 'pizza-addons', name_ar: 'إضافات البيتزا', slug: 'pizza-addons', sort_order: 7 },
  { id: 'tortilla', name_ar: 'تورتيلا', slug: 'tortilla', sort_order: 8 },
  { id: 'sides', name_ar: 'أصناف جانبية', slug: 'sides', sort_order: 9 },
  { id: 'drinks', name_ar: 'مشروبات', slug: 'drinks', sort_order: 10 },
  { id: 'combos', name_ar: 'إضافات كومبو', slug: 'combos', sort_order: 11 },
  { id: 'kids', name_ar: 'ساندوتشات الأطفال', slug: 'kids', sort_order: 12 },
  { id: 'meals', name_ar: 'وجبات', slug: 'meals', sort_order: 13 },
  { id: 'chicken-sandwiches', name_ar: 'ساندوتشات الدجاج', slug: 'chicken-sandwiches', sort_order: 14 },
  { id: 'meat-sandwiches', name_ar: 'ساندوتشات اللحوم', slug: 'meat-sandwiches', sort_order: 15 },
  { id: 'chicken-fries', name_ar: 'فرايز', slug: 'chicken-fries', sort_order: 16 },
]

const row = (id: string, category_id: string, name_ar: string, price_egp: number, source_page: 1 | 2, extra: Partial<MenuSeedItem> = {}): MenuSeedItem => ({
  id, category_id, name_ar, price_egp, source_page, variation_ar: [], image_path: null,
  description_ar: null, is_published: true, is_available: true, is_demo: false,
  needs_review: false, ...extra,
})
const unclear = (id: string, category: string, price: number, page: 1 | 2, section: string) => row(id, category, `اسم غير مقروء — ${section} ${id.split('-').at(-1)}`, price, page, { needs_review: true, review_note_ar: 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.' })

// Faithful local design-review transcription of both supplied menu pages.
// Repeated crepe entries were deduplicated; rows with blurred names keep their visible price and review flag.
export const initialItems: MenuSeedItem[] = [
  // Page 2: pizza (8)
  row('p2-pizza-jamaica', 'pizza', 'جامايكا', 200, 2, { description_ar: 'قطع شاورما الدجاج، موزاريلا، صوص توفيق الخاص، خضروات', is_featured: true }),
  row('p2-pizza-chicken-ranch', 'pizza', 'تشيكن رانش', 215, 2, { description_ar: 'قطع شاورما الدجاج، موزاريلا، صوص الرانش، خضروات', is_featured: true }),
  row('p2-pizza-burger', 'pizza', 'بيتزا برجر', 250, 2, { is_featured: true }),
  row('p2-pizza-chicken-snacks', 'pizza', 'تشيكن سناكس', 200, 2, { description_ar: 'قطع الدجاج المقرمش، تركي مدخن، موزاريلا، صوص توفيق الخاص، خضروات', is_featured: true }),
  row('p2-pizza-sausage', 'pizza', 'بيتزا سوسيس', 150, 2, { description_ar: 'قطع السوسيس، موزاريلا، صوص توفيق الخاص، خضروات' }),
  row('p2-pizza-pepperoni', 'pizza', 'بيتزا بيبروني', 180, 2, { description_ar: 'بيبروني مدخن، موزاريلا، صوص توفيق الخاص، خضروات' }),
  row('p2-pizza-milano', 'pizza', 'ميلانو', 200, 2),
  row('p2-pizza-mix-cheese', 'pizza', 'ميكس تشيز', 130, 2, { description_ar: 'خليط من أنواع الجبنة، صوص توفيق الخاص، خضروات' }),

  // Page 2: salads, sauces and additions (14)
  row('p2-salad-caesar', 'salads', 'تشيكن سيزر سلاد', 110, 2, { description_ar: 'صدور بالأعشاب، جبنة بارميزان، صوص سيزر' }),
  row('p2-salad-tawfeek', 'salads', 'توفيق سلاد', 100, 2, { description_ar: 'تركي مدخن، سلامي، صوص توفيق الخاص' }),
  row('p2-salad-greek', 'salads', 'جريك سلاد', 90, 2),
  row('p2-salad-green', 'salads', 'جرين سلاد', 50, 2),
  row('p2-salad-coleslaw', 'salads', 'كول سلو', 50, 2),
  row('p2-sauce-cocktail', 'salads', 'صوص كوكتيل', 25, 2),
  row('p2-sauce-spicy', 'salads', 'صوص سبايسي', 25, 2),
  row('p2-sauce-ranch', 'salads', 'صوص رانش', 25, 2),
  row('p2-sauce-bbq', 'salads', 'صوص باربيكيو', 25, 2),
  row('p2-sauce-garlic', 'salads', 'صوص تومية', 25, 2),
  row('p2-sauce-mayo', 'salads', 'صوص مايونيز', 25, 2),
  row('p2-pickles', 'salads', 'مخلل', 20, 2),
  row('p2-jalapeno', 'salads', 'فلفل هالبينو', 25, 2),
  row('p2-sauce-sweet-chili', 'salads', 'صوص سويت شيلي', 25, 2),

  // Page 2: pizza sandwiches (4)
  row('p2-pizza-sandwich-beef-burger', 'pizza-sandwiches', 'برجر بيتزا بيف', 140, 2),
  row('p2-pizza-sandwich-chicken-burger', 'pizza-sandwiches', 'برجر بيتزا تشيكن', 140, 2),
  row('p2-pizza-sandwich-chicken', 'pizza-sandwiches', 'تشيكن بيتزا ساندوتش', 130, 2),
  row('p2-pizza-sandwich-beef', 'pizza-sandwiches', 'بيف بيتزا ساندوتش', 130, 2),

  // Page 2: pasta and rice (7)
  row('p2-pasta-bechamel', 'rice-pasta', 'مكرونة بشاميل', 120, 2),
  row('p2-pasta-chicken-negrisco', 'rice-pasta', 'نجرسكو دجاج', 120, 2),
  row('p2-rice-plain', 'rice-pasta', 'أرز', 50, 2),
  row('p2-rice-chicken-shawarma', 'rice-pasta', 'أرز شاورما دجاج', 110, 2),
  row('p2-rice-shish', 'rice-pasta', 'أرز شيش', 120, 2),
  row('p2-rice-kofta', 'rice-pasta', 'أرز كفتة', 120, 2),
  row('p2-rice-sausage', 'rice-pasta', 'أرز سجق', 120, 2),

  // Page 2: crepes (8; duplicate references in page 1 omitted)
  row('p2-crepe-mix', 'crepes', 'كريب ميكس', 150, 2),
  row('p2-crepe-mexican', 'crepes', 'كريب ماكسيكان', 110, 2),
  row('p2-crepe-mix-chicken', 'crepes', 'كريب ميكس تشيكن', 170, 2),
  row('p2-crepe-steak-fajita', 'crepes', 'كريب ستيك فاهيتا', 135, 2, { needs_review: true, review_note_ar: 'قراءة كلمة الحشو غير مؤكدة من الصورة منخفضة الدقة.' }),
  row('p2-crepe-chicken', 'crepes', 'كريب تشيكن', 180, 2, { needs_review: true, review_note_ar: 'اسم الحشو بعد كلمة تشيكن غير واضح.' }),
  row('p2-crepe-grilled', 'crepes', 'كريب جريل', 130, 2),
  row('p2-crepe-kofta', 'crepes', 'كريب كفتة', 125, 2),
  row('p2-crepe-potato', 'crepes', 'كريب بطاطس', 85, 2),

  // Page 2: potato sandwiches (the potato crepe above is the same listed item)
  row('p2-potato-sandwich', 'potatoes', 'ساندوتش بطاطس', 65, 2),
  row('p2-crust-addition', 'pizza-addons', 'ساند كرست (إضافة حشو أطراف)', 65, 2),

  // Page 1: tortilla (3 names unreadable at supplied resolution)
  unclear('p1-tortilla-1', 'tortilla', 130, 1, 'تورتيلا'),
  unclear('p1-tortilla-2', 'tortilla', 130, 1, 'تورتيلا'),
  unclear('p1-tortilla-3', 'tortilla', 120, 1, 'تورتيلا'),

  // Page 1: side dishes (7; the names are blurred, prices are legible)
  unclear('p1-side-1', 'sides', 115, 1, 'أصناف جانبية'),
  unclear('p1-side-2', 'sides', 85, 1, 'أصناف جانبية'),
  unclear('p1-side-3', 'sides', 100, 1, 'أصناف جانبية'),
  unclear('p1-side-4', 'sides', 70, 1, 'أصناف جانبية'),
  unclear('p1-side-5', 'sides', 50, 1, 'أصناف جانبية'),
  unclear('p1-side-6', 'sides', 40, 1, 'أصناف جانبية'),
  unclear('p1-side-7', 'sides', 60, 1, 'أصناف جانبية'),

  // Page 1: drinks (4)
  row('p1-drink-pepsi-mango', 'drinks', 'بيبسي مانجو', 35, 1, { needs_review: true, review_note_ar: 'الاسم ظاهر جزئياً؛ يرجى التأكد من نوع المشروب.' }),
  unclear('p1-drink-2', 'drinks', 20, 1, 'مشروبات'),
  row('p1-drink-water', 'drinks', 'مياه معدنية', 10, 1),
  row('p1-drink-juice', 'drinks', 'عصير', 15, 1),

  // Page 1: combo add-on and kids sandwich
  row('p1-combo-addition', 'combos', 'إضافة كومبو', 83, 1, { variation_ar: ['إضافة كومبو'] }),
  row('p1-kids-sandwich', 'kids', 'ساندوتش الأطفال', 125, 1, { variation_ar: ['كبدة سوسيس', 'كبدة برجر لحم', 'كبدة برجر دجاج'] }),

  // Page 1: meals (9)
  row('p1-meal-mix-grill-270', 'meals', 'ميكس جريل', 270, 1, { needs_review: true, review_note_ar: 'الصفة أو حجم الوجبة غير واضح.' }),
  row('p1-meal-tandoori', 'meals', 'دجاج تندوري', 205, 1),
  row('p1-meal-chicken-tawook', 'meals', 'تشيكن طاووق', 205, 1),
  unclear('p1-meal-4', 'meals', 250, 1, 'وجبات'),
  row('p1-meal-beef-kofta', 'meals', 'كفتة لحم', 200, 1),
  row('p1-meal-chicken-kofta', 'meals', 'كفتة دجاج', 200, 1),
  row('p1-meal-mix-grill-250', 'meals', 'ميكس جريل', 250, 1, { needs_review: true, review_note_ar: 'التفصيل المميز للصنف غير واضح.' }),
  row('p1-meal-mix-shish-tawook', 'meals', 'ميكس شيش طاووق', 220, 1),
  row('p1-meal-half-chicken', 'meals', 'نصف دجاج محمر', 175, 1),

  // Page 1: chicken sandwiches (11)
  row('p1-chicken-big-crispy', 'chicken-sandwiches', 'بيج كرسبي تشيكن', 130, 1),
  row('p1-chicken-maya-crispy', 'chicken-sandwiches', 'مايا كرسبي تشيكن', 110, 1, { needs_review: true, review_note_ar: 'الاسم مركب بخط منخفض الوضوح.' }),
  unclear('p1-chicken-sandwich-3', 'chicken-sandwiches', 135, 1, 'ساندوتشات الدجاج'),
  row('p1-chicken-super-crunchy', 'chicken-sandwiches', 'سوبر كرانشي', 135, 1),
  row('p1-chicken-fajita', 'chicken-sandwiches', 'تشيكن فاهيتا', 110, 1),
  row('p1-chicken-shawarma', 'chicken-sandwiches', 'تشيكن شاورما', 110, 1),
  unclear('p1-chicken-sandwich-7', 'chicken-sandwiches', 120, 1, 'ساندوتشات الدجاج'),
  unclear('p1-chicken-sandwich-8', 'chicken-sandwiches', 120, 1, 'ساندوتشات الدجاج'),
  unclear('p1-chicken-sandwich-9', 'chicken-sandwiches', 135, 1, 'ساندوتشات الدجاج'),
  row('p1-chicken-burger', 'chicken-sandwiches', 'برجر دجاج', 70, 1, { needs_review: true, review_note_ar: 'الوصف الملحق بالاسم غير واضح.' }),
  row('p1-chicken-kofta-sandwich', 'chicken-sandwiches', 'كفتة دجاج', 110, 1),

  // Page 1: meat sandwiches (6)
  unclear('p1-meat-sandwich-1', 'meat-sandwiches', 155, 1, 'ساندوتشات اللحوم'),
  unclear('p1-meat-sandwich-2', 'meat-sandwiches', 170, 1, 'ساندوتشات اللحوم'),
  row('p1-chili-burger', 'meat-sandwiches', 'تشيلي برجر', 130, 1),
  row('p1-beef-burger', 'meat-sandwiches', 'بيف برجر', 70, 1),
  row('p1-grilled-kofta-sandwich', 'meat-sandwiches', 'كفتة مشوية', 110, 1),
  row('p1-sausage-sandwich', 'meat-sandwiches', 'سوسيس', 60, 1),

  // Page 1: chicken fries (1)
  row('p1-chicken-fries', 'chicken-fries', 'متشكن فرايز', 120, 1, { needs_review: true, review_note_ar: 'التهجئة وشرح الطبق يحتاجان مراجعة من الأصل.' }),
]
