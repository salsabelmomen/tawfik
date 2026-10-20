import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'

const { menuItem, supabaseMock, updatePayload, updatedWhere, recoveryListener, setUpdateError, getUpdateError, setUpdateNoRow, getUpdateNoRow } = vi.hoisted(() => {
  let updateError: { code: string; status: number } | null = null
  let updateNoRow = false
  return {
    menuItem: {
      id: 'menu-item-1',
      name_ar: 'جامايكا',
      description_ar: null as string | null,
      price_egp: 200,
      category_id: null as string | null,
      image_path: null,
      is_published: true,
      is_available: true,
      is_demo: false,
      is_featured: false,
      needs_review: false,
      review_note_ar: null,
      variation_ar: [],
    },
    updatePayload: vi.fn(),
    updatedWhere: vi.fn(),
    recoveryListener: { current: null as ((session: unknown) => void) | null },
    setUpdateError: (error: { code: string; status: number } | null) => { updateError = error },
    getUpdateError: () => updateError,
    setUpdateNoRow: (noRow: boolean) => { updateNoRow = noRow },
    getUpdateNoRow: () => updateNoRow,
    supabaseMock: {
      auth: {
        getSession: vi.fn(),
        onAuthStateChange: vi.fn(),
        signOut: vi.fn(),
        resetPasswordForEmail: vi.fn(),
        updateUser: vi.fn(),
      },
      from: vi.fn(),
    },
  }
})

vi.mock('./lib/supabase', () => ({
  supabase: supabaseMock,
  imageUrl: (path: string | null | undefined) => path ?? null,
  subscribeToPasswordRecoverySession: (listener: (session: unknown) => void) => {
    recoveryListener.current = listener
    listener(null)
    return () => { recoveryListener.current = null }
  },
}))

import App from './App'

async function openMenuItemEditor() {
  render(<App />)
  fireEvent.click(await screen.findByRole('button', { name: 'أصناف المنيو' }))
  fireEvent.click(document.querySelector('[data-category-id="__uncategorized__"] button')!)
  const itemRow = (await screen.findByText('جامايكا')).closest<HTMLDivElement>('.admin-row')
  if (!itemRow) throw new Error('Menu item row was not rendered')
  fireEvent.click(within(itemRow).getByRole('button', { name: 'تعديل' }))
  return document.querySelector<HTMLTextAreaElement>('#menu-item-editor textarea')!
}

beforeEach(() => {
  window.history.replaceState({}, '', '/admin')
  Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', { configurable: true, value: vi.fn() })
  menuItem.description_ar = null
  menuItem.category_id = null
  setUpdateError(null)
  setUpdateNoRow(false)
  vi.clearAllMocks()

  supabaseMock.auth.getSession.mockResolvedValue({ data: { session: { user: { id: 'admin-user' } } } })
  supabaseMock.auth.onAuthStateChange.mockReturnValue({ data: { subscription: { unsubscribe: vi.fn() } } })
  supabaseMock.auth.resetPasswordForEmail.mockResolvedValue({ error: null })
  supabaseMock.auth.updateUser.mockResolvedValue({ error: null })
  supabaseMock.auth.signOut.mockResolvedValue({ error: null })
  supabaseMock.from.mockImplementation((table: string) => ({
    select: () => ({
      order: async () => ({ data: table === 'menu_items' ? [{ ...menuItem }] : table === 'categories' ? [{ id: 'category-1', name_ar: 'Category One', sort_order: 1 }] : [], error: null }),
    }),
    update: (payload: Record<string, unknown>) => {
      updatePayload(payload)
        return {
          eq: (column: string, value: string) => ({
            select: () => ({
              single: async () => {
          updatedWhere(column, value)
                const error = getUpdateError()
                if (getUpdateNoRow()) return { data: null, error: { code: 'PGRST116', status: 406 } }
                return { data: error ? null : { id: value }, error }
              },
            }),
          }),
        }
    },
  }))
})

afterEach(() => {
  cleanup()
  window.history.replaceState({}, '', '/')
})

describe('admin menu description updates', () => {
  it('sends only description_ar and filters the update by item id', async () => {
    const descriptionInput = await openMenuItemEditor()
    fireEvent.change(descriptionInput, { target: { value: 'مكونات الصنف' } })
    fireEvent.click(screen.getByRole('button', { name: 'حفظ التعديلات' }))

    await screen.findByRole('status')
    expect(updatePayload).toHaveBeenCalledOnce()
    expect(updatePayload).toHaveBeenCalledWith({ description_ar: 'مكونات الصنف' })
    expect(updatedWhere).toHaveBeenCalledWith('id', 'menu-item-1')
  })

  it('shows an administrative permission error when the update is rejected', async () => {
    setUpdateError({ code: '42501', status: 403 })
    const descriptionInput = await openMenuItemEditor()
    fireEvent.change(descriptionInput, { target: { value: 'مكونات الصنف' } })
    fireEvent.click(screen.getByRole('button', { name: 'حفظ التعديلات' }))

    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('رفضت صلاحيات قاعدة البيانات'))
    expect(updatePayload).toHaveBeenCalledWith({ description_ar: 'مكونات الصنف' })
  })

  it('does not show success when the update returns no row', async () => {
    setUpdateNoRow(true)
    const descriptionInput = await openMenuItemEditor()
    fireEvent.change(descriptionInput, { target: { value: 'مكونات الصنف' } })
    fireEvent.click(screen.getByRole('button', { name: 'حفظ التعديلات' }))

    const notice = await screen.findByRole('status')
    expect(notice).toHaveTextContent('لم يتمكن التطبيق من تأكيد تحديث الوصف')
    expect(notice).not.toHaveTextContent('تم حفظ التعديلات')
    expect(updatePayload).toHaveBeenCalledWith({ description_ar: 'مكونات الصنف' })
    expect(updatedWhere).toHaveBeenCalledWith('id', 'menu-item-1')
  })
})


describe('admin menu category groups', () => {
  it('shows an item under its linked category and counts it once', async () => {
    menuItem.category_id = 'category-1'
    render(<App />)
    fireEvent.click(await screen.findByRole('button', { name: 'أصناف المنيو' }))
    const categoryToggle = await screen.findByRole('button', { name: /Category One/ })
    expect(categoryToggle).toHaveTextContent('1')
    expect(categoryToggle).toHaveAttribute('aria-expanded', 'false')
    fireEvent.click(categoryToggle)
    const item = await screen.findByText(menuItem.name_ar)
    expect(item.closest('[data-category-id]')).toHaveAttribute('data-category-id', 'category-1')
    expect(screen.getAllByText(menuItem.name_ar)).toHaveLength(1)
  })

  it('places items without a category in the separate uncategorized group', async () => {
    render(<App />)
    fireEvent.click(await screen.findByRole('button', { name: 'أصناف المنيو' }))
    const uncategorizedGroup = document.querySelector<HTMLElement>('[data-category-id="__uncategorized__"]')!
    const uncategorizedToggle = within(uncategorizedGroup).getByRole('button')
    expect(uncategorizedToggle).toHaveTextContent('1')
    fireEvent.click(uncategorizedToggle)
    const item = await screen.findByText(menuItem.name_ar)
    expect(item.closest('[data-category-id]')).toHaveAttribute('data-category-id', '__uncategorized__')
  })
})
describe('admin password recovery', () => {
  it('sends a reset email to the callback route without revealing whether the address exists', async () => {
    supabaseMock.auth.getSession.mockResolvedValue({ data: { session: null } })
    render(<App />)

    fireEvent.click(await screen.findByRole('button', { name: 'نسيت كلمة المرور؟' }))
    const emailInput = screen.getByLabelText('البريد الإلكتروني')
    fireEvent.change(emailInput, { target: { value: 'admin@example.com' } })
    fireEvent.click(screen.getByRole('button', { name: 'إرسال رابط الاستعادة' }))

    const notice = await screen.findByRole('status')
    expect(notice).toHaveTextContent('إذا كان البريد مرتبطًا بحساب')
    expect(notice).not.toHaveTextContent('admin@example.com')
    expect(supabaseMock.auth.resetPasswordForEmail).toHaveBeenCalledWith('admin@example.com', {
      redirectTo: 'http://localhost:3000/admin/reset-password',
    })
  })

  it('does not show a password form without a verified recovery session', async () => {
    window.history.replaceState({}, '', '/admin/reset-password')
    render(<App />)

    expect(await screen.findByText(/رابط الاستعادة غير صالح أو انتهت صلاحيته/)).toBeInTheDocument()
    expect(screen.queryByLabelText('كلمة المرور الجديدة')).not.toBeInTheDocument()
    expect(supabaseMock.auth.updateUser).not.toHaveBeenCalled()
  })

  it('updates the password only after a recovery event and a matching active session', async () => {
    window.history.replaceState({}, '', '/admin/reset-password')
    const recoverySession = { access_token: 'recovery-session', user: { id: 'admin-user' } }
    supabaseMock.auth.getSession.mockResolvedValue({ data: { session: recoverySession } })
    render(<App />)
    await act(async () => { recoveryListener.current?.(recoverySession) })

    fireEvent.change(await screen.findByLabelText('كلمة المرور الجديدة'), { target: { value: 'new-secret-password' } })
    fireEvent.change(screen.getByLabelText('تأكيد كلمة المرور'), { target: { value: 'new-secret-password' } })
    fireEvent.click(screen.getByRole('button', { name: 'حفظ كلمة المرور الجديدة' }))

    expect(await screen.findByRole('status')).toHaveTextContent('تم تغيير كلمة المرور')
    expect(supabaseMock.auth.updateUser).toHaveBeenCalledWith({ password: 'new-secret-password' })
    expect(supabaseMock.auth.signOut).toHaveBeenCalledWith({ scope: 'local' })
  })
})
