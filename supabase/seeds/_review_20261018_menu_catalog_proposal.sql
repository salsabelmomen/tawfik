-- REVIEW ONLY: generated from supabase/seeds/20261018_menu_catalog_review.sql.
-- Do not run until reviewed and explicitly approved. No source or migration was changed.
-- One DO statement: an uncaught validation exception aborts this statement's transaction.
DO $seed$
DECLARE
  v_missing_columns text;
  v_categories integer;
  v_items integer;
  v_review integer;
  v_new_categories integer := 0;
  v_new_items integer := 0;
  v_conflicts integer;
  v_missing_links integer;
BEGIN
  -- Serializes runs that use this same advisory lock; unrelated writers are not covered.
  PERFORM pg_advisory_xact_lock(20261018, 1);

  SELECT string_agg(r.table_name || '.' || r.column_name, ', ')
    INTO v_missing_columns
  FROM (VALUES
    ('categories','id'), ('categories','name_ar'), ('categories','slug'), ('categories','sort_order'),
    ('menu_items','id'), ('menu_items','category_id'), ('menu_items','name_ar'), ('menu_items','price_egp'),
    ('menu_items','description_ar'), ('menu_items','image_path'), ('menu_items','is_published'),
    ('menu_items','is_available'), ('menu_items','is_demo'), ('menu_items','is_featured'),
    ('menu_items','needs_review'), ('menu_items','review_note_ar'), ('menu_items','variation_ar')
  ) AS r(table_name, column_name)
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=r.table_name AND c.column_name=r.column_name
  );
  IF v_missing_columns IS NOT NULL THEN
    RAISE EXCEPTION 'Seed stopped: missing columns: %', v_missing_columns;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_index i
    JOIN pg_class t ON t.oid=i.indrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='public' AND t.relname='categories'
      AND i.indisunique AND i.indisvalid AND i.indpred IS NULL
      AND i.indnkeyatts=1
      AND pg_get_indexdef(i.indexrelid, 1, true)='slug'
  ) THEN
    RAISE EXCEPTION 'Seed stopped: no valid full unique index on categories.slug alone';
  END IF;

  CREATE TEMP TABLE seed_categories (
    name_ar text NOT NULL, slug text PRIMARY KEY, sort_order integer NOT NULL
  ) ON COMMIT DROP;
  INSERT INTO seed_categories (name_ar, slug, sort_order) VALUES
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
  ('فرايز', 'chicken-fries', 16);

  CREATE TEMP TABLE seed_items (
    source_id text PRIMARY KEY,
    category_slug text NOT NULL,
    category_name_ar text NOT NULL,
    name_ar text NOT NULL,
    price_egp numeric NOT NULL,
    description_ar text,
    image_path text,
    is_published boolean NOT NULL,
    is_available boolean NOT NULL,
    is_demo boolean NOT NULL,
    is_featured boolean NOT NULL,
    needs_review boolean NOT NULL,
    review_note_ar text,
    variation_ar text[] NOT NULL
  ) ON COMMIT DROP;
  INSERT INTO seed_items (
    source_id, category_slug, category_name_ar, name_ar, price_egp,
    description_ar, image_path, is_published, is_available, is_demo,
    is_featured, needs_review, review_note_ar, variation_ar
  ) VALUES
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
    ('p1-chicken-fries', 'chicken-fries', 'فرايز', 'متشكن فرايز', 120, NULL, NULL, false, true, false, false, true, 'التهجئة وشرح الطبق يحتاجان مراجعة من الأصل.', ARRAY[]::text[]);

  SELECT count(*) INTO v_categories FROM seed_categories;
  SELECT count(*) INTO v_items FROM seed_items;
  SELECT count(*) INTO v_review FROM seed_items WHERE needs_review;
  IF v_categories <> 16 OR v_items <> 86 OR v_review <> 26 THEN
    RAISE EXCEPTION 'Source counts unexpected: categories %, items %, review %', v_categories, v_items, v_review;
  END IF;
  IF EXISTS (SELECT 1 FROM seed_items WHERE needs_review AND is_published) THEN
    RAISE EXCEPTION 'Source contains a review row marked published';
  END IF;

  INSERT INTO public.categories (name_ar, slug, sort_order)
  SELECT name_ar, slug, sort_order FROM seed_categories
  ON CONFLICT (slug) DO NOTHING;
  GET DIAGNOSTICS v_new_categories = ROW_COUNT;

  SELECT count(*) INTO v_categories
  FROM seed_categories s JOIN public.categories c
    ON c.slug=s.slug AND c.name_ar=s.name_ar AND c.sort_order=s.sort_order;
  IF v_categories <> 16 THEN
    RAISE EXCEPTION 'Category mismatch: only % of 16 rows match slug/name/order', v_categories;
  END IF;

  SELECT count(*) INTO v_missing_links
  FROM seed_items s LEFT JOIN public.categories c
    ON c.slug=s.category_slug AND c.name_ar=s.category_name_ar
  WHERE c.id IS NULL;
  IF v_missing_links <> 0 THEN
    RAISE EXCEPTION 'Missing category links: %', v_missing_links;
  END IF;

  -- A candidate is either the deterministic UUID or same category/name/price.
  -- Any non-exact candidate or multiple candidate records is a hard conflict.
  SELECT count(*) INTO v_conflicts
  FROM seed_items s
  JOIN public.categories c ON c.slug=s.category_slug AND c.name_ar=s.category_name_ar
  CROSS JOIN LATERAL (
    SELECT (substr(md5('wesaya-menu-seed-v1:'||s.source_id),1,8)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),9,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),13,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),17,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),21,12))::uuid AS expected_id
  ) d
  CROSS JOIN LATERAL (
    SELECT count(*) AS candidates,
      count(*) FILTER (WHERE e.category_id=c.id AND e.name_ar=s.name_ar
        AND e.price_egp IS NOT DISTINCT FROM s.price_egp
        AND e.description_ar IS NOT DISTINCT FROM s.description_ar
        AND e.image_path IS NOT DISTINCT FROM s.image_path
        AND e.is_published=s.is_published AND e.is_available=s.is_available
        AND e.is_demo=s.is_demo AND e.is_featured=s.is_featured
        AND e.needs_review=s.needs_review
        AND e.review_note_ar IS NOT DISTINCT FROM s.review_note_ar
        AND e.variation_ar IS NOT DISTINCT FROM s.variation_ar) AS exact_rows
    FROM public.menu_items e
    WHERE e.id=d.expected_id OR (e.category_id=c.id AND e.name_ar=s.name_ar
      AND e.price_egp IS NOT DISTINCT FROM s.price_egp)
  ) q
  WHERE q.candidates > 1 OR (q.candidates=1 AND q.exact_rows<>1);
  IF v_conflicts <> 0 THEN
    RAISE EXCEPTION 'Existing menu conflicts: % source rows', v_conflicts;
  END IF;

  INSERT INTO public.menu_items (
    id, category_id, name_ar, price_egp, description_ar, image_path,
    is_published, is_available, is_demo, is_featured, needs_review, review_note_ar, variation_ar
  )
  SELECT (substr(md5('wesaya-menu-seed-v1:'||s.source_id),1,8)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),9,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),13,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),17,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),21,12))::uuid,
    c.id, s.name_ar, s.price_egp, s.description_ar, s.image_path,
    s.is_published, s.is_available, s.is_demo, s.is_featured,
    s.needs_review, s.review_note_ar, s.variation_ar
  FROM seed_items s
  JOIN public.categories c ON c.slug=s.category_slug AND c.name_ar=s.category_name_ar
  WHERE NOT EXISTS (
    SELECT 1 FROM public.menu_items e
    WHERE e.id=(substr(md5('wesaya-menu-seed-v1:'||s.source_id),1,8)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),9,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),13,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),17,4)||'-'||
      substr(md5('wesaya-menu-seed-v1:'||s.source_id),21,12))::uuid
      OR (e.category_id=c.id AND e.name_ar=s.name_ar
        AND e.price_egp IS NOT DISTINCT FROM s.price_egp)
  )
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS v_new_items = ROW_COUNT;

  -- Verify exactly one full-field row per source_id, not just total count.
  SELECT count(*) INTO v_conflicts
  FROM seed_items s
  JOIN public.categories c ON c.slug=s.category_slug AND c.name_ar=s.category_name_ar
  CROSS JOIN LATERAL (
    SELECT count(*) AS exact_rows FROM public.menu_items e
    WHERE e.category_id=c.id AND e.name_ar=s.name_ar
      AND e.price_egp IS NOT DISTINCT FROM s.price_egp
      AND e.description_ar IS NOT DISTINCT FROM s.description_ar
      AND e.image_path IS NOT DISTINCT FROM s.image_path
      AND e.is_published=s.is_published AND e.is_available=s.is_available
      AND e.is_demo=s.is_demo AND e.is_featured=s.is_featured
      AND e.needs_review=s.needs_review
      AND e.review_note_ar IS NOT DISTINCT FROM s.review_note_ar
      AND e.variation_ar IS NOT DISTINCT FROM s.variation_ar
  ) q
  WHERE q.exact_rows <> 1;
  IF v_conflicts <> 0 THEN
    RAISE EXCEPTION 'Missing, duplicate, or non-matching source rows: %', v_conflicts;
  END IF;

  SELECT count(*) INTO v_conflicts
  FROM seed_items s
  JOIN public.categories c ON c.slug=s.category_slug AND c.name_ar=s.category_name_ar
  CROSS JOIN LATERAL (
    SELECT count(*) AS candidates,
      count(*) FILTER (WHERE e.needs_review AND NOT e.is_published) AS safe_rows
    FROM public.menu_items e
    WHERE e.category_id=c.id AND e.name_ar=s.name_ar
      AND e.price_egp IS NOT DISTINCT FROM s.price_egp
  ) q
  WHERE s.needs_review AND (q.candidates<>1 OR q.safe_rows<>1);
  IF v_conflicts <> 0 THEN
    RAISE EXCEPTION 'Review rows missing, duplicated, or published: %', v_conflicts;
  END IF;

  RAISE NOTICE 'Verified source categories=16, items=86, review rows=26; new categories=%, new items=%',
    v_new_categories, v_new_items;
END
$seed$;
