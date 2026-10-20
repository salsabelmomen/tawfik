-- REVIEW ONLY: prepared from src/data.ts; this file has not been executed.
-- Uses categories.slug (unique) and menu category + exact name + price for duplicate detection. No UPDATE/DELETE.
-- Stable UUIDs derive from local source ids; the local text IDs are never cast to UUID.
-- Rows needing review are inserted with is_published=false. Review note and variations are retained.
-- source_page is local provenance and is not written because the schema has no column for it.
-- Read-only schema guard: stop before writes unless the expected migrated columns and slug uniqueness exist.
DO $preflight$
DECLARE missing_columns text;
BEGIN
  SELECT string_agg(required.table_name || '.' || required.column_name, ', ') INTO missing_columns
  FROM (VALUES
    ('categories','id'), ('categories','name_ar'), ('categories','slug'), ('categories','sort_order'),
    ('menu_items','id'), ('menu_items','category_id'), ('menu_items','name_ar'), ('menu_items','price_egp'),
    ('menu_items','description_ar'), ('menu_items','image_path'), ('menu_items','is_published'), ('menu_items','is_available'),
    ('menu_items','is_demo'), ('menu_items','is_featured'), ('menu_items','needs_review'), ('menu_items','review_note_ar'), ('menu_items','variation_ar')
  ) AS required(table_name, column_name)
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = required.table_name AND c.column_name = required.column_name
  );
  IF missing_columns IS NOT NULL THEN
    RAISE EXCEPTION 'Seed stopped: required schema columns are missing: %', missing_columns;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='categories' AND indexdef ILIKE '%UNIQUE%(slug)%') THEN
    RAISE EXCEPTION 'Seed stopped: public.categories.slug is not backed by a unique index';
  END IF;
END $preflight$;

BEGIN;

-- Add only missing categories; an existing slug and its data are left unchanged.
INSERT INTO public.categories (name_ar, slug, sort_order) VALUES
  ('بيتزا', 'pizza', 1),
  ('سلطات وإضافات', 'salads', 2),
  ('ساندوتش بيتزا', 'pizza-sandwiches', 3),
  ('المعجنات والأرز', 'rice-pasta', 4),
  ('كريب', 'crepes', 5),
  ('بطاطس', 'potatoes', 6),
  ('إضافات البيتزا', 'pizza-addons', 7),
  ('تورتيلا', 'tortilla', 8),
  ('أصناف جانبية', 'sides', 9),
  ('مشروبات', 'drinks', 10),
  ('إضافات كومبو', 'combos', 11),
  ('ساندوتشات الأطفال', 'kids', 12),
  ('وجبات', 'meals', 13),
  ('ساندوتشات الدجاج', 'chicken-sandwiches', 14),
  ('ساندوتشات اللحوم', 'meat-sandwiches', 15),
  ('فرايز', 'chicken-fries', 16)
ON CONFLICT (slug) DO NOTHING;

-- Resolve category UUIDs by slug and insert rows not already present by exact category/name/price.
WITH seed (source_id, category_slug, category_name_ar, name_ar, price_egp, description_ar, image_path, is_published, is_available, is_demo, is_featured, needs_review, review_note_ar, variation_ar) AS (
  VALUES
    ('p2-pizza-jamaica', 'pizza', 'بيتزا', 'جامايكا', 200, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-chicken-ranch', 'pizza', 'بيتزا', 'تشيكن رانش', 215, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-burger', 'pizza', 'بيتزا', 'بيتزا برجر', 250, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-chicken-snacks', 'pizza', 'بيتزا', 'تشيكن سناكس', 200, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-sausage', 'pizza', 'بيتزا', 'بيتزا سوسيس', 150, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-pepperoni', 'pizza', 'بيتزا', 'بيتزا بيبروني', 180, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-milano', 'pizza', 'بيتزا', 'ميلانو', 200, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-mix-cheese', 'pizza', 'بيتزا', 'ميكس تشيز', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-salad-caesar', 'salads', 'سلطات وإضافات', 'تشيكن سيزر سلاد', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-salad-tawfeek', 'salads', 'سلطات وإضافات', 'توفيق سلاد', 100, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-salad-greek', 'salads', 'سلطات وإضافات', 'جريك سلاد', 90, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-salad-green', 'salads', 'سلطات وإضافات', 'جرين سلاد', 50, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-salad-coleslaw', 'salads', 'سلطات وإضافات', 'كول سلو', 50, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-cocktail', 'salads', 'سلطات وإضافات', 'صوص كوكتيل', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-spicy', 'salads', 'سلطات وإضافات', 'صوص سبايسي', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-ranch', 'salads', 'سلطات وإضافات', 'صوص رانش', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-bbq', 'salads', 'سلطات وإضافات', 'صوص باربيكيو', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-garlic', 'salads', 'سلطات وإضافات', 'صوص تومية', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-mayo', 'salads', 'سلطات وإضافات', 'صوص مايونيز', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pickles', 'salads', 'سلطات وإضافات', 'مخلل', 20, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-jalapeno', 'salads', 'سلطات وإضافات', 'فلفل هالبينو', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-sauce-sweet-chili', 'salads', 'سلطات وإضافات', 'صوص سويت شيلي', 25, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-sandwich-beef-burger', 'pizza-sandwiches', 'ساندوتش بيتزا', 'برجر بيتزا بيف', 140, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-sandwich-chicken-burger', 'pizza-sandwiches', 'ساندوتش بيتزا', 'برجر بيتزا تشيكن', 140, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-sandwich-chicken', 'pizza-sandwiches', 'ساندوتش بيتزا', 'تشيكن بيتزا ساندوتش', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pizza-sandwich-beef', 'pizza-sandwiches', 'ساندوتش بيتزا', 'بيف بيتزا ساندوتش', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pasta-bechamel', 'rice-pasta', 'المعجنات والأرز', 'مكرونة بشاميل', 120, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-pasta-chicken-negrisco', 'rice-pasta', 'المعجنات والأرز', 'نجرسكو دجاج', 120, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-rice-plain', 'rice-pasta', 'المعجنات والأرز', 'أرز', 50, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-rice-chicken-shawarma', 'rice-pasta', 'المعجنات والأرز', 'أرز شاورما دجاج', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-rice-shish', 'rice-pasta', 'المعجنات والأرز', 'أرز شيش', 120, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-rice-kofta', 'rice-pasta', 'المعجنات والأرز', 'أرز كفتة', 120, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-rice-sausage', 'rice-pasta', 'المعجنات والأرز', 'أرز سجق', 120, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-mix', 'crepes', 'كريب', 'كريب ميكس', 150, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-mexican', 'crepes', 'كريب', 'كريب ماكسيكان', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-mix-chicken', 'crepes', 'كريب', 'كريب ميكس تشيكن', 170, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-steak-fajita', 'crepes', 'كريب', 'كريب ستيك فاهيتا', 135, NULL, NULL, false, true, false, false, true, 'قراءة كلمة الحشو غير مؤكدة من الصورة منخفضة الدقة.', ARRAY[]::text[]),
    ('p2-crepe-chicken', 'crepes', 'كريب', 'كريب تشيكن', 180, NULL, NULL, false, true, false, false, true, 'اسم الحشو بعد كلمة تشيكن غير واضح.', ARRAY[]::text[]),
    ('p2-crepe-grilled', 'crepes', 'كريب', 'كريب جريل', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-kofta', 'crepes', 'كريب', 'كريب كفتة', 125, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crepe-potato', 'crepes', 'كريب', 'كريب بطاطس', 85, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-potato-sandwich', 'potatoes', 'بطاطس', 'ساندوتش بطاطس', 65, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p2-crust-addition', 'pizza-addons', 'إضافات البيتزا', 'ساند كرست (إضافة حشو أطراف)', 65, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-tortilla-1', 'tortilla', 'تورتيلا', 'اسم غير مقروء — تورتيلا 1', 130, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-tortilla-2', 'tortilla', 'تورتيلا', 'اسم غير مقروء — تورتيلا 2', 130, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-tortilla-3', 'tortilla', 'تورتيلا', 'اسم غير مقروء — تورتيلا 3', 120, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-1', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 1', 115, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-2', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 2', 85, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-3', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 3', 100, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-4', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 4', 70, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-5', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 5', 50, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-6', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 6', 40, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-side-7', 'sides', 'أصناف جانبية', 'اسم غير مقروء — أصناف جانبية 7', 60, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-drink-pepsi-mango', 'drinks', 'مشروبات', 'بيبسي مانجو', 35, NULL, NULL, false, true, false, false, true, 'الاسم ظاهر جزئياً؛ يرجى التأكد من نوع المشروب.', ARRAY[]::text[]),
    ('p1-drink-2', 'drinks', 'مشروبات', 'اسم غير مقروء — مشروبات 2', 20, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-drink-water', 'drinks', 'مشروبات', 'مياه معدنية', 10, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-drink-juice', 'drinks', 'مشروبات', 'عصير', 15, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-combo-addition', 'combos', 'إضافات كومبو', 'إضافة كومبو', 83, NULL, NULL, true, true, false, false, false, NULL, ARRAY['إضافة كومبو']::text[]),
    ('p1-kids-sandwich', 'kids', 'ساندوتشات الأطفال', 'ساندوتش الأطفال', 125, NULL, NULL, true, true, false, false, false, NULL, ARRAY['كبدة سوسيس','كبدة برجر لحم','كبدة برجر دجاج']::text[]),
    ('p1-meal-mix-grill-270', 'meals', 'وجبات', 'ميكس جريل', 270, NULL, NULL, false, true, false, false, true, 'الصفة أو حجم الوجبة غير واضح.', ARRAY[]::text[]),
    ('p1-meal-tandoori', 'meals', 'وجبات', 'دجاج تندوري', 205, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meal-chicken-tawook', 'meals', 'وجبات', 'تشيكن طاووق', 205, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meal-4', 'meals', 'وجبات', 'اسم غير مقروء — وجبات 4', 250, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-meal-beef-kofta', 'meals', 'وجبات', 'كفتة لحم', 200, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meal-chicken-kofta', 'meals', 'وجبات', 'كفتة دجاج', 200, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meal-mix-grill-250', 'meals', 'وجبات', 'ميكس جريل', 250, NULL, NULL, false, true, false, false, true, 'التفصيل المميز للصنف غير واضح.', ARRAY[]::text[]),
    ('p1-meal-mix-shish-tawook', 'meals', 'وجبات', 'ميكس شيش طاووق', 220, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meal-half-chicken', 'meals', 'وجبات', 'نصف دجاج محمر', 175, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-big-crispy', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'بيج كرسبي تشيكن', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-maya-crispy', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'مايا كرسبي تشيكن', 110, NULL, NULL, false, true, false, false, true, 'الاسم مركب بخط منخفض الوضوح.', ARRAY[]::text[]),
    ('p1-chicken-sandwich-3', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'اسم غير مقروء — ساندوتشات الدجاج 3', 135, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-chicken-super-crunchy', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'سوبر كرانشي', 135, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-fajita', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'تشيكن فاهيتا', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-shawarma', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'تشيكن شاورما', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-sandwich-7', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'اسم غير مقروء — ساندوتشات الدجاج 7', 120, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-chicken-sandwich-8', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'اسم غير مقروء — ساندوتشات الدجاج 8', 120, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-chicken-sandwich-9', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'اسم غير مقروء — ساندوتشات الدجاج 9', 135, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-chicken-burger', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'برجر دجاج', 70, NULL, NULL, false, true, false, false, true, 'الوصف الملحق بالاسم غير واضح.', ARRAY[]::text[]),
    ('p1-chicken-kofta-sandwich', 'chicken-sandwiches', 'ساندوتشات الدجاج', 'كفتة دجاج', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-meat-sandwich-1', 'meat-sandwiches', 'ساندوتشات اللحوم', 'اسم غير مقروء — ساندوتشات اللحوم 1', 155, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-meat-sandwich-2', 'meat-sandwiches', 'ساندوتشات اللحوم', 'اسم غير مقروء — ساندوتشات اللحوم 2', 170, NULL, NULL, false, true, false, false, true, 'يرجى مراجعة صورة المنيو الأصلية وتأكيد الاسم قبل النشر.', ARRAY[]::text[]),
    ('p1-chili-burger', 'meat-sandwiches', 'ساندوتشات اللحوم', 'تشيلي برجر', 130, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-beef-burger', 'meat-sandwiches', 'ساندوتشات اللحوم', 'بيف برجر', 70, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-grilled-kofta-sandwich', 'meat-sandwiches', 'ساندوتشات اللحوم', 'كفتة مشوية', 110, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-sausage-sandwich', 'meat-sandwiches', 'ساندوتشات اللحوم', 'سوسيس', 60, NULL, NULL, true, true, false, false, false, NULL, ARRAY[]::text[]),
    ('p1-chicken-fries', 'chicken-fries', 'فرايز', 'متشكن فرايز', 120, NULL, NULL, false, true, false, false, true, 'التهجئة وشرح الطبق يحتاجان مراجعة من الأصل.', ARRAY[]::text[])
), mapped AS (
  SELECT (substr(md5('wesaya-menu-seed-v1:' || seed.source_id),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:' || seed.source_id),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:' || seed.source_id),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:' || seed.source_id),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:' || seed.source_id),21,12))::uuid AS id, categories.id AS category_id, seed.*
  FROM seed JOIN public.categories ON categories.slug = seed.category_slug AND categories.name_ar = seed.category_name_ar
)
INSERT INTO public.menu_items (id, category_id, name_ar, price_egp, description_ar, image_path, is_published, is_available, is_demo, is_featured, needs_review, review_note_ar, variation_ar)
SELECT id, category_id, name_ar, price_egp, description_ar, image_path, is_published, is_available, is_demo, is_featured, needs_review, review_note_ar, variation_ar FROM mapped
WHERE NOT EXISTS (SELECT 1 FROM public.menu_items e WHERE e.category_id=mapped.category_id AND e.name_ar=mapped.name_ar AND e.price_egp IS NOT DISTINCT FROM mapped.price_egp)
ON CONFLICT (id) DO NOTHING;

-- Verify resulting seed IDs and review/publication state before considering the import complete.
SELECT count(*) AS total_seed_ids, count(*) FILTER (WHERE needs_review AND NOT is_published) AS review_unpublished, count(*) FILTER (WHERE NOT needs_review AND is_published AND is_available) AS verified_published
FROM public.menu_items WHERE id IN (
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-jamaica'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-jamaica'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-jamaica'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-jamaica'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-jamaica'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-ranch'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-ranch'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-ranch'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-ranch'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-ranch'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-snacks'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-snacks'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-snacks'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-snacks'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-chicken-snacks'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-sausage'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sausage'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sausage'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sausage'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sausage'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-pepperoni'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-pepperoni'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-pepperoni'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-pepperoni'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-pepperoni'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-milano'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-milano'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-milano'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-milano'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-milano'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-mix-cheese'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-mix-cheese'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-mix-cheese'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-mix-cheese'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-mix-cheese'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-salad-caesar'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-caesar'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-caesar'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-caesar'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-caesar'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-salad-tawfeek'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-tawfeek'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-tawfeek'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-tawfeek'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-tawfeek'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-salad-greek'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-greek'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-greek'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-greek'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-greek'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-salad-green'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-green'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-green'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-green'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-green'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-salad-coleslaw'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-coleslaw'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-coleslaw'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-coleslaw'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-salad-coleslaw'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-cocktail'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-cocktail'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-cocktail'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-cocktail'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-cocktail'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-spicy'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-spicy'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-spicy'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-spicy'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-spicy'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-ranch'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-ranch'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-ranch'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-ranch'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-ranch'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-bbq'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-bbq'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-bbq'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-bbq'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-bbq'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-garlic'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-garlic'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-garlic'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-garlic'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-garlic'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-mayo'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-mayo'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-mayo'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-mayo'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-mayo'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pickles'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pickles'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pickles'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pickles'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pickles'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-jalapeno'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-jalapeno'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-jalapeno'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-jalapeno'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-jalapeno'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-sauce-sweet-chili'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-sweet-chili'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-sweet-chili'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-sweet-chili'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-sauce-sweet-chili'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-chicken'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pizza-sandwich-beef'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pasta-bechamel'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-bechamel'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-bechamel'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-bechamel'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-bechamel'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-pasta-chicken-negrisco'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-chicken-negrisco'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-chicken-negrisco'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-chicken-negrisco'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-pasta-chicken-negrisco'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-rice-plain'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-plain'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-plain'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-plain'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-plain'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-rice-chicken-shawarma'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-chicken-shawarma'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-chicken-shawarma'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-chicken-shawarma'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-chicken-shawarma'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-rice-shish'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-shish'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-shish'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-shish'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-shish'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-rice-kofta'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-kofta'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-kofta'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-kofta'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-kofta'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-rice-sausage'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-sausage'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-sausage'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-sausage'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-rice-sausage'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-mix'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-mexican'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mexican'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mexican'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mexican'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mexican'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-mix-chicken'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix-chicken'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix-chicken'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix-chicken'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-mix-chicken'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-steak-fajita'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-steak-fajita'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-steak-fajita'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-steak-fajita'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-steak-fajita'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-chicken'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-chicken'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-chicken'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-chicken'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-chicken'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-grilled'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-grilled'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-grilled'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-grilled'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-grilled'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-kofta'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-kofta'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-kofta'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-kofta'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-kofta'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crepe-potato'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-potato'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-potato'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-potato'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crepe-potato'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-potato-sandwich'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-potato-sandwich'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-potato-sandwich'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-potato-sandwich'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-potato-sandwich'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p2-crust-addition'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crust-addition'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crust-addition'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crust-addition'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p2-crust-addition'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-tortilla-1'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-1'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-1'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-1'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-1'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-tortilla-2'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-2'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-2'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-2'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-2'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-tortilla-3'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-3'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-3'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-3'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-tortilla-3'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-1'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-1'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-1'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-1'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-1'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-2'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-2'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-2'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-2'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-2'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-3'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-3'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-3'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-3'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-3'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-4'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-4'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-4'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-4'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-4'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-5'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-5'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-5'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-5'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-5'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-6'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-6'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-6'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-6'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-6'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-side-7'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-7'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-7'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-7'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-side-7'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-drink-pepsi-mango'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-pepsi-mango'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-pepsi-mango'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-pepsi-mango'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-pepsi-mango'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-drink-2'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-2'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-2'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-2'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-2'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-drink-water'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-water'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-water'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-water'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-water'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-drink-juice'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-juice'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-juice'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-juice'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-drink-juice'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-combo-addition'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-combo-addition'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-combo-addition'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-combo-addition'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-combo-addition'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-kids-sandwich'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-kids-sandwich'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-kids-sandwich'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-kids-sandwich'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-kids-sandwich'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-270'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-270'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-270'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-270'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-270'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-tandoori'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-tandoori'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-tandoori'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-tandoori'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-tandoori'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-tawook'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-tawook'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-tawook'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-tawook'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-tawook'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-4'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-4'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-4'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-4'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-4'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-beef-kofta'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-beef-kofta'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-beef-kofta'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-beef-kofta'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-beef-kofta'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-kofta'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-kofta'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-kofta'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-kofta'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-chicken-kofta'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-250'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-250'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-250'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-250'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-grill-250'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-mix-shish-tawook'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-shish-tawook'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-shish-tawook'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-shish-tawook'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-mix-shish-tawook'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meal-half-chicken'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-half-chicken'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-half-chicken'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-half-chicken'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meal-half-chicken'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-big-crispy'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-big-crispy'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-big-crispy'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-big-crispy'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-big-crispy'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-maya-crispy'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-maya-crispy'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-maya-crispy'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-maya-crispy'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-maya-crispy'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-3'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-3'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-3'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-3'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-3'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-super-crunchy'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-super-crunchy'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-super-crunchy'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-super-crunchy'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-super-crunchy'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-fajita'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fajita'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fajita'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fajita'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fajita'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-shawarma'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-shawarma'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-shawarma'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-shawarma'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-shawarma'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-7'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-7'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-7'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-7'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-7'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-8'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-8'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-8'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-8'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-8'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-9'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-9'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-9'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-9'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-sandwich-9'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-kofta-sandwich'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-kofta-sandwich'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-kofta-sandwich'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-kofta-sandwich'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-kofta-sandwich'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-1'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-1'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-1'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-1'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-1'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-2'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-2'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-2'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-2'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-meat-sandwich-2'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chili-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chili-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chili-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chili-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chili-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-beef-burger'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-beef-burger'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-beef-burger'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-beef-burger'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-beef-burger'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-grilled-kofta-sandwich'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-grilled-kofta-sandwich'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-grilled-kofta-sandwich'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-grilled-kofta-sandwich'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-grilled-kofta-sandwich'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-sausage-sandwich'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-sausage-sandwich'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-sausage-sandwich'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-sausage-sandwich'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-sausage-sandwich'),21,12))::uuid,
  (substr(md5('wesaya-menu-seed-v1:p1-chicken-fries'),1,8)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fries'),9,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fries'),13,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fries'),17,4)||'-'||substr(md5('wesaya-menu-seed-v1:p1-chicken-fries'),21,12))::uuid
);
COMMIT;
