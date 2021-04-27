os.loadAPI("imglib")
 
local monitor = peripheral.wrap("front")
monitor.setTextScale(0.5)
term.redirect(monitor)
 
local mw, mh = monitor.getSize()
 
local MAXBET = 128
 
local BACK = {}
local SUITS = {}
local VALUES = {"A","2","3","4","5",
                "6","7","8","9","10",
                "J","Q","K"}
 
function param(x)
  local h = 0
  if x <= 30 then
    h = math.floor(38-38/729*math.pow(x-3,2))
  else
    h = math.floor(19-19/400*math.pow(x-50,2))
  end
  return 52-14-h
end
 
function pickupItem()
  turtle.suckDown()
  local itm = turtle.getItemDetail()
  while itm do
    if (itm.name == "ComputerCraft:disk") then
      turtle.dropDown()
      return true
    else
      turtle.dropUp()
      turtle.suckDown()
      itm = turtle.getItemDetail()
    end
  end
  return false
end
 
function resetScreen(c)
  c = c or colors.green
  paintutils.drawFilledBox(1,1,mw,mh,c)
end
 
function startScreen()
  local name = "blackjack"
  local i = 1
  local cards = {}
  
  local nextCard = 0
  
  os.startTimer(0)
  
  while true do
    event = { os.pullEvent() }
    if event[1] == "disk" then
      if pickupItem() then return
      else os.startTimer(0.125)
      end
    elseif event[1] == "timer" then
      os.startTimer(0.125)
      if nextCard == 0 then
        dir = math.random(2)
        x0 = -9
        if dir == 2 then x0 = mw end
        table.insert(cards, {value=VALUES[math.random(table.getn(VALUES))],
                             suit=SUITS[math.random(table.getn(SUITS))],
                             x=x0,
                             y=param(x0),
                             speed=dir})
        nextCard = math.random(5)+3
      else
        nextCard = nextCard - 1
      end
      local newcards = {}
      resetScreen()
      for c = 1, #cards do
        local card = cards[c]
        if (card.speed == 1 and card.x <= mw) or (card.speed == 2 and card.x >= -9) then
          drawCard(card.value,card.suit,card.x,card.y)
          if card.speed == 1 then
            card.x = card.x+3
            card.y = param(card.x)
          else
            card.x = card.x-3
            card.y = param(mw-9-card.x)
          end
          table.insert(newcards,card)
        end
      end
      cards = newcards
      
      imglib.centerRect(monitor,mw/2,mh/2,50,9,colors.lime)
    
      imglib.centerWord(monitor,name,mw/2,mh/2,colors.white)
      i = i + 1
    end
  end
end
 
function main()
  SUITS = imglib.loadImgs("/images/suits",5)
  BACK = imglib.loadImg("/images/cardback")
  while true do
    startScreen()
    showProfilePic()
    placeBet()
    turtle.suckDown()
    turtle.dropUp()
  end
end
 
function drawFacedownCard(x, y)
  drawCard("F", nil, x, y)
end
 
function drawCard(val, suit, x, y)  
  paintutils.drawLine(x+1,y,x+10,y,colors.black)
  paintutils.drawLine(x,y+1,x,y+13,colors.black)
  paintutils.drawLine(x+1,y+14,x+10,y+14,colors.black)
  paintutils.drawLine(x+11,y+1,x+11,y+13,colors.black)
  if val == "F" then
    imglib.drawImage(monitor,BACK,x+1,y+1)
  else
    paintutils.drawFilledBox(x+1,y+1,x+10,y+13,colors.white)
    imglib.drawImage(monitor,suit,x+5,y+2)
 
    imglib.drawNumber(monitor,val,x+2,y+8)
  end
end
 
function showProfilePic()
  resetScreen(colors.white)
  imglib.centerWord(monitor,"Welcome", mw/2, 4)
  
  imglib.centerImage(monitor,imglib.loadImg("/disk/pic"), mw/2, mh/2)
 
  imglib.centerRect(monitor,mw/2,45,21,7,colors.blue)
  
  imglib.centerWord(monitor,"done", mw/2,45)
  
  while true do
    event,side,xPos,yPos = os.pullEvent("monitor_touch")
    if (30 <= xPos and xPos <= 50 and 42 <= yPos and yPos <= 48) then
      return
    end
  end
end
 
function placeBet()
  local bal = getCardValue()
  local b = math.min(MAXBET, bal)
  
  function drawBetScreen()
    bal = getCardValue()
    b = math.min(b, MAXBET, bal)
    resetScreen()
    imglib.centerWord(monitor,"Place your bet",mw/2,8)
    imglib.centerWord(monitor,"$"..bal,mw/2,20,colors.yellow)
 
    paintutils.drawFilledBox(mw/2-29,34,mw/2-20,40,colors.red)
    imglib.drawWord(monitor,"-8",mw/2-28,35)
    paintutils.drawFilledBox(mw/2-18,34,mw/2-10,40,colors.red)
    imglib.drawWord(monitor,"-1",mw/2-17,35)
 
    imglib.centerRect(monitor,mw/2,37,17,7,colors.white)
    imglib.centerWord(monitor,tostring(b),mw/2,37)
 
    paintutils.drawFilledBox(mw/2+12,34,mw/2+20,40,colors.lime)
    imglib.drawWord(monitor,"+1",mw/2+13,35)
    paintutils.drawFilledBox(mw/2+22,34,mw/2+31,40,colors.lime)
    imglib.drawWord(monitor,"+8",mw/2+23,35)
    
    imglib.centerRect(monitor,mw/2,45,17,7,colors.white)
    imglib.centerWord(monitor,"Bet",mw/2,45)
  
    paintutils.drawFilledBox(1,46,22,52,colors.red)
    imglib.drawWord(monitor,"Quit",2,mh-5)
  end
  
  drawBetScreen()
  
  while true do
    event,side,xPos,yPos = os.pullEvent("monitor_touch")
    if (xPos <= 22 and yPos >= 46) then
      return
    elseif (34 <= yPos and yPos <= 40) then
      if (mw/2-29 <= xPos and xPos <= mw/2-20) then
        b = math.max(b-8,0)
      elseif (mw/2-18 <= xPos and xPos <= mw/2-10) then
        b = math.max(b-1,0)
      elseif (mw/2+12 <= xPos and xPos <= mw/2+20) then
        b = math.min(b+1,128,bal)
      elseif (mw/2+22 <= xPos and xPos <= mw/2+31) then
        b = math.min(b+8,128,bal)
      end
      drawBetScreen()
    elseif (mw/2-7 <= xPos and xPos <= mw/2+9 and 42 <= yPos and yPos <= 48) then
      if b > 0 then
        blackjack(b)
      else
        local offset = 0
        for j = 0, 1 do
          for i = 0, 3 do
            if j % 2 == 0 then offset = i
            else offset = 5-i
            end
            imglib.centerRect(monitor,mw/2,37,17,7,colors.white)
            imglib.centerWord(monitor,tostring(b),mw/2-4+offset,37)
            os.sleep(0.05)
          end
        end
      end
      drawBetScreen()
    end
  end
end
 
function blackjack(bet)
  local bal = getCardValue()
  
  local pulled = {}
  local dh = {}
  local ph = {}
  
  for i=1,2 do
    local c = generateCard(pulled)
    table.insert(pulled,c)
    table.insert(dh,c)
  end
  for i=1,2 do
    local c = generateCard(pulled)
    table.insert(pulled,c)
    table.insert(ph,c)
  end
  
  local doubled = false
  
  if getHandValue(dh) ~= 21 and getHandValue(ph) ~= 21 then
    while true do
      resetScreen()
    
      drawCard(VALUES[dh[1].valIdx],SUITS[dh[1].suitIdx],mw/2-11,5)
      drawFacedownCard(mw/2+2,5)
    
      for i=1,table.getn(ph) do
        drawCard(VALUES[ph[i].valIdx],SUITS[ph[i].suitIdx],
                 mw/2-13*(table.getn(ph)/2-i+1)+2,27)
      end
      
      if doubled then
        paintutils.drawFilledBox(mw/2-13,45,mw/2+14,51,colors.orange)
        imglib.drawWord(monitor,"Stand",mw/2-12,46)
      else
        paintutils.drawFilledBox(mw/2-26,45,mw/2,51,colors.orange)
        imglib.drawWord(monitor,"Stand",mw/2-25,46)
      
        paintutils.drawFilledBox(mw/2+2,45,mw/2+17,51,colors.red)
        imglib.drawWord(monitor,"Hit",mw/2+3,46)
      end
      
      if table.getn(ph) == 2 then
        paintutils.drawFilledBox(mw/2+19,45,mw/2+28,51,colors.red)
        imglib.drawWord(monitor,"*2",mw/2+20,46)
      end
      
      event,side,xPos,yPos = os.pullEvent("monitor_touch") 
      if (45 <= yPos and yPos <= 51) then
        if doubled then
          if (mw/2-13 <= xPos and xPos <= mw/2+14) then
            break
          end
        elseif (mw/2-26 <= xPos and xPos <= mw/2) then
          break
        elseif (mw/2+2 <= xPos and xPos <= mw/2+17) then
          newCard = generateCard(pulled)
          table.insert(pulled,newCard)
          table.insert(ph,newCard)
          if getHandValue(ph) >= 21 then break end
        elseif (table.getn(ph) == 2 and mw/2+19 <= xPos and xPos <= mw/2+28) then
          bet = bet * 2
          doubled = true
          newCard = generateCard(pulled)
          table.insert(pulled,newCard)
          table.insert(ph,newCard)
          if getHandValue(ph) >= 21 then break end
        end
      end
    end
  end  
  resetScreen()
  
  function drawHand(h, y)
    for i=1,table.getn(h) do
      drawCard(VALUES[h[i].valIdx],SUITS[h[i].suitIdx],
               mw/2-13*(table.getn(h)/2-i+1)+2,y)
    end
  end
  
  drawHand(dh,5)
  drawHand(ph,27)
  
  if getHandValue(dh) == 21 then
    imglib.centerWord(monitor,"Dealer Blackjack",mw/2,23)
    playLoseSound()
    updateCardValue(-bet)
  elseif getHandValue(ph) == 21 and table.getn(ph) == 2 then
    imglib.centerWord(monitor,"Blackjack",mw/2,23)
    playWinSound()
    updateCardValue(math.floor(bet*3/2))
  elseif getHandValue(ph) > 21 then
    imglib.centerWord(monitor,"Busted",mw/2,23)
    playLoseSound()
    updateCardValue(-bet)
  else
    done = false
    handVal = getHandValue(dh)
    if handVal == 17 and getHandValue(dh,true) == 7 then
      done = false
    elseif handVal >= 17 then
      done = true
    end
    while not done do
      os.sleep(1.25)
      newCard = generateCard(pulled)
      table.insert(pulled, newCard)
      table.insert(dh, newCard)
      resetScreen()
      drawHand(dh,5)
      drawHand(ph,27)
      
      handVal = getHandValue(dh)
      if handVal == 17 and getHandValue(dh,true) == 7 then
        done = false
      elseif handVal >= 17 then
        done = true
      end
    end
    if getHandValue(dh) > 21 or getHandValue(dh) < getHandValue(ph) then
      imglib.centerWord(monitor,"You Win",mw/2,23)
      playWinSound()
      updateCardValue(bet)
    elseif getHandValue(dh) == getHandValue(ph) then
      imglib.centerWord(monitor,"Push",mw/2,23)
      playLowSound()
    else
      imglib.centerWord(monitor,"You Lose",mw/2,23)
      playLoseSound()
      updateCardValue(-bet)
    end
  end
  os.pullEvent("monitor_touch")
  -- TODO : Play again/quit
end
 
function getHandValue(hand,soft)
  soft = soft or false
 
  local tot = 0
  local aces = 0
  for i,c in ipairs(hand) do
    numeric = 10
    cardVal = VALUES[c.valIdx]
    if cardVal == "A" then
      numeric = 11
      aces = aces + 1
    elseif tonumber(cardVal) ~= nil then
      numeric = tonumber(cardVal)
    end
    tot = tot + numeric
  end
  
  while aces > 0 and tot > 10 do
    if not soft and tot <= 21 then break end
    aces = aces - 1
    tot = tot - 10
  end
  return tot
end
 
function generateCard(pulled)
  local card = {valIdx=math.random(13),
                suitIdx=math.random(4)}
  
  local rpt = true
  
  while rpt do
    card = {valIdx=math.random(13),
            suitIdx=math.random(4)}
    rpt = false
    for i,c in ipairs(pulled) do
      if card.valIdx == c.valIdx and card.suitIdx == c.suitIdx then
        rpt = true
        break
      end
    end
  end
  return card
end
 
function updateCardValue(dm)
  local oldVal = getCardValue()
  local file = fs.open("/disk/val", "w")
  file.write(oldVal + dm)
  file.close()
end
 
function getCardValue()
  local file = fs.open("/disk/val","r")
  if file then
    local cardVal = tonumber(file.readLine())
    file.close()
    return cardVal
  else
    return 0
  end  
end
 
function playLowSound()
  redstone.setOutput("back",true)
  os.sleep(0.1)
  redstone.setOutput("back",false)
end
function playHighSound()
  redstone.setOutput("right",true)
  os.sleep(0.1)
  redstone.setOutput("right",false)
end
 
function playWinSound()
  playLowSound()
  --os.sleep(0.1)
  playHighSound()
end
 
function playLoseSound()
  playHighSound()
  --os.sleep(0.1)
  playLowSound()
end
 
main()