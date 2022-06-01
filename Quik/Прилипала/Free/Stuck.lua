-- Прилипала. Автор: Денис Базарнов, 2020 год. 
-- сайт: КБС.Онлайн
-- почта: kbs.online.service@gmail.com
-- Telegram: @BazDen

big_qty = 30 -- ВО СКОЛЬКО РАЗ количество текущей сделки должно превышать среднее количество, чтобы считать сделку крупной

color_price = RGB(236, 207, 234)
color_ticket = RGB(253, 249, 219)
color_big = RGB(155, 117, 117)
color_white = RGB(255, 255, 255)

stopped = false
Trades = {}
View = AllocTable()
SimpleView = AllocTable()
function TradesSort()
-- примитивная, но быстрая сортировка. Да, всего одна итерация, но при следующем срабатывании OnAllTrade сортировка повторится
	if (#Trades > 3) then
		for i=2,#Trades do
			A = string.sub(Trades[i-1].ticket, 1,1)
			B = string.sub(Trades[i].ticket, 1,1)
			if (A>B) then
				TradeA = Trades[i-1]
				TradeB = Trades[i]
				Trades[i-1] = TradeB
				Trades[i] = TradeA
			end	
		end
	end
end

function OnAllTrade(Trade)
	local curTrade = {}
	local Find = false
	curTrade = {
		ticket = Trade.sec_code, 
		price = Trade.price, 
		qty = 1, 
		value = Trade.value, 
		avg_qty = Trade.value,
		buy = 0,
		sell = 0,
		big_qty = 0,
		big_value = 0,
		big_avg_qty = 0,
		big_part = 0,
		big_buy = 0,
		big_sell = 0,
		trend_all_buy = 0,
		trend_all_sell = 0,
		trend_big_buy = 0,
		trend_big_sell = 0
		}
		if bit.band(Trade.flags, 0x2) == 0x2 then
			curTrade.buy = Trade.value
			curTrade.sell = 0
		elseif bit.band(Trade.flags, 0x1) == 0x1 then
			curTrade.buy = 0
			curTrade.sell = Trade.value
		end
	if (#Trades>0) then
	   Find = false
	   for i=1,#Trades do
			if Trades[i].ticket == curTrade.ticket then
				Find = true
				Trades[i].price = curTrade.price
				Trades[i].qty = Trades[i].qty + curTrade.qty
				Trades[i].value = Trades[i].value + curTrade.value		
				Trades[i].avg_value = math.ceil(Trades[i].value / Trades[i].qty)
				Trades[i].buy = Trades[i].buy + curTrade.buy
				Trades[i].sell = Trades[i].sell + curTrade.sell	
				
				if (Trades[i].avg_value*big_qty) < curTrade.value then
					Trades[i].big_qty = Trades[i].big_qty + 1
					Trades[i].big_value = Trades[i].big_value + curTrade.value
					Trades[i].big_avg_qty = math.floor(Trades[i].big_value / Trades[i].big_qty)
					Trades[i].big_part = math.floor(Trades[i].big_value/Trades[i].value*100)
					Trades[i].big_buy = Trades[i].big_buy + curTrade.buy
					Trades[i].big_sell = Trades[i].big_sell + curTrade.sell
					Trades[i].trend_big_buy = math.floor(Trades[i].big_buy/Trades[i].value*100)
					Trades[i].trend_big_sell = math.floor(Trades[i].big_sell/Trades[i].value*100)
				end	
				Trades[i].trend_all_buy = math.floor(Trades[i].buy/Trades[i].value*100)
				Trades[i].trend_all_sell = math.floor(Trades[i].sell/Trades[i].value*100)
			end
	   end
	   if Find == false then
		   Trades[#Trades+1] = curTrade
	   end
	else
		Trades[#Trades+1] = curTrade
	end
	TradesSort()
	Clear(View)
	Clear(SimpleView)
	for i=1,#Trades do
		curRow = InsertRow(View, -1)
		SetCell(View, curRow, 1, Trades[i].ticket)
		SetCell(View, curRow, 2, tostring(Trades[i].price))
		SetCell(View, curRow, 3, tostring(Trades[i].qty))
		SetCell(View, curRow, 4, tostring(Trades[i].value))
		SetCell(View, curRow, 5, tostring(Trades[i].avg_value))
		SetCell(View, curRow, 6, tostring(Trades[i].buy))
		SetCell(View, curRow, 7, tostring(Trades[i].sell))
		SetCell(View, curRow, 8, tostring(Trades[i].big_qty))
		SetCell(View, curRow, 9, tostring(Trades[i].big_value))
		SetCell(View, curRow, 10, tostring(Trades[i].big_avg_qty))
		SetCell(View, curRow, 11, tostring(Trades[i].big_part)..'%')
		SetCell(View, curRow, 12, tostring(Trades[i].big_buy))
		SetCell(View, curRow, 13, tostring(Trades[i].big_sell))
		SetCell(View, curRow, 14, tostring(Trades[i].trend_all_buy)..'%')
		SetCell(View, curRow, 15, tostring(Trades[i].trend_all_sell)..'%')
		SetCell(View, curRow, 16, tostring(Trades[i].trend_big_buy)..'%')
		SetCell(View, curRow, 17, tostring(Trades[i].trend_big_sell)..'%')
		curRow = InsertRow(SimpleView, -1)
		SetCell(SimpleView, curRow, 1, Trades[i].ticket)
		SetCell(SimpleView, curRow, 2, tostring(Trades[i].price))
		SetCell(SimpleView, curRow, 3, tostring(Trades[i].trend_all_buy)..'%')
		SetCell(SimpleView, curRow, 4, tostring(Trades[i].trend_all_sell)..'%')
		SetCell(SimpleView, curRow, 5, tostring(Trades[i].trend_big_buy)..'%')
		SetCell(SimpleView, curRow, 6, tostring(Trades[i].trend_big_sell)..'%')
		
		if (Trades[i].trend_all_buy > Trades[i].trend_all_sell) then
			SetColor(SimpleView, curRow, 3, RGB(10, 255 - Trades[i].trend_all_buy*2, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			SetColor(View, curRow, 14, RGB(10, 255 - Trades[i].trend_all_buy*2, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			if (Trades[i].trend_all_sell>0) then
				SetColor(SimpleView, curRow, 4, RGB(255-Trades[i].trend_all_sell*2, 10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
				SetColor(View, curRow, 15, RGB(255-Trades[i].trend_all_sell*2, 10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			end
		end
		if (Trades[i].trend_big_buy > Trades[i].trend_big_sell) then
			SetColor(SimpleView, curRow, 5, RGB(10, 255-Trades[i].trend_big_buy*2, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			SetColor(View, curRow, 16, RGB(10, 255-Trades[i].trend_big_buy*2, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			if (Trades[i].trend_big_sell>0) then
				SetColor(SimpleView, curRow, 6, RGB(255-Trades[i].trend_big_sell*2, 10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
				SetColor(View, curRow, 17, RGB(255-Trades[i].trend_big_sell*2, 10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			end
		end
	end
end

function OnInit(path)
	AddColumn(View, 1, "Тикер", true, QTABLE_STRING_TYPE, 10)

	AddColumn(View, 2, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 3, "Сделки, кол-во", true, QTABLE_STRING_TYPE, 5)
	AddColumn(View, 4, "Объем", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 5, "Ср. объем", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 6, "Покупка", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 7, "Продажа", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 8, "Б.сделки, кол-во", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 9, "Б.сделки, объем", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 10, "Б.сделки, ср. кол-во", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 11, "Б.сделки, доля в общем объеме", true, QTABLE_STRING_TYPE, 20)
	AddColumn(View, 12, "Б.сделки, покупка", true, QTABLE_STRING_TYPE, 18)
	AddColumn(View, 13, "Б.сделки, продажа", true, QTABLE_STRING_TYPE, 18)
	AddColumn(View, 14, "Покупка, доля всех сделок", true, QTABLE_STRING_TYPE, 12)
	AddColumn(View, 15, "Продажа, доля всех сделок", true, QTABLE_STRING_TYPE, 20)
	AddColumn(View, 16, "Покупка, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
	AddColumn(View, 17, "Продажа, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
		
	CreateWindow(View)
	SetColor(View, QTABLE_NO_INDEX, 1, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 2, color_price, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 3, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 4, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 5, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 6, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 7, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 8, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 9, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 10, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 11, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 12, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 13, color_big, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetWindowCaption(View, "Прилипала (свод) Free 1.0")
	AddColumn(SimpleView, 1, "Тикер", true, QTABLE_STRING_TYPE, 10)
	AddColumn(SimpleView, 2, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(SimpleView, 3, "Покупка, доля всех сделок", true, QTABLE_STRING_TYPE, 12)
	AddColumn(SimpleView, 4, "Продажа, доля всех сделок", true, QTABLE_STRING_TYPE, 20)
	AddColumn(SimpleView, 5, "Покупка, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
	AddColumn(SimpleView, 6, "Продажа, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
	CreateWindow(SimpleView)
	SetColor(SimpleView, QTABLE_NO_INDEX, 1, color_ticket, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(SimpleView, QTABLE_NO_INDEX, 2, color_price, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetWindowCaption(SimpleView, "Прилипала (сокращенная ) Free 1.0")
end

function OnStop(signal) 
	stopped = true 
end

function OnClose() 
	stopped = true 
end

function main()
	
	while not stopped 
		do sleep(10) 
	end
end