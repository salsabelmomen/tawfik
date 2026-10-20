import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react'
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import { ArrowDown, ArrowLeft, ArrowRight, ChevronDown, Heart, ImagePlus, Leaf, Menu as MenuIcon, MessageCircle, Phone, ShieldCheck, Sparkles, Star, UtensilsCrossed, X } from 'lucide-react'
import { initialCategories, initialItems } from './data'
import { imageUrl, subscribeToPasswordRecoverySession, supabase, type Category, type MenuItem, type Offer, type PasswordRecoverySession, type Testimonial } from './lib/supabase'

const navLinks = [{ href: '#menu', label: 'المنيو' }, { href: '#offers', label: 'العروض' }, { href: '#about', label: 'عن وصاية' }, { href: '#testimonials', label: 'آراء الزبائن' }]
const brandSlogan = 'طعم ❤️ حتحبه'
const foodIllustrations: Record<string, string> = { pizza: '🍕', salads: '🥗', 'pizza-sandwiches': '🥪', 'rice-pasta': '🍝', crepes: '🥙', potatoes: '🍟', tortilla: '🌯', sides: '🍽️', drinks: '🥤', combos: '🍟', kids: '🍔', meals: '🍗', 'chicken-sandwiches': '🍔', 'meat-sandwiches': '🥩', 'chicken-fries': '🍟' }

function supabaseErrorMessage(error: unknown) {
  const details = error && typeof error === 'object' ? error as { code?: unknown; status?: unknown } : {}
  if (details.code === '42P01' || details.code === 'PGRST205') {
    return 'جداول قاعدة البيانات المطلوبة غير جاهزة بعد. راجع حالة migrations في Supabase.'
  }
  if (details.code === '42501' || details.status === 401 || details.status === 403) {
    return 'رفضت صلاحيات قاعدة البيانات هذا الطلب. راجع سياسات RLS وصلاحيات الحساب.'
  }
  return 'تعذر تحميل البيانات من Supabase. تحقق من الاتصال وإعدادات المشروع ثم أعد المحاولة.'
}

const supabaseDiagnosticsEnabled = import.meta.env.DEV

function safeDiagnosticMessage(error: unknown) {
  if (!error || typeof error !== 'object') return 'Unrecognized error message redacted'
  const message = (error as { message?: unknown }).message
  if (typeof message !== 'string') return 'No message; details redacted'
  const safePatterns = [
    /^(?:column|relation|table|function) ["']?[a-z0-9_.]+["']? does not exist\.?$/i,
    /^Could not find the table '[a-z0-9_.]+' in the schema cache\.?$/i,
    /^Could not find the '[a-z0-9_]+' column of '[a-z0-9_.]+' in the schema cache\.?$/i,
    /^permission denied for (?:table|schema|function) [a-z0-9_.]+\.?$/i,
    /^new row violates row-level security policy for table "[a-z0-9_]+"\.?$/i,
    /^invalid api key\.?$/i,
    /^(?:failed to fetch|load failed|networkerror.*)$/i,
    /^jwt expired\.?$/i,
  ]
  return safePatterns.some(pattern => pattern.test(message)) ? message : 'Unrecognized error message redacted'
}

function logSupabaseQuery(name: string, error: unknown, rowCount?: number) {
  if (!supabaseDiagnosticsEnabled) return
  if (!error) {
    console.info('[Supabase diagnostic]', { query: name, outcome: 'success', rowCount })
    return
  }
  const record = typeof error === 'object' && error !== null ? error as { code?: unknown; status?: unknown } : {}
  const code = typeof record.code === 'string' && /^[A-Z0-9_-]{2,20}$/i.test(record.code) ? record.code : 'unavailable'
  const status = typeof record.status === 'number' && Number.isInteger(record.status) ? record.status : undefined
  console.warn('[Supabase diagnostic]', { query: name, outcome: 'error', code, status, message: safeDiagnosticMessage(error) })
}

async function diagnoseSupabaseQuery<T extends { error: unknown }>(name: string, query: PromiseLike<T>): Promise<T> {
  try {
    const result = await query
    const data = (result as { data?: unknown }).data
    logSupabaseQuery(name, result.error, Array.isArray(data) ? data.length : undefined)
    return result
  } catch (error) {
    logSupabaseQuery(name, error)
    throw error
  }
}

function useRestaurantData() {
  const [categories, setCategories] = useState<Category[]>(supabase ? [] : initialCategories)
  const [items, setItems] = useState<MenuItem[]>(supabase ? [] : initialItems)
  const [offers, setOffers] = useState<Offer[]>([])
  const [reviews, setReviews] = useState<Pick<Testimonial, 'id'|'display_name'|'content'|'rating'>[]>([])
  const [loading, setLoading] = useState(Boolean(supabase))
  const [loadError, setLoadError] = useState('')
  useEffect(() => {
    if (!supabase) return
    let alive = true
    Promise.all([
      diagnoseSupabaseQuery('public.categories', supabase.from('categories').select('*').order('sort_order')),
      diagnoseSupabaseQuery('public.menu_items', supabase.from('menu_items').select('*, categories(*)').eq('is_published', true).eq('is_available', true).order('created_at', { ascending: false })),
      diagnoseSupabaseQuery('public.offers', supabase.from('offers').select('*').eq('is_active', true).eq('is_published', true).order('created_at', { ascending: false })),
      diagnoseSupabaseQuery('public.testimonials', supabase.from('testimonials').select('id,display_name,content,rating').eq('is_published', true).order('created_at', { ascending: false })),
    ]).then(([cats, menu, deal, approved]) => {
      if (!alive) return
      const failed = [cats, menu, deal, approved].find(result => result.error)
      if (failed?.error) {
        setLoadError(supabaseErrorMessage(failed.error))
        return
      }
      setCategories(cats.data ?? [])
      setItems(menu.data ?? [])
      setOffers(deal.data ?? [])
      setReviews(approved.data ?? [])
      setLoadError('')
    }).catch(error => {
      if (alive) setLoadError(supabaseErrorMessage(error))
    }).finally(() => {
      if (alive) setLoading(false)
    })
    return () => { alive = false }
  }, [])
  return { categories, setCategories, items, setItems, offers, setOffers, reviews, loading, loadError, localPreview: !supabase }
}

function FirstVisit() {
  const reduced = useReducedMotion()
  const [show, setShow] = useState(true)
  useEffect(() => { const timer = window.setTimeout(() => setShow(false), reduced ? 0 : 1550); return () => window.clearTimeout(timer) }, [reduced])
  return <AnimatePresence>{show && <motion.div className="intro" initial={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: reduced ? 0 : .45 }} aria-label="أهلاً بيك في وصاية توفيق"><motion.div className="intro-flower" initial={reduced ? false : { scale: .65, rotate: -12 }} animate={{ scale: 1, rotate: 0 }} transition={{ duration: reduced ? 0 : .7 }}><span>وصاية</span><strong>توفيق</strong></motion.div><p>{brandSlogan}</p><div className="loader"><i /></div></motion.div>}</AnimatePresence>
}

function Header({ admin = false }: { admin?: boolean }) {
  const [open, setOpen] = useState(false)
  return <header className="header"><a className="brand" href={admin ? '/' : '#top'} aria-label="وصاية توفيق - الرئيسية"><span className="brand-mark"><img className="brand-mark-image" src="/menu-images/brand-hotline.jpeg" alt="" /></span><span><b>وصاية توفيق</b><small>{brandSlogan}</small></span></a>{!admin && <><nav className={open ? 'nav nav-open' : 'nav'} aria-label="التنقل الرئيسي">{navLinks.map(link => <a key={link.href} onClick={() => setOpen(false)} href={link.href}>{link.label}</a>)}<a className="nav-call" href="tel:15801"><Phone size={16} /> 15801</a></nav><button className="mobile-menu" aria-label={open ? 'إغلاق القائمة' : 'فتح القائمة'} onClick={() => setOpen(!open)}>{open ? <X /> : <MenuIcon />}</button></>}</header>
}

function Hero() {
  const [videoFailed, setVideoFailed] = useState(false)
  return <section className="hero" id="top"><div className="hero-video-wrap">{!videoFailed && <video className="hero-video" autoPlay muted loop playsInline onError={() => setVideoFailed(true)}><source src="/assets/hero-video.mp4" type="video/mp4" /></video>}<div className="hero-wash" /></div><div className="hero-content"><span className="eyebrow"><Sparkles size={15} /> حكاية طعم</span><h1>وصاية توفيق</h1><p className="brand-slogan">{brandSlogan}</p><div className="hero-actions"><a className="button button-yellow" href="#menu">اكتشف المنيو <ArrowDown size={18} /></a><a className="button button-glass" href="tel:15801"><Phone size={17} /> الخط الساخن 15801</a></div></div><div className="hero-scroll"><ChevronDown size={17} /></div></section>
}

function MenuCard({ item, categories }: { item: MenuItem; categories: Category[] }) {
  const src = imageUrl(item.image_path)
  const description = item.description_ar?.trim() || `اختيار من منيو وصاية: ${item.name_ar}.`
  return <article className="item-card" key={item.id}>
    <div className="item-image">{src ? <img src={src} alt={item.name_ar} loading="lazy" /> : <div className="item-placeholder"><span className="food-illustration" aria-hidden="true">{foodIllustrations[item.category_id ?? ''] ?? '🍽️'}</span><span>صورة مؤقتة قابلة للاستبدال</span></div>}{categories.find(cat => cat.id === item.category_id) && <span className="item-category">{categories.find(cat => cat.id === item.category_id)?.name_ar}</span>}</div>
    <div className="item-copy"><h3>{item.name_ar}{item.is_demo && <small className="demo-tag">عينة</small>}</h3>{item.needs_review && <small className="review-tag">محتاج مراجعة</small>}{item.review_note_ar && item.needs_review && <p className="review-note">{item.review_note_ar}</p>}<p className="item-description">{description}</p>{item.variation_ar?.length ? <ul className="variation-list">{item.variation_ar.map(variant => <li key={variant}>{variant}</li>)}</ul> : null}<div className="item-bottom"><span className="price">{item.price_egp === null ? 'السعر عند الطلب' : <>{item.price_egp} <small>ج.م</small></>}</span><span className={item.is_available ? 'availability' : 'availability unavailable'}>{item.is_available ? 'متاح' : 'غير متاح'}</span></div></div>
  </article>
}

function MenuSection({ categories, items, loading }: { categories: Category[]; items: MenuItem[]; loading: boolean }) {
  const [selected, setSelected] = useState('all')
  const [limit, setLimit] = useState(12)
  const visible = selected === 'all' ? items : items.filter(item => item.category_id === selected)
  useEffect(() => setLimit(12), [selected])
  return <section className="section menu-section" id="menu"><div className="section-heading"><span className="eyebrow"><UtensilsCrossed size={15} /> اختار اللي بتحبه</span><h2>منيو <em>وصاية</em></h2><p>اختار فئتك المفضلة وتصفح الأصناف بسهولة.</p></div><div className="menu-tabs" role="group" aria-label="تصفية فئات المنيو"><button className={selected === 'all' ? 'active' : ''} onClick={() => setSelected('all')}>المنيو كله</button>{categories.map(cat => <button key={cat.id} className={selected === cat.id ? 'active' : ''} onClick={() => setSelected(cat.id)}>{cat.name_ar}</button>)}</div>{loading && <div className="state-message">بنجهز المنيو ليك...</div>}{visible.length > 0 && <><div className="menu-count" aria-live="polite">عرض {Math.min(limit, visible.length)} من {visible.length} صنف</div><div className="item-grid">{visible.slice(0, limit).map(item => <MenuCard key={item.id} item={item} categories={categories} />)}</div>{limit < visible.length && <button className="button button-yellow show-more" onClick={() => setLimit(value => Math.min(value + 12, visible.length))}>عرض المزيد</button>}</>}{!loading && !items.length && <div className="menu-empty"><div className="empty-icon"><UtensilsCrossed size={27} /></div><h3>منيو وصاية كله مستنيك</h3><p>تصفح أصنافنا المتنوعة، ولو حابب تسأل عن صنف اتصل بينا.</p><a className="button button-red" href="tel:15801"><Phone size={16} /> اطلب المنيو على 15801</a></div>}</section>
}

function OfferCard({ offer }: { offer: Offer }) {
  const src = imageUrl(offer.image_path)
  const starts = offer.starts_at ? new Date(offer.starts_at).toLocaleDateString('ar-EG') : null
  const ends = offer.ends_at ? new Date(offer.ends_at).toLocaleDateString('ar-EG') : null
  return <article className="item-card offer-card" key={offer.id}>
    <div className="item-image">{src ? <img src={src} alt={offer.title_ar} loading="lazy" /> : <div className="item-placeholder"><UtensilsCrossed size={36} /></div>}</div>
    <div className="item-copy"><h3>{offer.title_ar}</h3>{offer.description_ar?.trim() && <p className="item-description">{offer.description_ar}</p>}{(starts || ends) && <div className="item-bottom offer-validity">{starts && <span>{'\u064a\u0628\u062f\u0623'} {starts}</span>}{ends && <span>{'\u064a\u0646\u062a\u0647\u064a'} {ends}</span>}</div>}</div>
  </article>
}

export function Offers({ offers }: { offers: Offer[] }) {
  const active = offers.filter(o => o.is_active && o.is_published && (!o.starts_at || new Date(o.starts_at) <= new Date()) && (!o.ends_at || new Date(o.ends_at) >= new Date()))
  return <section className="section menu-section" id="offers"><div className="section-heading"><span className="eyebrow"><Sparkles size={15} /> {'\u0639\u0644\u0649 \u0645\u0632\u0627\u062c\u0643'}</span><h2>{'\u0627\u0644\u0639\u0631\u0648\u0636'}</h2></div>{active.length ? <div className="item-grid">{active.map(offer => <OfferCard key={offer.id} offer={offer} />)}</div> : <div className="state-message">{'\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0631\u0648\u0636 \u0645\u062a\u0627\u062d\u0629 \u062d\u0627\u0644\u064a\u064b\u0627.'}</div>}</section>
}

function About() {
  return <section className="section about-section" id="about"><div className="about-copy"><span className="eyebrow"><Heart size={15} /> حكاية طعم</span><h2>كل أكلة ليها وصاية</h2><p>وصاية توفيق.. اختيارات متنوعة من الأكل اللي بتحبه، بطعم يخليك ترجعله تاني.</p><p>شايف حاجة نفسك تجربها؟ كلمنا على الخط الساخن.</p><a className="button button-red" href="tel:15801"><Phone size={17} /> 15801</a></div></section>
}

const feedbackImages = [
  { src: '/feedback-01.jpeg', width: 800, height: 299 },
  { src: '/feedback-02.jpeg', width: 812, height: 186 },
  { src: '/feedback-03.jpeg', width: 812, height: 176 },
  { src: '/feedback-04.jpeg', width: 812, height: 180 },
  { src: '/feedback-05.jpeg', width: 800, height: 277 },
]

function Testimonials({ reviews }: { reviews: Pick<Testimonial, 'id'|'display_name'|'content'|'rating'>[] }) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null)
  const isLightboxOpen = selectedIndex !== null
  const reducedMotion = useReducedMotion()
  const galleryRef = useRef<HTMLDivElement>(null)
  const carouselSetRef = useRef<HTMLDivElement>(null)
  const dialogRef = useRef<HTMLDivElement>(null)
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const triggerRef = useRef<HTMLElement | null>(null)
  const pausedRef = useRef(false)
  const lightboxOpenRef = useRef(false)
  const touchActiveRef = useRef(false)
  const lastAutoScrollRef = useRef(0)
  const resumeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  lightboxOpenRef.current = isLightboxOpen

  useEffect(() => {
    if (reducedMotion) return
    let animationFrame = 0
    let previousTime = 0

    function animateCarousel(time: number) {
      const gallery = galleryRef.current
      const groupWidth = carouselSetRef.current?.offsetWidth ?? 0
      const elapsed = previousTime ? Math.min(time - previousTime, 64) : 0
      previousTime = time

      if (gallery && groupWidth > 0 && !pausedRef.current && !lightboxOpenRef.current) {
        lastAutoScrollRef.current = time
        gallery.scrollLeft += elapsed * 0.032
        if (gallery.scrollLeft >= groupWidth) gallery.scrollLeft %= groupWidth
      }
      animationFrame = requestAnimationFrame(animateCarousel)
    }

    animationFrame = requestAnimationFrame(animateCarousel)
    return () => {
      cancelAnimationFrame(animationFrame)
      if (resumeTimerRef.current) clearTimeout(resumeTimerRef.current)
    }
  }, [reducedMotion])

  function resumeAfterInteraction() {
    if (resumeTimerRef.current) clearTimeout(resumeTimerRef.current)
    resumeTimerRef.current = setTimeout(() => {
      const gallery = galleryRef.current
      if (!touchActiveRef.current && !gallery?.contains(document.activeElement) && !gallery?.matches(':hover')) {
        pausedRef.current = false
      }
    }, 1200)
  }

  function handleGalleryScroll() {
    if (performance.now() - lastAutoScrollRef.current < 80) return
    pausedRef.current = true
    if (!touchActiveRef.current) resumeAfterInteraction()
  }

  function closeLightbox() {
    setSelectedIndex(null)
    requestAnimationFrame(() => triggerRef.current?.focus())
  }

  useEffect(() => {
    if (selectedIndex === null) return
    closeButtonRef.current?.focus()
    function handleDialogKeys(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setSelectedIndex(null)
        requestAnimationFrame(() => triggerRef.current?.focus())
      } else if (event.key === 'ArrowLeft') {
        setSelectedIndex(index => index === null ? null : (index + 1) % feedbackImages.length)
      } else if (event.key === 'ArrowRight') {
        setSelectedIndex(index => index === null ? null : (index - 1 + feedbackImages.length) % feedbackImages.length)
      } else if (event.key === 'Tab') {
        const controls = dialogRef.current?.querySelectorAll<HTMLButtonElement>('button:not([disabled])')
        if (!controls?.length) return
        const first = controls[0]
        const last = controls[controls.length - 1]
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault()
          last.focus()
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault()
          first.focus()
        }
      }
    }
    window.addEventListener('keydown', handleDialogKeys)
    return () => window.removeEventListener('keydown', handleDialogKeys)
  }, [isLightboxOpen])

  const renderImageCard = (image: typeof feedbackImages[number], index: number, duplicate = false) => {
    const imageElement = <img src={image.src} alt={duplicate ? '' : `صورة رأي عميل ${index + 1}`} width={image.width} height={image.height} />
    if (duplicate) return <div className="feedback-gallery-card" key={`duplicate-${image.src}`} aria-hidden="true" onClick={()=>{triggerRef.current=galleryRef.current;setSelectedIndex(index)}}>{imageElement}</div>

    return <motion.button className="feedback-gallery-card" key={image.src} type="button" onClick={event=>{triggerRef.current=event.currentTarget;setSelectedIndex(index)}} aria-label={`عرض صورة رأي العميل ${index + 1} بحجم أكبر`} initial={reducedMotion?false:{opacity:0,y:14}} whileInView={{opacity:1,y:0}} viewport={{once:true,amount:.2}} transition={{duration:reducedMotion?0:.42,delay:reducedMotion?0:index*.055}}>{imageElement}</motion.button>
  }

  return <section className="feedback-section" id="testimonials"><div className="feedback-decoration" aria-hidden="true"><Star /><Star /><Star /></div><div className="feedback-inner"><div className="feedback-copy"><span className="eyebrow"><MessageCircle size={15} /> آراء وتجارب</span><h2>آراء عملائنا <em>❤️</em></h2><p>كل رأي بيفرق معانا، وشكرًا إنكم جزء من لَمّتنا</p></div>{!reviews.length && <div className="testimonial-empty"><Heart size={24} /><p>لا توجد شهادات نصية منشورة حاليًا.</p></div>}</div>{reviews.length>0&&<div className="approved-reviews" aria-label="شهادات منشورة">{reviews.map(review=><blockquote key={review.id}>{review.rating!==null&&<div className="testimonial-rating" aria-label={'تقييم '+review.rating+' من 5'}>{Array.from({length:review.rating},(_,i)=><Star key={i} size={15} fill="currentColor"/>)}</div>}<p>{review.content}</p>{review.display_name&&<cite>{review.display_name}</cite>}</blockquote>)}</div>}<div className="feedback-gallery" role="region" aria-label="معرض صور آراء العملاء" tabIndex={0} dir="ltr" ref={galleryRef} onScroll={handleGalleryScroll} onPointerEnter={event=>{if(event.pointerType!=='touch')pausedRef.current=true}} onPointerLeave={event=>{if(event.pointerType!=='touch'&&!galleryRef.current?.contains(document.activeElement))pausedRef.current=false}} onPointerDown={event=>{pausedRef.current=true;if(event.pointerType==='touch')touchActiveRef.current=true}} onPointerUp={event=>{if(event.pointerType==='touch'){touchActiveRef.current=false;resumeAfterInteraction()}}} onPointerCancel={()=>{touchActiveRef.current=false;resumeAfterInteraction()}} onFocusCapture={()=>{pausedRef.current=true}} onBlurCapture={event=>{if(!event.currentTarget.contains(event.relatedTarget as Node|null)&&!event.currentTarget.matches(':hover'))pausedRef.current=false}}><div className="feedback-carousel-track"><div className="feedback-carousel-set" ref={carouselSetRef}>{feedbackImages.map((image,index)=>renderImageCard(image,index))}</div><div className="feedback-carousel-set" aria-hidden="true">{feedbackImages.map((image,index)=>renderImageCard(image,index,true))}</div></div></div>{selectedIndex!==null&&<div className="feedback-lightbox" role="dialog" aria-modal="true" aria-label="معرض صور آراء العملاء المكبر" ref={dialogRef} onClick={closeLightbox}><button className="feedback-lightbox-close" type="button" aria-label="إغلاق الصور" ref={closeButtonRef} onClick={closeLightbox}><X size={22}/></button><button className="feedback-lightbox-nav feedback-lightbox-prev" type="button" aria-label="الصورة السابقة" onClick={event=>{event.stopPropagation();setSelectedIndex((selectedIndex-1+feedbackImages.length)%feedbackImages.length)}}><ArrowRight size={22}/></button><img src={feedbackImages[selectedIndex].src} alt={`صورة رأي عميل ${selectedIndex+1} بحجم أكبر`} onClick={event=>event.stopPropagation()} /><button className="feedback-lightbox-nav feedback-lightbox-next" type="button" aria-label="الصورة التالية" onClick={event=>{event.stopPropagation();setSelectedIndex((selectedIndex+1)%feedbackImages.length)}}><ArrowLeft size={22}/></button><span className="feedback-lightbox-count" aria-live="polite">{selectedIndex+1} من {feedbackImages.length}</span></div>}</section>
}
function Footer() {
  return <footer className="footer"><div className="footer-main"><a className="brand brand-footer" href="#top"><span className="brand-mark">و</span><span><b>وصاية توفيق</b><small>{brandSlogan}</small></span></a><p>حكاية طعم حلوة.. من أول لقمة.</p><a className="footer-phone" href="tel:15801"><Phone size={17} /> الخط الساخن <strong>15801</strong></a></div><div className="footer-bottom"><span>وصاية توفيق © {new Date().getFullYear()}</span><span>{brandSlogan} <Heart size={13} fill="currentColor" /></span><a href="/admin" aria-label="لوحة الإدارة" className="admin-link">إدارة الموقع</a></div></footer>
}

function Landing() {
  const data = useRestaurantData()
  return <><FirstVisit /><Header /><main>{data.localPreview && <p className="data-status data-status-preview" role="status">معاينة محلية: بيانات المنيو المعروضة ليست محمّلة من قاعدة بيانات Supabase.</p>}{data.loadError && <p className="data-status data-status-error" role="alert">{data.loadError}</p>}<Hero /><div className="ticker"><div className="ticker-track">{Array.from({ length: 24 }, (_, i) => <span key={i}>{brandSlogan} <i>✳</i> الخط الساخن 15801 <i>✳</i></span>)}</div></div><MenuSection categories={data.categories} items={data.items} loading={data.loading} /><Offers offers={data.offers} /><About /><Testimonials reviews={data.reviews} /></main><Footer /></>
}

function PasswordRecovery() {
  const [recoverySession, setRecoverySession] = useState<PasswordRecoverySession | null>(null)
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [complete, setComplete] = useState(false)

  useEffect(() => subscribeToPasswordRecoverySession(setRecoverySession), [])

  async function updatePassword(event: FormEvent) {
    event.preventDefault()
    if (!supabase || !recoverySession) return
    if (password !== confirmation) {
      setError('كلمتا المرور غير متطابقتين.')
      return
    }

    setBusy(true)
    setError('')
    try {
      const current = await supabase.auth.getSession()
      if (current.error || !current.data.session || current.data.session.user.id !== recoverySession.user.id) {
        setRecoverySession(null)
        setError('رابط الاستعادة غير صالح أو انتهت صلاحيته. اطلب رابطًا جديدًا.')
        return
      }

      const { error: updateError } = await supabase.auth.updateUser({ password })
      if (updateError) {
        setError('تعذر تغيير كلمة المرور. قد يكون الرابط انتهى؛ اطلب رابط استعادة جديدًا وحاول مرة أخرى.')
        return
      }

      await supabase.auth.signOut({ scope: 'local' })
      setRecoverySession(null)
      setComplete(true)
    } catch {
      setError('تعذر تغيير كلمة المرور الآن. تحقق من الاتصال واطلب رابطًا جديدًا إذا انتهت صلاحيته.')
    } finally {
      setBusy(false)
    }
  }

  const recoveryReady = Boolean(recoverySession?.access_token && recoverySession.user?.id)

  return <><Header admin /><main className="admin-page"><section className="admin-login">
    <div className="admin-icon"><ShieldCheck /></div>
    <span className="eyebrow">استعادة الحساب</span>
    <h1>{complete ? 'تم تغيير كلمة المرور' : 'تعيين كلمة مرور جديدة'}</h1>
    {complete ? <>
      <p className="admin-auth-message admin-auth-success" role="status">تم تغيير كلمة المرور. يمكنك الآن تسجيل الدخول بها.</p>
      <a className="button button-red" href="/admin">العودة لتسجيل الدخول <ArrowLeft size={17}/></a>
    </> : recoveryReady ? <form className="admin-auth-form" onSubmit={updatePassword}>
      <p>اكتب كلمة المرور الجديدة وأكدها لإكمال الاستعادة.</p>
      <label htmlFor="recovery-password">كلمة المرور الجديدة</label>
      <input id="recovery-password" type="password" value={password} onChange={event => setPassword(event.target.value)} required autoComplete="new-password" />
      <label htmlFor="recovery-password-confirm">تأكيد كلمة المرور</label>
      <input id="recovery-password-confirm" type="password" value={confirmation} onChange={event => setConfirmation(event.target.value)} required autoComplete="new-password" />
      <button className="button button-red" disabled={busy}>{busy ? 'جاري تغيير كلمة المرور...' : 'حفظ كلمة المرور الجديدة'}</button>
      {error && <p className="admin-auth-message admin-auth-error" role="alert">{error}</p>}
    </form> : <>
      <p className="admin-auth-message" role="status">رابط الاستعادة غير صالح أو انتهت صلاحيته. ارجع لصفحة الدخول واطلب رابطًا جديدًا.</p>
      <a className="button button-red" href="/admin">العودة لصفحة الدخول <ArrowLeft size={17}/></a>
    </>}
  </section></main></>
}

function Admin() {
  const [session, setSession] = useState<Awaited<ReturnType<NonNullable<typeof supabase>['auth']['getSession']>>['data']['session']>(null)
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [error, setError] = useState(''); const [authMode, setAuthMode] = useState<'login'|'recovery-email'>('login'); const [resetNotice, setResetNotice] = useState(''); const [resetError, setResetError] = useState(''); const [section, setSection] = useState<'overview'|'items'|'offers'|'testimonials'|'categories'>('overview')
  const [items, setItems] = useState<MenuItem[]>([]); const [categories, setCategories] = useState<Category[]>([]); const [openMenuCategory, setOpenMenuCategory] = useState<string | null>(null); const [offers, setOffers] = useState<Offer[]>([]); const [testimonials, setTestimonials] = useState<Testimonial[]>([])
  const [testimonialName, setTestimonialName] = useState(''); const [testimonialNameAuthorized, setTestimonialNameAuthorized] = useState(false); const [testimonialContent, setTestimonialContent] = useState(''); const [testimonialRating, setTestimonialRating] = useState(''); const [editingTestimonial, setEditingTestimonial] = useState<string|null>(null)
  const [itemName, setItemName] = useState(''); const [itemDescription, setItemDescription] = useState(''); const [itemPrice, setItemPrice] = useState(''); const [itemCategory, setItemCategory] = useState(''); const [itemImage, setItemImage] = useState<File|null>(null); const [itemPreview, setItemPreview] = useState(''); const [itemDemo, setItemDemo] = useState(false); const [itemFeatured, setItemFeatured] = useState(false); const [itemNeedsReview, setItemNeedsReview] = useState(false); const [itemReviewNote, setItemReviewNote] = useState(''); const [editingItem, setEditingItem] = useState<string|null>(null)
  const [offerTitle, setOfferTitle] = useState(''); const [offerDescription, setOfferDescription] = useState(''); const [offerStart, setOfferStart] = useState(''); const [offerEnd, setOfferEnd] = useState(''); const [offerImage, setOfferImage] = useState<File|null>(null); const [offerPreview, setOfferPreview] = useState(''); const [editingOffer, setEditingOffer] = useState<string|null>(null)
  const [catName, setCatName] = useState(''); const [busy, setBusy] = useState(false); const [notice, setNotice] = useState(''); const [loadError, setLoadError] = useState('')
  useEffect(() => { if (!supabase) return; supabase.auth.getSession().then(({ data }) => setSession(data.session)); const { data } = supabase.auth.onAuthStateChange((_event, s) => setSession(s)); return () => data.subscription.unsubscribe() }, [])
  const load = async () => {
    if (!supabase) return
    try {
      const [i,c,o,t]=await Promise.all([diagnoseSupabaseQuery('admin.public.menu_items',supabase.from('menu_items').select('*, categories(*)').order('created_at',{ascending:false})),diagnoseSupabaseQuery('admin.public.categories',supabase.from('categories').select('*').order('sort_order')),diagnoseSupabaseQuery('admin.public.offers',supabase.from('offers').select('*').order('created_at',{ascending:false})),diagnoseSupabaseQuery('admin.public.testimonials',supabase.from('testimonials').select('*').order('created_at',{ascending:false}))])
      const failed = [i,c,o,t].find(result => result.error)
      if (failed?.error) {
        setLoadError(supabaseErrorMessage(failed.error))
        return
      }
      setItems(i.data ?? []); setCategories(c.data ?? []); setOffers(o.data ?? []); setTestimonials(t.data ?? []); setLoadError('')
    } catch (error) {
      setLoadError(supabaseErrorMessage(error))
    }
  }
  useEffect(() => { if (session) void load() }, [session])
  async function login(e: FormEvent) { e.preventDefault(); if(!supabase){setError('اربط بيانات Supabase في ملف .env.local أولاً.');return};setBusy(true);setError(''); const {error:e2}=await supabase.auth.signInWithPassword({email,password});setBusy(false);if(e2)setError('تعذر تسجيل الدخول. راجع البريد وكلمة المرور أو صلاحيات حساب الإدارة.') }
  async function requestPasswordReset(e: FormEvent) {
    e.preventDefault()
    if (!supabase) return
    setBusy(true)
    setResetError('')
    setResetNotice('')
    try {
      const redirectTo = `${window.location.origin}/admin/reset-password`
      const { error: requestError } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo })
      if (requestError) {
        setResetError('تعذر إرسال طلب الاستعادة الآن. حاول مرة أخرى لاحقًا.')
      } else {
        setResetNotice('إذا كان البريد مرتبطًا بحساب، فستصلك رسالة تحتوي على رابط استعادة كلمة المرور.')
      }
    } catch {
      setResetError('تعذر إرسال طلب الاستعادة الآن. تحقق من الاتصال وحاول مرة أخرى لاحقًا.')
    } finally {
      setBusy(false)
    }
  }
  async function upload(file: File, folder: 'menu'|'offers') { if(!supabase) throw new Error('قاعدة البيانات غير متصلة'); if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5*1024*1024)throw new Error('اختار صورة JPG أو PNG أو WebP بحجم أقل من 5 ميجابايت.'); const safe=file.name.replace(/[^a-zA-Z0-9._-]/g,'-');const path=`${folder}/${crypto.randomUUID()}-${safe}`;const {error:e}=await supabase.storage.from('restaurant-images').upload(path,file,{upsert:false});if(e)throw e;return path }
  async function saveItem(e: FormEvent) {
    e.preventDefault()
    if (!supabase) return
    setBusy(true)
    setNotice('')
    try {
      if (editingItem) {
        const { data: updatedItem, error: updateError } = await supabase
          .from('menu_items')
          .update({ description_ar: itemDescription.trim() || null })
          .eq('id', editingItem)
          .select('id')
          .single()
        if (updateError?.code === 'PGRST116') {
          setNotice('لم يتمكن التطبيق من تأكيد تحديث الوصف. تحقق من الصنف ثم أعد المحاولة.')
          return
        }
        if (updateError) throw updateError
        if (!updatedItem) {
          setNotice('لم يتمكن التطبيق من تأكيد تحديث الوصف. تحقق من الصنف ثم أعد المحاولة.')
          return
        }

        setItemName('')
        setItemDescription('')
        setItemPrice('')
        setItemCategory('')
        setItemImage(null)
        setItemPreview('')
        setItemDemo(false)
        setItemFeatured(false)
        setItemNeedsReview(false)
        setItemReviewNote('')
        setEditingItem(null)
        setNotice('تم حفظ التعديلات.')
        await load()
        return
      }

      const image_path = itemImage ? await upload(itemImage, 'menu') : null
      const record = {
        name_ar: itemName.trim(),
        description_ar: itemDescription.trim() || null,
        price_egp: itemPrice ? Number(itemPrice) : null,
        category_id: itemCategory || null,
        image_path,
        is_published: !itemDemo,
        is_available: true,
        is_demo: itemDemo,
        is_featured: itemFeatured,
        needs_review: itemNeedsReview,
        review_note_ar: itemNeedsReview ? (itemReviewNote.trim() || null) : null,
      }
      const { error: insertError } = await supabase.from('menu_items').insert(record)
      if (insertError) throw insertError

      setItemName('')
      setItemDescription('')
      setItemPrice('')
      setItemCategory('')
      setItemImage(null)
      setItemPreview('')
      setItemDemo(false)
      setItemFeatured(false)
      setItemNeedsReview(false)
      setItemReviewNote('')
      setEditingItem(null)
      setNotice('تم حفظ الصنف.')
      await load()
    } catch (err) {
      setNotice(supabaseErrorMessage(err))
    } finally {
      setBusy(false)
    }
  }
  function editItem(item:MenuItem){setEditingItem(item.id);setItemName(item.name_ar);setItemDescription(item.description_ar??'');setItemPrice(item.price_egp===null?'':String(item.price_egp));setItemCategory(item.category_id??'');setItemDemo(item.is_demo);setItemFeatured(Boolean(item.is_featured));setItemNeedsReview(Boolean(item.needs_review));setItemReviewNote(item.review_note_ar??'');setItemImage(null);setItemPreview(imageUrl(item.image_path)??'');document.getElementById('menu-item-editor')?.scrollIntoView({behavior:'smooth'})}
  async function saveOffer(e:FormEvent){e.preventDefault();if(!supabase)return;setBusy(true);setNotice('');try{const existing=offers.find(o=>o.id===editingOffer);const image_path=offerImage?await upload(offerImage,'offers'):existing?.image_path??null;const record={title_ar:offerTitle.trim(),description_ar:offerDescription.trim()||null,image_path,starts_at:offerStart?new Date(offerStart).toISOString():null,ends_at:offerEnd?new Date(offerEnd).toISOString():null,is_demo:false,is_active:existing?.is_active??false,is_published:existing?.is_published??false};const result=editingOffer?await supabase.from('offers').update(record).eq('id',editingOffer):await supabase.from('offers').insert(record);if(result.error)throw result.error;setEditingOffer(null);setOfferTitle('');setOfferDescription('');setOfferImage(null);setOfferPreview('');setOfferStart('');setOfferEnd('');setNotice('تم حفظ العرض.');await load()}catch(err){setNotice(supabaseErrorMessage(err))}finally{setBusy(false)}}
  function editOffer(offer:Offer){setEditingOffer(offer.id);setOfferTitle(offer.title_ar);setOfferDescription(offer.description_ar??'');setOfferStart(offer.starts_at?.slice(0,16)??'');setOfferEnd(offer.ends_at?.slice(0,16)??'');setOfferImage(null);setOfferPreview(imageUrl(offer.image_path)??'');document.querySelector('.editor-form')?.scrollIntoView({behavior:'smooth'})}
  async function toggleOffer(offer:Offer,key:'is_active'|'is_published'){if(!supabase)return;const {error:e}=await supabase.from('offers').update({[key]:!offer[key],is_demo:false}).eq('id',offer.id);setNotice(e?'تعذر تحديث العرض.':'تم تحديث العرض.');await load()}
  async function removeOffer(offer:Offer){if(!supabase||!window.confirm(`حذف العرض ${offer.title_ar}؟`))return;const {error:e}=await supabase.from('offers').delete().eq('id',offer.id);setNotice(e?'تعذر حذف العرض.':'تم حذف العرض.');await load()}
  async function addCategory(e:FormEvent){e.preventDefault();if(!supabase)return;const {error:e2}=await supabase.from('categories').insert({name_ar:catName.trim(),slug:`${Date.now()}`,sort_order:categories.length+1});setNotice(e2?'تعذر إضافة الفئة.':'تمت إضافة الفئة.');if(!e2){setCatName('');await load()}}
  async function renameCategory(id:string,name:string){if(!supabase||name.trim().length<1)return;const {error:e}=await supabase.from('categories').update({name_ar:name.trim()}).eq('id',id);setNotice(e?'تعذر تحديث الفئة.':'تم تحديث الفئة.');await load()}
  async function removeCategory(category:Category){if(!supabase||!window.confirm('حذف الفئة؟ الأصناف المرتبطة بها ستبقى بدون فئة.'))return;const {error:e}=await supabase.from('categories').delete().eq('id',category.id);setNotice(e?'تعذر حذف الفئة.':'تم حذف الفئة.');await load()}
  async function saveTestimonial(e:FormEvent){e.preventDefault();if(!supabase)return;if(testimonialContent.trim().length<8){setNotice('اكتب شهادة من 8 أحرف على الأقل.');return}if(testimonialName.trim()&&!testimonialNameAuthorized){setNotice('أكد أن لديك إذناً لنشر اسم صاحب الشهادة.');return}setBusy(true);const existing=testimonials.find(t=>t.id===editingTestimonial);const record={display_name:testimonialName.trim()||null,content:testimonialContent.trim(),rating:testimonialRating?Number(testimonialRating):null,is_published:existing?.is_published??false};const result=editingTestimonial?await supabase.from('testimonials').update(record).eq('id',editingTestimonial):await supabase.from('testimonials').insert(record);setBusy(false);setNotice(result.error?'تعذر حفظ الشهادة.':'تم حفظ الشهادة.');if(!result.error){setEditingTestimonial(null);setTestimonialName('');setTestimonialNameAuthorized(false);setTestimonialContent('');setTestimonialRating('');await load()}}
  function editTestimonial(t:Testimonial){setEditingTestimonial(t.id);setTestimonialName(t.display_name??'');setTestimonialNameAuthorized(Boolean(t.display_name));setTestimonialContent(t.content);setTestimonialRating(t.rating===null?'':String(t.rating))}
  async function toggleTestimonial(t:Testimonial){if(!supabase)return;const {error:e}=await supabase.from('testimonials').update({is_published:!t.is_published}).eq('id',t.id);setNotice(e?'تعذر تحديث النشر.':'تم تحديث حالة النشر.');await load()}
  async function removeTestimonial(t:Testimonial){if(!supabase||!window.confirm('حذف الشهادة نهائياً؟'))return;const {error:e}=await supabase.from('testimonials').delete().eq('id',t.id);setNotice(e?'تعذر حذف الشهادة.':'تم حذف الشهادة.');await load()}
  async function toggleItem(item:MenuItem, key:'is_published'|'is_available'|'is_featured'){if(!supabase)return;const {error:e}=await supabase.from('menu_items').update({[key]:!item[key]}).eq('id',item.id);setNotice(e?'تعذر تحديث الصنف.':'تم تحديث الصنف.');await load()}
  async function removeItem(item:MenuItem){if(!supabase||!window.confirm(`حذف ${item.name_ar} نهائياً؟`))return;const {error:e}=await supabase.from('menu_items').delete().eq('id',item.id);setNotice(e?'تعذر حذف الصنف.':'تم الحذف.');await load()}
  const cards = useMemo(()=>[{label:'أصناف المنيو',value:items.length,icon:<UtensilsCrossed/>},{label:'العروض',value:offers.length,icon:<Sparkles/>},{label:'الشهادات المنشورة',value:testimonials.filter(t=>t.is_published).length,icon:<MessageCircle/>},{label:'فئات المنيو',value:categories.length,icon:<Leaf/>}], [items,offers,testimonials,categories])
  const menuCategoryGroups = [
    ...categories.map(category => ({ id: category.id, name: category.name_ar, items: items.filter(item => item.category_id === category.id) })),
    { id: '__uncategorized__', name: String.fromCharCode(0x628,0x62f,0x648,0x646,0x20,0x641,0x626,0x629), items: items.filter(item => !item.category_id || !categories.some(category => category.id === item.category_id)) },
  ];
  if(!supabase)return <><Header admin /><main className="admin-page"><section className="admin-login"><div className="admin-icon"><ShieldCheck /></div><span className="eyebrow">إعداد لوحة التحكم</span><h1>إدارة وصاية</h1><p>أضف مفاتيح مشروع Supabase في <code>.env.local</code>، ثم شغّل ملف قاعدة البيانات لفتح تسجيل الدخول.</p><a className="button button-red" href="/">العودة للموقع <ArrowLeft size={17}/></a></section></main></>
  if(!session)return <><Header admin /><main className="admin-page">{authMode === 'login' ? <form className="admin-login" onSubmit={login}>
    <div className="admin-icon"><ShieldCheck /></div><span className="eyebrow">منطقة الإدارة</span><h1>أهلاً بيك تاني</h1><p>سجل دخولك بحساب مدير مُصرح له.</p>
    <label htmlFor="login-email">البريد الإلكتروني</label><input id="login-email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required autoComplete="username" />
    <label htmlFor="login-password">كلمة المرور</label><input id="login-password" type="password" value={password} onChange={e=>setPassword(e.target.value)} required autoComplete="current-password" />
    <button className="button button-red" disabled={busy}>{busy?'جاري الدخول...':'تسجيل الدخول'} <ArrowLeft size={17}/></button>
    <button type="button" className="admin-auth-link" onClick={()=>{setAuthMode('recovery-email');setError('');setResetNotice('');setResetError('')}}>نسيت كلمة المرور؟</button>
    {error&&<p role="alert" className="admin-auth-message admin-auth-error">{error}</p>}
  </form> : <form className="admin-login" onSubmit={requestPasswordReset}>
    <div className="admin-icon"><ShieldCheck /></div><span className="eyebrow">استعادة الحساب</span><h1>نسيت كلمة المرور؟</h1><p>اكتب بريدك الإلكتروني، وسنرسل رابط الاستعادة إذا كان مرتبطًا بحساب.</p>
    <label htmlFor="reset-email">البريد الإلكتروني</label><input id="reset-email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required autoComplete="email" />
    <button className="button button-red" disabled={busy}>{busy?'جاري إرسال الطلب...':'إرسال رابط الاستعادة'} <ArrowLeft size={17}/></button>
    <button type="button" className="admin-auth-link" onClick={()=>{setAuthMode('login');setResetNotice('');setResetError('')}}>العودة لتسجيل الدخول</button>
    {resetNotice&&<p role="status" className="admin-auth-message admin-auth-success">{resetNotice}</p>}
    {resetError&&<p role="alert" className="admin-auth-message admin-auth-error">{resetError}</p>}
  </form>}</main></>
  return <><Header admin /><main className="dashboard"><aside className="admin-sidebar"><div className="side-title">لوحة الإدارة</div>{([['overview','نظرة عامة'],['items','أصناف المنيو'],['categories','فئات المنيو'],['offers','العروض'],['testimonials','الشهادات']] as const).map(([key,label])=><button key={key} className={section===key?'selected':''} onClick={()=>setSection(key)}>{label}</button>)}<button className="logout" onClick={()=>void supabase?.auth.signOut()}>تسجيل الخروج</button></aside><section className="dashboard-content"><div className="dashboard-head"><div><span className="eyebrow">أهلاً بيك في وصاية</span><h1>{section==='overview'?'نظرة عامة':section==='items'?'أصناف المنيو':section==='categories'?'فئات المنيو':section==='offers'?'إدارة العروض':'إدارة الشهادات'}</h1></div><button className="button button-yellow" onClick={()=>void load()}>تحديث البيانات</button></div>{loadError&&<p className="admin-notice admin-notice-error" role="alert">{loadError}</p>}{notice&&<p className="admin-notice" role="status">{notice}</p>}{section==='overview'&&<><div className="stat-grid">{cards.map(c=><article key={c.label}><span>{c.icon}</span><b>{c.value}</b><small>{c.label}</small></article>)}</div><div className="admin-panel"><h2>جاهز تبدأ؟</h2><p>أضف بيانات المنيو الحقيقية وحدث صور الأصناف. العناصر المضافة كعينات تظل غير منشورة حتى تراجعها.</p></div></>}{section==='items'&&<><form id="menu-item-editor" className="admin-panel editor-form" onSubmit={saveItem}><h2>{editingItem?"تعديل الصنف":"إضافة صنف"}</h2><label>اسم الصنف<input required value={itemName} onChange={e=>setItemName(e.target.value)} maxLength={120}/></label><label>??? ?????<textarea value={itemDescription} onChange={e=>setItemDescription(e.target.value)} maxLength={300} rows={2} placeholder="??? ????? ???? ???????"/></label><label>السعر بالجنيه (اتركه فارغاً إن لم يتأكد)<input type="number" min="0" step="1" value={itemPrice} onChange={e=>setItemPrice(e.target.value)}/></label><label>الفئة<select value={itemCategory} onChange={e=>setItemCategory(e.target.value)}><option value="">بدون فئة</option>{categories.map(c=><option value={c.id} key={c.id}>{c.name_ar}</option>)}</select></label><label className="upload-box"><ImagePlus size={22}/>{itemPreview?<img src={itemPreview} alt="معاينة صورة الصنف"/>:<span>صورة الصنف · JPG، PNG، WebP · حتى 5MB</span>}<input type="file" accept="image/jpeg,image/png,image/webp" onChange={e=>{const f=e.target.files?.[0];if(f){setItemImage(f);setItemPreview(URL.createObjectURL(f))}}}/></label><label className="check-line"><input type="checkbox" checked={itemDemo} onChange={e=>setItemDemo(e.target.checked)}/> عينة / غير مؤكّد (يبقى غير منشور)</label><label className="check-line"><input type="checkbox" checked={itemFeatured} onChange={e=>setItemFeatured(e.target.checked)}/> ??? ??? ?????? ?????</label><label className="check-line"><input type="checkbox" checked={itemNeedsReview} onChange={e=>setItemNeedsReview(e.target.checked)}/> الاسم أو السعر يحتاج مراجعة (لن يظهر للزوار)</label>{itemNeedsReview&&<label>ملاحظة المراجعة<textarea value={itemReviewNote} onChange={e=>setItemReviewNote(e.target.value)} maxLength={500}/></label>}<button className="button button-red" disabled={busy}>{busy?'جاري الحفظ...':editingItem?'حفظ التعديلات':'حفظ الصنف'}</button>{editingItem&&<button type="button" onClick={()=>{setEditingItem(null);setItemName('');setItemDescription('');setItemPrice('');setItemFeatured(false);setItemImage(null);setItemPreview('')}}>إلغاء التعديل</button>}</form><div className="admin-panel"><h2>الأصناف ({items.length})</h2>{menuCategoryGroups.map(group=><section className="admin-category-group" key={group.id} data-category-id={group.id}><button type="button" className="admin-category-toggle" aria-expanded={openMenuCategory===group.id} onClick={()=>setOpenMenuCategory(openMenuCategory===group.id?null:group.id)}><span>{group.name}</span><span className="admin-category-count">{group.items.length} {'\u0635\u0646\u0641'}</span><ChevronDown size={17}/></button>{openMenuCategory===group.id&&<div className="admin-category-items">{group.items.map(item=><div className="admin-row" key={item.id}><span>{item.name_ar}{item.is_demo&&<small className="demo-tag">{'\u0639\u064a\u0646\u0629'}</small>}{item.needs_review&&<small className="review-tag">{'\u0645\u0631\u0627\u062c\u0639\u0629'}</small>}</span><span>{item.price_egp===null?'\u2014':item.price_egp+' '+ '\u062c.\u0645'}</span><button onClick={()=>void toggleItem(item,'is_published')}>{item.is_published?'\u0625\u0644\u063a\u0627\u0621 \u0627\u0644\u0646\u0634\u0631':'\u0646\u0634\u0631'}</button><button onClick={()=>void toggleItem(item,'is_available')}>{item.is_available?'\u0645\u062a\u0627\u062d':'\u063a\u064a\u0631 \u0645\u062a\u0627\u062d'}</button><button onClick={()=>void toggleItem(item,'is_featured')}>{item.is_featured?'\u062a\u0645\u064a\u064a\u0632 \u0645\u0646 \u0627\u0644\u0623\u0643\u062b\u0631 \u0637\u0644\u0628\u0627\u064b':'\u062a\u0645\u064a\u064a\u0632 \u0644\u0644\u0623\u0643\u062b\u0631 \u0637\u0644\u0628\u0627\u064b'}</button><button onClick={()=>editItem(item)}>{'\u062a\u0639\u062f\u064a\u0644'}</button><button className="danger-link" onClick={()=>void removeItem(item)}>{'\u062d\u0630\u0641'}</button></div>)}</div>}</section>)}</div></>}{section==='categories'&&<><form className="admin-panel editor-form" onSubmit={addCategory}><h2>إضافة فئة</h2><label>اسم الفئة<input required value={catName} onChange={e=>setCatName(e.target.value)} maxLength={80}/></label><button className="button button-red">إضافة الفئة</button></form><div className="admin-panel"><h2>الفئات ({categories.length})</h2>{categories.map(c=><form className="admin-row category-row" key={c.id} onSubmit={e=>{e.preventDefault();const data=new FormData(e.currentTarget);void renameCategory(c.id,String(data.get("name")??""))}}><b>{c.sort_order}.</b><input name="name" defaultValue={c.name_ar} maxLength={80} required/><button>حفظ</button><button type="button" className="danger-link" onClick={()=>void removeCategory(c)}>حذف</button></form>)}</div></>}{section==='offers'&&<><form className="admin-panel editor-form" onSubmit={saveOffer}><h2>{editingOffer?"تعديل العرض":"إضافة عرض"}</h2><label>عنوان العرض<input required value={offerTitle} onChange={e=>setOfferTitle(e.target.value)} maxLength={120}/></label><label>التفاصيل<textarea value={offerDescription} onChange={e=>setOfferDescription(e.target.value)} maxLength={1000}/></label><label>يبدأ في<input type="datetime-local" value={offerStart} onChange={e=>setOfferStart(e.target.value)}/></label><label>ينتهي في<input type="datetime-local" value={offerEnd} onChange={e=>setOfferEnd(e.target.value)}/></label><label className="upload-box"><ImagePlus size={22}/>{offerPreview?<img src={offerPreview} alt="معاينة صورة العرض"/>:<span>صورة العرض · JPG، PNG، WebP · حتى 5MB</span>}<input type="file" accept="image/jpeg,image/png,image/webp" onChange={e=>{const f=e.target.files?.[0];if(f){setOfferImage(f);setOfferPreview(URL.createObjectURL(f))}}}/></label><p>العرض يحفظ غير منشور حتى تراجعه وتفعّله.</p><button className="button button-red" disabled={busy}>{busy?'جاري الحفظ...':editingOffer?'حفظ التعديلات':'حفظ العرض'}</button>{editingOffer&&<button type="button" onClick={()=>{setEditingOffer(null);setOfferTitle('');setOfferDescription('');setOfferPreview('');setOfferImage(null)}}>إلغاء التعديل</button>}</form><div className="admin-panel"><h2>العروض ({offers.length})</h2>{offers.map(o=><div className="admin-row" key={o.id}><span>{o.title_ar}{o.is_demo&&<small className="demo-tag">عينة</small>}</span><span>{o.starts_at?new Date(o.starts_at).toLocaleDateString('ar-EG'):''} – {o.ends_at?new Date(o.ends_at).toLocaleDateString('ar-EG'):''}</span><button onClick={()=>editOffer(o)}>تعديل</button><button onClick={()=>void toggleOffer(o,'is_active')}>{o.is_active?'إيقاف':'تفعيل'}</button><button onClick={()=>void toggleOffer(o,'is_published')}>{o.is_published?'إلغاء النشر':'نشر'}</button><button className="danger-link" onClick={()=>void removeOffer(o)}>حذف</button></div>)}</div></>}{section==='testimonials'&&<><form className="admin-panel editor-form" onSubmit={saveTestimonial}><h2>{editingTestimonial?'تعديل شهادة':'إضافة شهادة عميل'}</h2><label>اسم صاحب الشهادة (اختياري)<input value={testimonialName} onChange={e=>setTestimonialName(e.target.value)} maxLength={80}/></label>{testimonialName.trim()&&<label className="check-line"><input type="checkbox" checked={testimonialNameAuthorized} onChange={e=>setTestimonialNameAuthorized(e.target.checked)}/> لدي إذن بنشر هذا الاسم</label>}<label>نص الشهادة<textarea required minLength={8} maxLength={1000} value={testimonialContent} onChange={e=>setTestimonialContent(e.target.value)} rows={4}/></label><label>التقييم (اختياري)<select value={testimonialRating} onChange={e=>setTestimonialRating(e.target.value)}><option value="">بدون تقييم</option>{[1,2,3,4,5].map(n=><option value={n} key={n}>{n} من 5</option>)}</select></label><button className="button button-red" disabled={busy}>{busy?'جاري الحفظ...':editingTestimonial?'حفظ التعديلات':'حفظ الشهادة كمسودة'}</button>{editingTestimonial&&<button type="button" onClick={()=>{setEditingTestimonial(null);setTestimonialName('');setTestimonialNameAuthorized(false);setTestimonialContent('');setTestimonialRating('')}}>إلغاء التعديل</button>}</form><div className="admin-panel"><h2>الشهادات ({testimonials.length})</h2>{!testimonials.length&&<p>لا توجد شهادات حتى الآن. أضف شهادة حقيقية بعد الحصول على إذن نشرها.</p>}{testimonials.map(t=><article className="feedback-row" key={t.id}><div>{t.display_name&&<b>{t.display_name}</b>}<p>{t.content}</p><small>{t.is_published?'منشورة':'مسودة'}{t.rating!==null?' · '+t.rating+' من 5':''}</small></div><button onClick={()=>editTestimonial(t)}>تعديل</button><button onClick={()=>void toggleTestimonial(t)}>{t.is_published?'إلغاء النشر':'نشر'}</button><button className="danger-link" onClick={()=>void removeTestimonial(t)}>حذف</button></article>)}</div></>}</section></main></>
}

export default function App() {
  const path = window.location.pathname.replace(/\/$/,'')
  if (path === '/admin/reset-password') return <PasswordRecovery />
  return path === '/admin' ? <Admin /> : <Landing />
}
