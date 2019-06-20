Select min(M.pub_date) year, G.genres
From Genres G
Inner Join Movies M
On M.movieID=G.movieID 
Where G.genres<>"(no genres listed)"
Group By G.genres
Order By year asc;