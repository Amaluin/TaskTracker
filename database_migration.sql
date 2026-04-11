-- Migration to add task assignment and postponement features
-- Run this SQL in your Supabase SQL editor

-- Add new columns to tasks table
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to_user_id TEXT,
ADD COLUMN IF NOT EXISTS assigned_to_user_name TEXT,
ADD COLUMN IF NOT EXISTS postponed_until TIMESTAMP WITH TIME ZONE;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_user_id ON tasks(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_postponed_until ON tasks(postponed_until);

-- Add comments for documentation
COMMENT ON COLUMN tasks.assigned_to_user_id IS 'ID пользователя, ответственного за задачу';
COMMENT ON COLUMN tasks.assigned_to_user_name IS 'Имя пользователя, ответственного за задачу';
COMMENT ON COLUMN tasks.postponed_until IS 'Дата и время, на которое отложена задача';
