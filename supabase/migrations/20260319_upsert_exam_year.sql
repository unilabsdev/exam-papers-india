-- Helper called by the on-storage-upload edge function.
-- Inserts a new exam_year row or increments paper_count if it already exists.

create or replace function upsert_exam_year(
  p_exam_id    text,
  p_year       int,
  p_paper_count int default 1
) returns void language plpgsql security definer as $$
begin
  insert into exam_years (exam_id, year, paper_count, is_latest)
  values (p_exam_id, p_year, p_paper_count, false)
  on conflict (exam_id, year) do update
    set paper_count = exam_years.paper_count + p_paper_count;

  -- Mark the latest year for this exam
  update exam_years
  set    is_latest = (year = (
           select max(year) from exam_years where exam_id = p_exam_id
         ))
  where  exam_id = p_exam_id;
end;
$$;
