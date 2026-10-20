import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import App, { Offers } from './App'
import { initialItems } from './data'
import type { Offer } from './lib/supabase'

vi.mock('./lib/supabase', () => ({
  supabase: null,
  imageUrl: (path: string | null | undefined) => path ?? null,
}))

afterEach(() => { cleanup(); window.history.replaceState({}, '', '/'); window.sessionStorage.removeItem('wesaya-intro-seen') })
describe('restaurant landing page', () => {
  it('renders the verified hotline and individual menu cards without original menu imagery', () => {
    const { container } = render(<App />)
    expect(screen.getByRole('heading', { name: /وصاية توفيق/ })).toBeInTheDocument()
    expect(screen.getAllByText(/15801/).length).toBeGreaterThan(0)
    expect(container.querySelectorAll('#menu .item-card')).toHaveLength(12)
    expect(container.querySelector('.menu-scans')).not.toBeInTheDocument()
    expect(container.querySelectorAll('img[src*="menu-pizza-sides"], img[src*="menu-hot-sandwiches"]')).toHaveLength(0)
    expect(container.querySelector('header .brand-mark-image')).toHaveAttribute('src', '/menu-images/brand-hotline.jpeg')
    expect(container.querySelector('.hero img[src="/menu-images/brand-hotline.jpeg"]')).not.toBeInTheDocument()
    expect(container.textContent).not.toContain('كل لقمة معمولة بحب')
    expect(container.textContent).not.toContain('اكتشف الحكاية')
    expect(container.textContent).not.toContain('بيحط قلب')
    expect(container.textContent).toContain('وصاية توفيق')
    expect(container.textContent).toContain('طعم ❤️ حتحبه')
    expect(screen.getAllByText('حكاية طعم').length).toBeGreaterThan(0)
    expect(screen.getByRole('heading', { name: 'كل أكلة ليها وصاية' })).toBeInTheDocument()
    expect(screen.getByText('شايف حاجة نفسك تجربها؟ كلمنا على الخط الساخن.')).toBeInTheDocument()
  })
  it('shows the intro on every page load even if an old session flag exists', () => {
    window.sessionStorage.setItem('wesaya-intro-seen', '1')
    const { container } = render(<App />)
    expect(container.querySelector('.intro')).toBeInTheDocument()
  })
  it('filters the original-menu transcription by category', () => {
    render(<App />)
    fireEvent.click(screen.getByRole('button', { name: 'بيتزا' }))
    expect(screen.getByRole('heading', { name: 'منيو وصاية' })).toBeInTheDocument()
    expect(document.querySelector('#menu .item-card h3')).toBeInTheDocument()
    expect(screen.queryByText('توفيق سلاد')).not.toBeInTheDocument()
    expect(document.querySelectorAll('#menu .item-card')).toHaveLength(8)
  })
  it('shows a manageable menu and removes the featured section', () => {
    const { container } = render(<App />)
    expect(container.querySelectorAll('#menu .item-card')).toHaveLength(12)
    expect(container.querySelectorAll('#menu .item-description')).toHaveLength(12)
    expect(screen.getByRole('button', { name: 'عرض المزيد' })).toBeInTheDocument()
    expect(container.querySelector('#featured')).not.toBeInTheDocument()
    expect(document.querySelector('a[href="#featured"]')).not.toBeInTheDocument()
    while (screen.queryByRole('button', { name: 'عرض المزيد' })) fireEvent.click(screen.getByRole('button', { name: 'عرض المزيد' }))
    expect(container.querySelectorAll('#menu .item-card')).toHaveLength(86)
  })

  it('renders only active published unexpired offers as menu-style cards', () => {
    const offers: Offer[] = [
      { id: 'current', title_ar: 'Test offer', description_ar: 'Offer details', image_path: '/offer.jpg', starts_at: null, ends_at: '2099-12-31T23:59:00.000Z', is_active: true, is_published: true, is_demo: false },
      { id: 'expired', title_ar: 'Expired offer', description_ar: null, image_path: null, starts_at: null, ends_at: '2000-01-01T00:00:00.000Z', is_active: true, is_published: true, is_demo: false },
      { id: 'draft', title_ar: 'Draft offer', description_ar: null, image_path: null, starts_at: null, ends_at: null, is_active: true, is_published: false, is_demo: false },
      { id: 'inactive', title_ar: 'Inactive offer', description_ar: null, image_path: null, starts_at: null, ends_at: null, is_active: false, is_published: true, is_demo: false },
    ]
    const { container } = render(<Offers offers={offers} />)
    expect(container.querySelectorAll('#offers .item-card')).toHaveLength(1)
    expect(screen.getByRole('heading', { name: 'Test offer' })).toBeInTheDocument()
    expect(screen.getByText('Offer details')).toBeInTheDocument()
    expect(container.querySelector('#offers img')).toHaveAttribute('src', '/offer.jpg')
    expect(container.querySelector('#offers .offer-validity')).toBeInTheDocument()
    expect(screen.queryByText('Expired offer')).not.toBeInTheDocument()
    expect(screen.queryByText('Draft offer')).not.toBeInTheDocument()
    expect(screen.queryByText('Inactive offer')).not.toBeInTheDocument()
  })

  it('renders the exact slogan and has no public testimonial submission form', () => {
    const { container } = render(<App />)
    expect(screen.getAllByText('طعم ❤️ حتحبه').length).toBeGreaterThan(0)
    expect(screen.queryByLabelText('رأيك في وصاية')).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /ابعت رأيك|أرسل رأيك/ })).not.toBeInTheDocument()
    expect(container.querySelectorAll('main form')).toHaveLength(0)
    expect(screen.getByText('لا توجد شهادات نصية منشورة حاليًا.')).toBeInTheDocument()
  })
  it('shows the supplied feedback images and supports lightbox navigation and keyboard dismissal', async () => {
    const { container } = render(<App />)
    const galleryImages = container.querySelectorAll('#testimonials .feedback-carousel-set:first-child img')
    expect(galleryImages).toHaveLength(5)
    expect(galleryImages[0]).toHaveAttribute('src', '/feedback-01.jpeg')
    expect(galleryImages[4]).toHaveAttribute('src', '/feedback-05.jpeg')
    expect(container.querySelectorAll('#testimonials .feedback-carousel-set[aria-hidden="true"] img')).toHaveLength(5)
    expect(screen.getByRole('heading', { name: 'آراء عملائنا ❤️' })).toBeInTheDocument()
    expect(screen.getByText('كل رأي بيفرق معانا، وشكرًا إنكم جزء من لَمّتنا')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'عرض صورة رأي العميل 1 بحجم أكبر' }))
    expect(screen.getByRole('dialog', { name: 'معرض صور آراء العملاء المكبر' })).toBeInTheDocument()
    expect(screen.getByRole('img', { name: 'صورة رأي عميل 1 بحجم أكبر' })).toHaveAttribute('src', '/feedback-01.jpeg')
    fireEvent.click(screen.getByRole('button', { name: 'الصورة التالية' }))
    expect(screen.getByRole('img', { name: 'صورة رأي عميل 2 بحجم أكبر' })).toHaveAttribute('src', '/feedback-02.jpeg')
    fireEvent.keyDown(window, { key: 'ArrowLeft' })
    expect(screen.getByRole('img', { name: 'صورة رأي عميل 3 بحجم أكبر' })).toHaveAttribute('src', '/feedback-03.jpeg')
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    await waitFor(() => expect(screen.getByRole('button', { name: 'عرض صورة رأي العميل 1 بحجم أكبر' })).toHaveFocus())

    const duplicateImage = container.querySelector('#testimonials .feedback-carousel-set[aria-hidden="true"] .feedback-gallery-card')
    expect(duplicateImage).toBeInTheDocument()
    fireEvent.click(duplicateImage!)
    expect(screen.getByRole('dialog', { name: 'معرض صور آراء العملاء المكبر' })).toBeInTheDocument()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })
  it('renders all 86 transcribed rows from both menu pages and flags uncertain text', () => {
    const { container } = render(<App />)
    expect(initialItems).toHaveLength(86)
    expect(new Set(initialItems.map(item => item.source_page))).toEqual(new Set([1, 2]))
    expect(initialItems.filter(item => item.source_page === 1)).toHaveLength(43)
    expect(initialItems.filter(item => item.source_page === 2)).toHaveLength(43)
    expect(initialItems.filter(item => item.needs_review)).toHaveLength(26)
    expect(initialItems.filter(item => !item.needs_review)).toHaveLength(60)
    expect(container.querySelectorAll('#menu .item-card')).toHaveLength(12)
  })
})

describe('admin route', () => {
  it('shows setup guidance without database credentials', () => {
    window.history.replaceState({}, '', '/admin')
    render(<App />)
    expect(screen.getByRole('heading', { name: 'إدارة وصاية' })).toBeInTheDocument()
    expect(screen.getByText(/\.env.local/)).toBeInTheDocument()
  })
})
