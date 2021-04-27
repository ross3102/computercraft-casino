local monitor = peripheral.wrap("right")
local mw, mh = monitor.getSize()
term.redirect(monitor)
 
local currency = "minecraft:diamond"
 
function resetScreen()
  paintutils.drawFilledBox(1,1,mw,mh,colors.black)
  term.setCursorPos(1,1)
end
 
function pickupItem()
  turtle.suckDown()
  local itm = turtle.getItemDetail()
  while itm do
    if (itm.name == "ComputerCraft:disk") then
      turtle.dropDown()
      return true
    else
      turtle.drop()
      turtle.suckDown()
      itm = turtle.getItemDetail()
    end
  end
  return false
end
 
function awaitCard()
  function awaitCardScreen()
    resetScreen()
    centerText("Insert",9)
    monitor.setCursorPos(1,2)
    centerText("Card",10)
  end
  
  redstone.setOutput("back", true)
  awaitCardScreen()
  
  while true do
    event = { os.pullEvent("disk") }
    if pickupItem() then
      resetScreen()
      menu()
      redstone.setOutput("back", true)
    else
      redstone.setOutput("back", false)
      
      resetScreen()
      centerText("Not a Card",9)
      centerText("Collect Your Items",10)
      centerText("Click to Proceed",11)
      
      event = { os.pullEvent("monitor_touch") }
      redstone.setOutput("back", true)
    end
    awaitCardScreen()
  end
end
 
function menu()
  function drawMenu()
    resetScreen()
    
    monitor.setBackgroundColor(colors.black)
    
    local file = fs.open("/disk/val", "r")
    local cardVal = getCardValue()
    
    centerText("Cashier!",4)
    centerText("$"..tostring(cardVal),6)
    paintutils.drawFilledBox(2,8,17,10,colors.blue)
    centerText("Load Money",9)
    paintutils.drawFilledBox(2,12,17,14,colors.green)
    centerText("Cash Out",13)
    paintutils.drawFilledBox(2,16,17,18,colors.red)
    centerText("Done",17)
  end
  drawMenu()
  redstone.setOutput("back", false)
  
  while true do
    event,side,xPos,yPos = os.pullEvent("monitor_touch")
    if (8 <= yPos and yPos <= 10) then
      deposit()
      drawMenu()
      redstone.setOutput("back", false)
    elseif (12 <= yPos and yPos <= 14) then
      cashOut()
      drawMenu()
    elseif (16 <= yPos and yPos <= 18) then
      turtle.suckDown()
      turtle.drop()
      resetScreen()
      centerText("Thanks",9)
      os.sleep(4)
      return -- back to awaitCard
    end
  end
end
 
function deposit()
  function drawDeposit()
    resetScreen()
    monitor.setBackgroundColor(colors.black)
    
    centerText("Insert",4)
    centerText("Diamonds",5)
    paintutils.drawFilledBox(2,12,17,14,colors.green)
    centerText("Done",13)
  end
 
  local d = 0
  local clicked = false
  
  function handleDiamond(dmnd)
    if (dmnd.name == currency) then
      d = d + dmnd.count
      turtle.dropUp()
    else
      turtle.drop()
    end
  end
 
  function collectDiamonds()
    while true do
      if clicked then
        resetScreen()
        centerText("Counting",9)
        os.sleep(2)
        turtle.suckDown()
        local itm = turtle.getItemDetail()
        while itm do
          handleDiamond(itm)
          turtle.suckDown()
          itm = turtle.getItemDetail()
        end
        return
      end
      turtle.suckDown()
      local itm = turtle.getItemDetail()
      if itm then
        handleDiamond(itm)
      end
    end
  end
 
  function awaitDone()
    while true do
      event,side,posX,posY = os.pullEvent("monitor_touch")
      if (12 <= posY and posY <= 14) then
        clicked = true
        return
      end
    end
  end
  
  drawDeposit()
  
  turtle.select(16)
  turtle.suckDown()
  turtle.select(1)
  
  redstone.setOutput("back", true)
  
  parallel.waitForAll(collectDiamonds, awaitDone)
 
  turtle.select(16)
  turtle.dropDown()
  turtle.select(1)
 
  updateCardValue(d)
  
  return -- back to menu
end
 
function cashOut()
  function drawCashOut()
    resetScreen()
    centerText("Cash Out",4)
    paintutils.drawFilledBox(2,8,17,10,colors.green)
    centerText("All",9)
    paintutils.drawFilledBox(2,12,17,14,colors.yellow)
    centerText("Half",13)
    paintutils.drawFilledBox(2,16,17,18,colors.red)
    centerText("Cancel",17)
  end
  
  drawCashOut()
  
  while true do
    event,side,xPos,yPos = os.pullEvent("monitor_touch")
    if (8 <= yPos and yPos <= 10) then
      local bal = getCardValue()
      resetScreen()
      centerText("Dispensing",9)
      updateCardValue(-bal)
      local scammed = withdraw(math.floor(bal*.95))
      updateCardValue(scammed)
      os.sleep(1)
      return -- back to menu
    elseif (12 <= yPos and yPos <= 14) then
      local bal = math.floor(getCardValue()/2)
      resetScreen()
      centerText("Dispensing",9)
      updateCardValue(-bal)
      local scammed = withdraw(math.floor(bal*.95))
      updateCardValue(scammed)
      os.sleep(1)
      return -- back to menu
    elseif (16 <= yPos and yPos <= 18) then
      return -- back to menu
    end
  end
end
 
function withdraw(n)
  local scammed = 0
  while (n >= 64) do
    for p = 1, math.min(16, math.floor(n/64)) do
      turtle.select(p)
      turtle.suckUp()
      if (turtle.getItemCount() == 0) then
        scammed = scammed + 64
      end
      n = n - 64
    end
    for p = 1, 16 do
      turtle.select(p)
      turtle.drop()
    end
  end
  if scammed == 0 then
    turtle.select(1)
    turtle.suckUp(n)
    scammed = scammed + n - turtle.getItemCount()
    turtle.drop()
  else
    scammed = scammed + n
  end
  return scammed
end
 
function updateCardValue(newd)
  local oldVal = getCardValue()
  local file = fs.open("/disk/val","w")
  file.write(tostring(oldVal + newd))
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
 
function centerText(text, y)
  monitor.setCursorPos(math.floor((mw/2)-(text:len()/2)+1),y)
  monitor.write(text)
end
 
awaitCard()