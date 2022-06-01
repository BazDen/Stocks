-- Подстаканник. Автор: Денис Базарнов, 2020 год. 
-- сайт: КБС.Онлайн
-- почта: kbs.online.service@gmail.com
-- Telegram: @BazDen

MultiQty = 3 -- во сколько раз Объем по отдельной позиции в стакане должен быть выше среднего объема по стакану, чтобы попасть в сводну таблицу 
ClassFilter = 'TQBR'


color_green = RGB(150, 200, 150)
color_red = RGB(200, 150, 150)
color_white = RGB(255, 255, 255)
View = AllocTable()
Shares = {}

function SharesSort()
-- примитивная, но быстрая сортировка. Да, всего одна итерация, но при следующем срабатывании OnParam сортировка повторится
	if (#Shares > 3) then
		for i=2,#Shares do
			A = string.sub(Shares[i-1].ticket, 1,1)
			B = string.sub(Shares[i].ticket, 1,1)
			if (A>B) then
				ShareA = Shares[i-1]
				ShareB = Shares[i]
				Shares[i-1] = ShareB
				Shares[i] = ShareA
			end	
		end
	end
end

function OnParam( class, sec )
	if class == ClassFilter then
			body = getQuoteLevel2(class, sec)
				if (tonumber(body.bid_count) > 0) or (tonumber(body.offer_count) > 0) then
					buy_date = "---"
					buy_price = "---"
					buy_volume = "---"
					sell_date = "---"
					sell_price = "---"
					sell_volume = "---"
					bidqty = 0
					for i = tonumber(body.bid_count), 1, -1 do
						bidqty = bidqty + body.bid[i].quantity
					end
					if (bidqty>0) then
						bidavg = bidqty / body.bid_count
					else
						bidavg=0
					end
					if (bidavg>0) then
						for i = tonumber(body.bid_count), 1, -1 do
							if (tonumber(body.bid[i].quantity)>(bidavg*MultiQty)) then
								buy_price = body.bid[i].price
								buy_volume = body.bid[i].quantity
								buy_date = os.date("%c",os.time())
							end
						end
					end
					askqty = 0
					for i = tonumber(body.offer_count), 1, -1 do
						askqty = askqty + body.offer[i].quantity
					end
					if (askqty>0) then
						askavg = askqty / body.offer_count
					else
						askavg=0
					end
					if (askavg>0) then
						for i = tonumber(body.offer_count), 1, -1 do
							if (tonumber(body.offer[i].quantity)>(askavg*MultiQty)) then
								sell_price = body.offer[i].price
								sell_volume = body.offer[i].quantity
								sell_date = os.date("%c",os.time())		
							end
						end
					end
					Share = {
						ticket = sec,
						class = class,
						price = getParamEx(class, sec, "LAST").param_image,
						last_change = getParamEx(class, sec, "LASTCHANGE").param_image,
						last_change_num = getParamEx(class, sec, "LASTCHANGE").param_value,
						buy_date = buy_date,
						buy_price = buy_price,
						buy_volume = buy_volume,
						sell_date = sell_date,
						sell_price = sell_price,
						sell_volume = sell_volume
					}
					
					if (#Shares>0) then
						Find = false
						for i=1,#Shares do
							if Shares[i].ticket == Share.ticket then
								Find = true
								Shares[i] = Share
							end
						end
						if Find == false then
							Shares[#Shares+1] = Share
							InsertRow(View, -1)
						end
					else
						Shares[#Shares+1] = Share
						InsertRow(View, -1)
					end

					SharesSort()
					for i=1,#Shares do
						
						SetCell(View, i, 1, Shares[i].ticket)
						SetCell(View, i, 2, Shares[i].class)
						SetCell(View, i, 3, Shares[i].price)
						SetCell(View, i, 4, Shares[i].last_change)
						SetCell(View, i, 5, Shares[i].buy_date)
						SetCell(View, i, 6, Shares[i].buy_price)
						SetCell(View, i, 7, Shares[i].buy_volume)
						SetCell(View, i, 8, Shares[i].sell_date)
						SetCell(View, i, 9, Shares[i].sell_price)
						SetCell(View, i, 10, Shares[i].sell_volume)
						num = math.floor(tonumber(Shares[i].last_change_num))
						if (num~=nil) then
							if (num > 1) then
								SetColor(View, i, 3, RGB(10, 255-num*3, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
								SetColor(View, i, 4, RGB(10, 255-num*3, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
							elseif (num < -1) then
								SetColor(View, i, 3, RGB(255+num*3,10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
								SetColor(View, i, 4, RGB(255+num*3,10, 10), color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
							else
								SetColor(View, i, 3, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
								SetColor(View, i, 4, color_white, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
							end
							
						end
					end
				
			end
			

	end	
end


function OnInit(path)
	
	AddColumn(View, 1, "Тикет", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 2, "Класс", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 3, "Цена", true, QTABLE_STRING_TYPE , 10)
	AddColumn(View, 4, "Изм.,%", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 5, "Время", true, QTABLE_STRING_TYPE, 20)
	AddColumn(View, 6, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 7, "Объем", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 8, "Время", true, QTABLE_STRING_TYPE, 20)
	AddColumn(View, 9, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 10, "Объем", true, QTABLE_STRING_TYPE, 10)
	

	CreateWindow(View)

	SetColor(View, QTABLE_NO_INDEX, 5, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 6, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 7, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 8, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 9, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetColor(View, QTABLE_NO_INDEX, 10, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetWindowCaption(View, "Подстаканник")
	
	
end

function OnStop(signal) 
	stopped = true 
end

function OnClose() 
	stopped = true 
end

function main()
	while not stopped 
		do sleep(500) 
	end
end