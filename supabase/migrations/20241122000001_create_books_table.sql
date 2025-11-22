-- Migration: Create books table
-- Description: Stores book information for each user

-- Create books table
CREATE TABLE IF NOT EXISTS public.books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT,
    total_pages INTEGER NOT NULL DEFAULT 0,
    current_page INTEGER NOT NULL DEFAULT 0,
    pdf_url TEXT,
    cover_image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT current_page_valid CHECK (current_page >= 0 AND current_page <= total_pages),
    CONSTRAINT total_pages_positive CHECK (total_pages >= 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_books_user_id ON public.books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON public.books(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_books_title ON public.books(title);

-- Enable Row Level Security
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Policy: Users can view their own books
CREATE POLICY "Users can view own books"
    ON public.books
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own books
CREATE POLICY "Users can insert own books"
    ON public.books
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own books
CREATE POLICY "Users can update own books"
    ON public.books
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own books
CREATE POLICY "Users can delete own books"
    ON public.books
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
CREATE TRIGGER set_books_updated_at
    BEFORE UPDATE ON public.books
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Grant permissions
GRANT ALL ON public.books TO authenticated;
GRANT SELECT ON public.books TO anon;
