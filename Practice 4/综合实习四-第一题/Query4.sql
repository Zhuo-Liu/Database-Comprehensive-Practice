Select min(M.pub_date) year, G.genres 
From Movies M, Genres G 
Where M.movieID=G.movieID and G.genres="IMAX";