Select avg(R.rating) avg_R, M.pub_date year
From Movies M
Inner Join Ratings R
On M.movieID=R.movieID
Group By year
Order By avg_R desc;