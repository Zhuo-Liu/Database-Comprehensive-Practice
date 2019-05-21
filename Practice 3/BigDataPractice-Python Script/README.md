# 爬虫实习


## 数据获取
`get_data.py`

首先我们从`http://www.cbooo.cn/cinemaweek`这个网址上找到我们要获取的信息（影院票房-周票房排行榜）。通过对其HTTP请求分析我们发现其网址上所有数据均通过
`http://www.cbooo.cn/BoxOffice/getCBW?pIndex={}&dt={}`这个api获取。
因此我们只需要伪造HTTP的get请求，即可拿到数据，即`get_data()`函数所实现的功能。然后我们使用`insert()`函数将爬取的数据插入到数据库表中，以便后续数据分析使用。
数据库的建表语句为`create.sql`。


## 数据可视化
`visualize.py`

这里我们编写了三个数据分析的实例，分别为数据分布图、平均票价信息图以及地域票房信息图，均使用matplotlib库实现。其中地域票房信息图还使用了基于jieba分词的地域查询包cpca，可以直接返回中文地址对应的省市县。