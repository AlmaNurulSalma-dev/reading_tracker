-- Migration: Create daily_reading_stats table
-- Description: Aggregated daily reading statistics per user

-- Create daily_reading_stats table
CREATE TABLE IF NOT EXISTS public.daily_reading_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_pages_read INTEGER NOT NULL DEFAULT 0,
    books_read_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT total_pages_positive CHECK (total_pages_read >= 0),
    CONSTRAINT books_count_positive CHECK (books_read_count >= 0),
    -- Ensure one record per user per day
    CONSTRAINT unique_user_date UNIQUE (user_id, date)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_daily_stats_user_id ON public.daily_reading_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_stats_date ON public.daily_reading_stats(date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_stats_user_date ON public.daily_reading_stats(user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE public.daily_reading_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Policy: Users can view their own daily stats
CREATE POLICY "Users can view own daily stats"
    ON public.daily_reading_stats
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own daily stats
CREATE POLICY "Users can insert own daily stats"
    ON public.daily_reading_stats
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own daily stats
CREATE POLICY "Users can update own daily stats"
    ON public.daily_reading_stats
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own daily stats
CREATE POLICY "Users can delete own daily stats"
    ON public.daily_reading_stats
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to auto-update updated_at (reusing function from books migration)
CREATE TRIGGER set_daily_stats_updated_at
    BEFORE UPDATE ON public.daily_reading_stats
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Grant permissions
GRANT ALL ON public.daily_reading_stats TO authenticated;
GRANT SELECT ON public.daily_reading_stats TO anon;

-- Create function to update daily stats when reading log is inserted
CREATE OR REPLACE FUNCTION public.update_daily_stats_on_log()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert or update daily stats
    INSERT INTO public.daily_reading_stats (user_id, date, total_pages_read, books_read_count)
    VALUES (
        NEW.user_id,
        NEW.date,
        NEW.pages_read,
        1
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        total_pages_read = daily_reading_stats.total_pages_read + EXCLUDED.total_pages_read,
        books_read_count = (
            SELECT COUNT(DISTINCT book_id)
            FROM public.reading_logs
            WHERE user_id = NEW.user_id AND date = NEW.date
        ),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-update daily stats when reading log is inserted
CREATE TRIGGER update_daily_stats_after_log
    AFTER INSERT ON public.reading_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_daily_stats_on_log();

-- Create function to update book's current_page when reading log is inserted
CREATE OR REPLACE FUNCTION public.update_book_progress_on_log()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the book's current_page to the end_page of the reading log
    UPDATE public.books
    SET current_page = GREATEST(current_page, NEW.end_page)
    WHERE id = NEW.book_id AND user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-update book progress
CREATE TRIGGER update_book_progress_after_log
    AFTER INSERT ON public.reading_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_book_progress_on_log();
