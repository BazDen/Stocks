-- Жадина для Quik. Автор: Денис Базарнов, 2020 год. 
-- сайт: КБС.Онлайн
-- почта: kbs.online.service@gmail.com
-- Telegram: @BazDen

trade_account = "L01-00000F00" -- Ващ лицевой счет
trade_sec = 'POLY' -- название акцииЮ указывается код (Тикет). Например POLY = Полиметалл
trade_class = 'TQBR' -- класс инструмента (TQBR - для акций)
trade_qty = 1  -- количество лотов
trade_profit = 6   -- насколько дороже продавать. Цена продажи = цена покупки + trade_profit
trade_buy_in = -20 -- когда докупать. В данном случае указано, что при падении цены на 20 рублей
trade_sec_profit = 10 -- насколько дороже продавать, при дозакупке
--------------------------------------------------------------------------------------
color_green = RGB(150, 200, 150)
color_red = RGB(200, 150, 150)
color_white = RGB(255, 255, 255)
color_yellow = RGB(255, 255, 115)

View = AllocTable()
Dealings = {}
Status = 0 
trans_id = 0
cur_profit = 0
all_profit = 0
lotsize = 1
buy_price = 0
cur_price = 0
cur_qty = 0
cur_sell_ratio = 0

function ShowDealings()
	for i=1,#Dealings do
		SetCell(View, i, 1, Dealings[i].action)
		SetCell(View, i, 2, Dealings[i].sec)
		SetCell(View, i, 3, tostring(Dealings[i].price))
		SetCell(View, i, 4, tostring(Dealings[i].qty))
		SetCell(View, i, 5, tostring(Dealings[i].sum))
		SetCell(View, i, 6, tostring(Dealings[i].cur_profit))
		SetCell(View, i, 7, tostring(Dealings[i].all_profit))
	end
end

function OnParam( class, sec )
	if class == trade_class then
		if sec == trade_sec then	
			cur_price = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)
			if Status == 0 then
				Deal = {
						action = 'Начало работы',
						sec = trade_sec,
						price = getParamEx(trade_class, trade_sec, "LAST").param_image,
						qty = cur_qty*lotsize,
						sum = tonumber(cur_price)*trade_qty*lotsize,
						cur_profit = cur_profit,
						all_profit = all_profit
					}
				Dealings[#Dealings+1] = Deal
				InsertRow(View, -1)
				ShowDealings()
				cur_sell_ratio = trade_profit
				cur_qty = trade_qty
				buy_price = cur_price
				-- делаем покупку на заданный объем
				-- покупаем по рынку
				trans_id = tostring(os.time()-100000000)
				transaction = {
					ACCOUNT=trade_account,
					TYPE="M",
					TRANS_ID=trans_id,
					CLASSCODE=trade_class,
					SECCODE=trade_sec,
					ACTION="NEW_ORDER",
					OPERATION="B",
					PRICE = "0",
					QUANTITY=tostring(trade_qty)
				}
				local res = sendTransaction(transaction)
				if (res ~= '') then
					message(res)
					stopped = true
				end	
				Deal = {
					action = 'Покупка по рынку',
					sec = trade_sec,
					price = getParamEx(trade_class, trade_sec, "LAST").param_image,
					qty = cur_qty*lotsize,
					sum = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)*trade_qty*lotsize,
					cur_profit = cur_profit,
					all_profit = all_profit
				}
				Dealings[#Dealings+1] = Deal
				InsertRow(View, -1)
				ShowDealings()
				SetColor(View, #Dealings, QTABLE_NO_INDEX, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
				sleep(100)
				Status = 1
			elseif Status == 1 then
				cur_profit = math.floor(cur_price*trade_qty*lotsize - buy_price * trade_qty * lotsize)
				SetCell(View, #Dealings, 3, getParamEx(class, sec, "LAST").param_image)
				SetCell(View, #Dealings, 4, tostring(cur_qty))
				SetCell(View, #Dealings, 5, tostring(Dealings[#Dealings].qty*getParamEx(class, sec, "LAST").param_value))
				SetCell(View, #Dealings, 6, tostring(cur_profit))
				SetCell(View, #Dealings, 7, tostring(all_profit + cur_profit))
				if ((buy_price + cur_sell_ratio) < cur_price) then
					all_profit = all_profit + cur_profit
					buy_price = cur_price
					if (cur_qty == trade_qty) then
						cur_qty = cur_qty + trade_qty
						-- покупаем по рынку
						trans_id = tostring(os.time()-100000000)
						transaction = {
							ACCOUNT=trade_account,
							TYPE="M",
							TRANS_ID=trans_id,
							CLASSCODE=trade_class,
							SECCODE=trade_sec,
							ACTION="NEW_ORDER",
							OPERATION="B",
							PRICE = "0",
							QUANTITY=tostring(trade_qty)
						}
						local res = sendTransaction(transaction)
						
						if (res ~= '') then
							message(res)
							stopped = true
						end	
						Deal = {
							action = 'Покупка по рынку',
							sec = trade_sec,
							price = getParamEx(trade_class, trade_sec, "LAST").param_image,
							qty = cur_qty*lotsize,
							sum = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)*trade_qty*lotsize,
							cur_profit = cur_profit,
							all_profit = all_profit
						}
						Dealings[#Dealings+1] = Deal
						InsertRow(View, -1)
						SetColor(View, #Dealings, QTABLE_NO_INDEX, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
						sleep(100)
						-- выставляем лимитированную заявку на продажу
						trans_id = tostring(os.time()-100000000)
						transaction = {
							ACCOUNT=trade_account,
							TYPE="L",
							TRANS_ID=trans_id,
							CLASSCODE=trade_class,
							SECCODE=trade_sec,
							ACTION="NEW_ORDER",
							OPERATION="S",
							PRICE=tostring(buy_price + cur_sell_ratio),
							QUANTITY=tostring(trade_qty)
						}
						local res = sendTransaction(transaction)
						if (res ~= '') then
							message(res)
							stopped = true
						end
						Deal = {
							action = 'Заявка на продажу по цене: '..tostring(buy_price + cur_sell_ratio),
							sec = trade_sec,
							price = getParamEx(trade_class, trade_sec, "LAST").param_image,
							qty = cur_qty*lotsize,
							sum = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)*trade_qty*lotsize,
							cur_profit = cur_profit,
							all_profit = all_profit
						}
						Dealings[#Dealings+1] = Deal
						InsertRow(View, -1)
						SetColor(View, #Dealings, QTABLE_NO_INDEX, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
						ShowDealings()
						
					elseif (cur_qty > trade_qty) then
						
						cur_qty = trade_qty
						cur_sell_ratio = trade_profit
					end
				elseif ((buy_price + trade_buy_in) > cur_price) then
					buy_price = cur_price
					cur_qty = cur_qty + trade_qty
					cur_sell_ratio = cur_sell_ratio + trade_sec_profit
					-- покупаем по рынку
					trans_id = tostring(os.time()-100000000)
					transaction = {
						ACCOUNT=trade_account,
						TYPE="M",
						TRANS_ID=trans_id,
						CLASSCODE=trade_class,
						SECCODE=trade_sec,
						ACTION="NEW_ORDER",
						OPERATION="B",
						PRICE = "0",
						QUANTITY=tostring(trade_qty)
					}
					local res = sendTransaction(transaction)
					
					if (res ~= '') then
						message(res)
						stopped = true
					end	
					Deal = {
						action = 'Цена упала. Докупаем.',
						sec = trade_sec,
						price = getParamEx(trade_class, trade_sec, "LAST").param_image,
						qty = cur_qty*lotsize,
						sum = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)*trade_qty*lotsize,
						cur_profit = cur_profit,
						all_profit = all_profit
					}
					Dealings[#Dealings+1] = Deal
					InsertRow(View, -1)
					SetColor(View, #Dealings, QTABLE_NO_INDEX, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
					sleep(100)
					-- выставляем лимитированную заявку на продажу
					trans_id = tostring(os.time()-100000000)
					transaction = {
						ACCOUNT=trade_account,
						TYPE="L",
						TRANS_ID=trans_id,
						CLASSCODE=trade_class,
						SECCODE=trade_sec,
						ACTION="NEW_ORDER",
						OPERATION="S",
						PRICE=tostring(buy_price + cur_sell_ratio),
						QUANTITY=tostring(trade_qty)
					}
					local res = sendTransaction(transaction)
					if (res ~= '') then
						message(res)
						stopped = true
					end
					Deal = {
						action = 'Заявка на продажу по цене: '..tostring(buy_price + cur_sell_ratio),
						sec = trade_sec,
						price = getParamEx(trade_class, trade_sec, "LAST").param_image,
						qty = cur_qty*lotsize,
						sum = tonumber(getParamEx(trade_class, trade_sec, "LAST").param_value)*trade_qty*lotsize,
						cur_profit = cur_profit,
						all_profit = all_profit
					}
					Dealings[#Dealings+1] = Deal
					InsertRow(View, -1)
					SetColor(View, #Dealings, QTABLE_NO_INDEX, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
					ShowDealings()
				end
			end
		end
	end	
end


function OnInit(path)
	
	AddColumn(View, 1, "Действие", true, QTABLE_STRING_TYPE, 40)
	AddColumn(View, 2, "Инстр.", true, QTABLE_STRING_TYPE , 10)
	AddColumn(View, 3, "Цена", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 4, "Кол-во", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 5, "Сумма", true, QTABLE_STRING_TYPE, 10)
	AddColumn(View, 6, "Тек.прибыль", true, QTABLE_STRING_TYPE, 15)
	AddColumn(View, 7, "Общ.прибыль", true, QTABLE_STRING_TYPE, 15)
	CreateWindow(View)

	-- SetColor(View, QTABLE_NO_INDEX, 5, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	-- SetColor(View, QTABLE_NO_INDEX, 6, color_green, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	-- SetColor(View, QTABLE_NO_INDEX, 7, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	-- SetColor(View, QTABLE_NO_INDEX, 8, color_red, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
	SetWindowCaption(View, "Жадина "..trade_sec)
	lotsize = tonumber(getParamEx(trade_class, trade_sec, "LOTSIZE").param_value)
end

function OnStop(signal) 
	stopped = true 
end

function OnClose() 
	stopped = true 
end

function main()
	while not stopped 
		do sleep(1000) 
	end
end