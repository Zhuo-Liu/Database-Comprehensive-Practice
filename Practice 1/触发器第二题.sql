create table my_stock(
    stock_id int identity(1,1) primary key,
    volume int,
    avg_price float,
    profit float
)
go

create table trans(
    trans_id int identity(1,1) primary key,
	stock_id int,
	date_ date,
	price float,
	amount int,
	sell_or_buy int check(sell_or_buy in (0,1)) -- 0:sell,1:buy
)
go

--´¥·¢Æ÷
CREATE TRIGGER UPDATE_MY_STOCK
ON trans
AFTER INSERT
AS
BEGIN
    DECLARE @SELL_OR_BUY INT
	DECLARE @STOCK_ID INT
	DECLARE @PRICE FLOAT
	DECLARE @AMOUNT INT
	DECLARE @AMOUNT_MY INT

    DECLARE @AMOUNT_SOLD INT
    DECLARE @AMOUNT_BUY INT
    DECLARE @NEED_ID INT

    DECLARE @trans_id int
    DECLARE @stock_id1 int
    DECLARE @date_ date
    DECLARE @price1 int
    DECLARE @amount1 int
    DECLARE @tmp_SELL int

	SELECT @STOCK_ID = stock_id FROM inserted
	SELECT @SELL_OR_BUY = sell_or_buy FROM inserted
	SELECT @PRICE = price FROM inserted
	SELECT @AMOUNT = amount FROM inserted
	SELECT @AMOUNT_MY = volume FROM my_stock WHERE stock_id = @STOCK_ID

	IF @SELL_OR_BUY = 1
	BEGIN
	   IF NOT EXISTS (SELECT * FROM my_stock)
	       INSERT INTO my_stock(volume, avg_price, profit) VALUES (1, @PRICE, 0)
	   ELSE
	       UPDATE my_stock SET volume = a.volume + 1
		   FROM my_stock as a, inserted as b
		   WHERE a.stock_id = b.stock_id

		   UPDATE my_stock SET avg_price = (avg_price*volume + b.amount * b.price) / a.volume 
		   FROM my_stock as a, inserted as b
		   WHERE a.stock_id = b.stock_id
	END
	ELSE IF @SELL_OR_BUY = 0
    BEGIN
	   IF @AMOUNT > @AMOUNT_MY
       BEGIN
	       ROLLBACK
       END
       ELSE
       BEGIN
           set @AMOUNT_BUY = (select sum(amount) 
                              from trans
                              where sell_or_buy = 1)
           set @AMOUNT_SOLD = (select sum(amount) 
                               from trans
                               where sell_or_buy = 0 and stock_id = @STOCK_ID)
           set @NEED_ID = 0
           DECLARE cursorPRFED cursor for
               select trans_id, stock_id, date_, price, amount
               from trans
               where sell_or_buy = 1
               order by date_
           OPEN cursorPRFED
           fetch next from cursorPRFED into @trans_id, @stock_id1, @date_, @price1, @amount1
           WHILE @@fetch_status = 0 
           BEGIN
               set @NEED_ID = @NEED_ID + 1
               set @AMOUNT_SOLD = @AMOUNT_SOLD - @amount1
               EXIT when @AMOUNT_SOLD < 0
               fetch next from cursorPRFED into @trans_id, @stock_id1, @date_, @price1, @amount1
           END
           
           WHILE @@fetch_status = 0
           BEGIN
               set @tmp_SELL = @AMOUNT
               IF @tmp_SELL <= -@AMOUNT_SOLD
               BEGIN
                   DECLARE @tmp_PRFT INT
                   SET @tmp_PRFT = (@PRICE - @price1) * @tmp_SELL
                   UPDATE my_stock SET profit = profit + @tmp_PRFT
                   WHERE stock_id = @STOCK_ID
                   set @tmp_SELL = 0
               END
               ELSE
               BEGIN
                   DECLARE @tmp_PRFT INT
                   SET @tmp_PRFT = (@PRICE - @price1) * (-@AMOUNT_SOLD)
                   UPDATE my_stock SET profit = profit + @tmp_PRFT
                   WHERE stock_id = @STOCK_ID
                   set @tmp_SELL = @tmp_SELL + @AMOUNT_SOLD
               END
               EXIT WHEN @tmp_SELL = 0
               fetch next from cursorPRFED into @trans_id, @stock_id, @date_, @price, @amount
               set @AMOUNT_SOLD = -@amount1
           END
           

	       UPDATE my_stock SET volume = a.volume - 1
		   FROM my_stock as a, inserted as b
		   WHERE a.stock_id = b.stock_id

		   UPDATE my_stock SET avg_price = (avg_price*volume - b.amount * b.price) / a.volume 
		   FROM my_stock as a, inserted as b
		   WHERE a.stock_id = b.stock_id
           
           
       END
	END
END
