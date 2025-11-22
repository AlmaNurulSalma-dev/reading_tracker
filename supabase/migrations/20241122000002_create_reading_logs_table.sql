-- Migration: Create reading_logs table
-- Description: Tracks individual reading sessions for each book

-- Create reading_logs table
CREATE TABLE IF NOT EXISTS public.reading_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    pages_read INTEGER NOT NULL DEFAULT 0,
    start_page INTEGER NOT NULL DEFAULT 0,
    end_page INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT pages_read_positive CHECK (pages_read >= 0),
    CONSTRAINT start_page_positive CHECK (start_page >= 0),
    CONSTRAINT end_page_valid CHECK (end_page >= start_page),
    CONSTRAINT pages_read_matches CHECK (pages_read = end_page - start_page)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_reading_logs_user_id ON public.reading_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_logs_book_id ON public.reading_logs(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_logs_date ON public.reading_logs(date DESC);
CREATE INDEX IF NOT EXISTS idx_reading_logs_user_date ON public.reading_logs(user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE public.reading_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Policy: Users can view their own reading logs
CREATE POLICY "Users can view own reading logs"
    ON public.reading_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own reading logs
CREATE POLICY "Users can insert own reading logs"
    ON public.reading_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reading logs
CREATE POLICY "Users can update own reading logs"
    ON public.reading_logs
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reading logs
CREATE POLICY "Users can delete own reading logs"
    ON public.reading_logs
    FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.reading_logs TO authenticated;
GRANT SELECT ON public.reading_logs TO anon;
