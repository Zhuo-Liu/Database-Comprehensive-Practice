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
	sell_or_buy int check(sell_or_buy in (0,1)) -- 0ÊÇsell£¬1ÊÇbuy
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
		   FROM my_stock a, inserted b
		   WHERE a.stock_id = b.stock_id

		   UPDATE my_stock SET avg_price = (avg_price*volume + b.amount * b.price) / a.volume 
		   FROM my_stock a, inserted b
		   WHERE a.stock_id = b.stock_id
	END
	ELSE IF @SELL_OR_BUY = 0
    BEGIN
	   IF @AMOUNT > @AMOUNT_MY
	       ROLLBACK
       ELSE
	       UPDATE my_stock SET volume = a.volume - 1
		   FROM my_stock a, inserted b
		   WHERE a.stock_id = b.stock_id

		   UPDATE my_stock SET avg_price = (avg_price*volume - b.amount * b.price) / a.volume 
		   FROM my_stock a, inserted b
		   WHERE a.stock_id = b.stock_id
	END
END