Select count(M.title)
From Movies M
Where not exists (
    Select R.movieID From Ratings R
    Where R.movieID=M.movieID and R.rating>=4.0
);