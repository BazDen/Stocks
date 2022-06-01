-- Прилипала. Автор: Денис Базарнов, 2020 год. 
-- сайт: КБС.Онлайн
-- почта: kbs.online.service@gmail.com
-- Telegram: @BazDen

big_qty = 30 -- ВО СКОЛЬКО РАЗ количество текущей сделки должно превышать среднее количество, чтобы считать сделку крупной

color_white = RGB(255, 255, 255)
color_green = RGB(10, 155, 10)
color_red = RGB(155, 10, 10)

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

function math_round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function OnAllTrade(Trade)
	local curTrade = {}
	local Find = false
	curTrade = {
		ticket = Trade.sec_code, 
		price = Trade.price, 
		cnt = 1, -- количество сделок
		qty = Trade.qty, -- количество в текущей сделке
		value = Trade.value, 
		all_qty = Trade.qty,
		avg_qty = 1,
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
		trend_big_sell = 0,
		last_change = getParamEx(Trade.class_code, Trade.sec_code, "LASTCHANGE").param_value,
		timer_last_min = os.time(),
		speed_last_min = 0,
		speed_prelast_min = 0
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
				Trades[i].cnt = Trades[i].cnt + 1
				Trades[i].all_qty = Trades[i].all_qty + Trade.qty
				Trades[i].avg_qty = math.ceil(Trades[i].all_qty / Trades[i].cnt)
				Trades[i].value = Trades[i].value + curTrade.value		
				Trades[i].avg_value = math.ceil(Trades[i].value / Trades[i].cnt)
				Trades[i].buy = Trades[i].buy + curTrade.buy
				Trades[i].sell = Trades[i].sell + curTrade.sell	
				Trades[i].last_change = math_round(curTrade.last_change, 2)
				if (tonumber(os.time() - Trades[i].timer_last_min) >= 60) then
					Trades[i].timer_last_min = os.time()
					Trades[i].speed_prelast_min = Trades[i].speed_last_min
					Trades[i].speed_last_min = 1
				else
					Trades[i].speed_last_min = Trades[i].speed_last_min + 1
				end
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
		   InsertRow(SimpleView, -1)
	   end
	else
		Trades[#Trades+1] = curTrade
		InsertRow(SimpleView, -1)
	end
	TradesSort()
	for i=1,#Trades do
		SetCell(SimpleView, i, 1, Trades[i].ticket)
		SetCell(SimpleView, i, 2, tostring(Trades[i].price))
		if (tonumber(Trades[i].last_change) == 0) then
			SetCell(SimpleView, i, 3, " ")
		else
			SetCell(SimpleView, i, 3, tostring(Trades[i].last_change))
		end	
		if (tonumber(Trades[i].trend_all_buy) == 0) then
			SetCell(SimpleView, i, 4, ' ')
		else
			SetCell(SimpleView, i, 4, tostring(Trades[i].trend_all_buy)..'%')
		end	
		if (tonumber(Trades[i].trend_all_sell) == 0) then
			SetCell(SimpleView, i, 5, ' ')
		else
			SetCell(SimpleView, i, 5, tostring(Trades[i].trend_all_sell)..'%')
		end	
		if (tonumber(Trades[i].trend_big_buy) == 0) then
			SetCell(SimpleView, i, 6, ' ')
		else
			SetCell(SimpleView, i, 6, tostring(Trades[i].trend_big_buy)..'%')
		end
		if (tonumber(Trades[i].trend_big_sell) == 0) then
			SetCell(SimpleView, i, 7, ' ')
		else
			SetCell(SimpleView, i, 7, tostring(Trades[i].trend_big_sell)..'%')
		end	
		--SetCell(SimpleView, i, 8, tostring(Trades[i].avg_qty))
		--SetCell(SimpleView, i, 9, tostring(Trades[i].speed_prelast_min)..'/min')
		SetCell(SimpleView, i, 10, tostring(Trades[i].speed_last_min)..'/min')
		if (tonumber(Trades[i].last_change) > 0) then
			 SetColor(SimpleView, i, 3, color_green, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		elseif (tonumber(Trades[i].last_change) < 0) then
			SetColor(SimpleView, i, 3, color_red, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			SetColor(SimpleView, i, 3, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)	
		end
		if (Trades[i].trend_all_buy > Trades[i].trend_all_sell) then
			SetColor(SimpleView, i, 4, color_green, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			SetColor(SimpleView, i, 5, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			if (Trades[i].trend_all_sell>0) then
				SetColor(SimpleView, i, 5, color_red, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
				SetColor(SimpleView, i, 4, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			end
		end
		if (Trades[i].trend_big_buy > Trades[i].trend_big_sell) then
			if (Trades[i].trend_big_buy>=1) then
				SetColor(SimpleView, i, 6, color_green, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			else
				SetColor(SimpleView, i, 6, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			end	
			SetColor(SimpleView, i, 7, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			if (Trades[i].trend_big_sell>1) then
				SetColor(SimpleView, i, 7, color_red, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			else
				SetColor(SimpleView, i, 7, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
			end	
			SetColor(SimpleView, i, 6, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		end
		if (Trades[i].speed_last_min > Trades[i].speed_prelast_min) then
			SetColor(SimpleView, i, QTABLE_NO_INDEX, RGB(150, 150, 150), RGB(0, 0, 0), QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			SetColor(SimpleView, i, QTABLE_NO_INDEX, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		end
	end
end

function OnInit(path)
	AddColumn(SimpleView, 1, "Тикер", true, QTABLE_STRING_TYPE, 10)
	AddColumn(SimpleView, 2, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(SimpleView, 3, "Изм.цены, %", true, QTABLE_STRING_TYPE, 12)
	AddColumn(SimpleView, 4, "Покупка, доля всех сделок", true, QTABLE_STRING_TYPE, 12)
	AddColumn(SimpleView, 5, "Продажа, доля всех сделок", true, QTABLE_STRING_TYPE, 20)
	AddColumn(SimpleView, 6, "Покупка, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
	AddColumn(SimpleView, 7, "Продажа, доля б.сделок", true, QTABLE_STRING_TYPE, 18)
	--AddColumn(SimpleView, 8, "Ср. кол-во", true, QTABLE_STRING_TYPE, 12)
	--AddColumn(SimpleView, 9, "Ср. скорость(сделок/в минуту)", true, QTABLE_STRING_TYPE, 18)
	AddColumn(SimpleView, 10, "Скорость (текущая)", true, QTABLE_STRING_TYPE, 18)
	
	CreateWindow(SimpleView)
	SetWindowCaption(SimpleView, "Прилипала Pro 1.1")
end

function OnStop(signal) 
	stopped = true 
end

function OnClose() 
	stopped = true 
end

function LoadOneTrade(Trade)
	local curTrade = {}
	local Find = false
	curTrade = {
		ticket = Trade.sec_code, 
		price = Trade.price, 
		cnt = 1, -- количество сделок
		value = Trade.value, -- объем
		avg_qty = 1, -- среднее количество в сделке
		all_qty = Trade.qty, -- общее количество
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
		trend_big_sell = 0,
		last_change = 0,
		timer_last_min = 0,
		speed_last_min = 0,
		speed_prelast_min = 0
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
				Trades[i].cnt = Trades[i].cnt + 1
				Trades[i].all_qty = Trades[i].all_qty + Trade.qty
				Trades[i].avg_qty = math.ceil(Trades[i].all_qty / Trades[i].cnt)
				Trades[i].value = Trades[i].value + curTrade.value		
				Trades[i].avg_value = math.ceil(Trades[i].value / Trades[i].cnt)
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
		   InsertRow(SimpleView, -1)
	   end
	else
		Trades[#Trades+1] = curTrade
		InsertRow(SimpleView, -1)
	end
	TradesSort()
	return true
end

function LoadTrades()
	SearchItems("all_trades", 0, getNumberOf("all_trades")-1, LoadOneTrade)
end

function main()
	message("Ждите, идет загрузка обезличенных сделок за день")
	LoadTrades()
	message("Загрузка обезличенных сделок завершена")
	-- message("В течение минуты таблицу поколбасит, т.к. происходит сортировка, потом можно работать")
	while not stopped 
		do sleep(1000) 
	end
end