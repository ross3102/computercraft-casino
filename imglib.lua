colorChars = {["0"]=colors.white,
              ["1"]=colors.orange,
              ["2"]=colors.magenta,
              ["3"]=colors.lightBlue,
              ["4"]=colors.yellow,
              ["5"]=colors.lime,
              ["6"]=colors.pink,
              ["7"]=colors.gray,
              ["8"]=colors.lightGray,
              ["9"]=colors.cyan,
              ["a"]=colors.purple,
              ["b"]=colors.blue,
              ["c"]=colors.brown,
              ["d"]=colors.green,
              ["e"]=colors.red,
              ["f"]=colors.black}
 
function loadImgs(fn,nl)
  local imgs = {}
  
  local file = fs.open(fn, "r")
  
  local line = file.readLine()
  
  while (line ~= nil) do
    local img = {lines={},
                  width=0}
    
    for l = 1, nl do
      img.width = math.max(img.width, line:len())
      table.insert(img.lines, line)
      line = file.readLine()
    end
    table.insert(imgs,img)
  end
  
  file.close()
  return imgs
end
  
function loadImg(fn)
  local img = {lines={},
                width=0}
  
  local file = fs.open(fn, "r")
  
  local line = file.readLine()
  
  while (line ~= nil) do
    img.width = math.max(img.width, line:len())
    table.insert(img.lines, line)
    line = file.readLine()
  end
  
  file.close()
  return img
end
 
function drawSector(m, cx, cy, ri, rf, ti, tf, color)
  --local oldTerm = term.redirect(m)
  for th=ti,tf,1/20 do --math.ceil(12*rf*(tf-ti)) do
    paintutils.drawLine(math.floor(cx+ri*math.cos(th)+0.5),math.floor(cy-ri*math.sin(th)/1.5+0.5),math.floor(cx+rf*math.cos(th)+0.5),math.floor(cy-rf*math.sin(th)/1.5+0.5),color)
  end
  --term.redirect(oldTerm)
end
 
function drawRect(m, x, y, w, h, color)
  local oldTerm = term.redirect(m)
  paintutils.drawFilledBox(x, y, x+w-1, y+h-1, color)
  term.redirect(oldTerm)
end
 
function centerRect(m, x, y, w, h, color)
  drawRect(m, math.floor(x-w/2+1), math.floor(y-h/2+1), w, h, color)
end
 
-- drawImage : Monitor Image Nat Nat [Maybe Color] ->
function drawImage(m, img, x, y, override)
  local oldTerm = term.redirect(m)
  
  for l,line in ipairs(img.lines) do
    for i = 1, line:len() do
      local c = colorChars[line:sub(i,i)]
      if c then
        paintutils.drawPixel(x+i-1,y+l-1,override or c)
      end
    end
  end
  term.redirect(oldTerm)
end
 
function centerImage(m, img, x, y, override)
  drawImage(m, img, math.floor(x-img.width/2+1), math.floor(y-table.getn(img.lines)/2+1), override)
end
 
function getLetterImg(l)
  local lImg = {}
  if l == "+" then
    lImg = {lines={"   ",
                   " f ",
                   "fff",
                   " f ",
                   "   "},
            width=3}
  elseif l == "-" then
    lImg = {lines={"   ",
                   "   ",
                   "fff",
                   "   ",
                   "   "},
            width=3}
  elseif l == "*" then
    lImg = {lines={"   ",
                   "f f",
                   " f ",
                   "f f",
                   "   "},
            width=3}
  elseif tonumber(l) == nil then
    local i = 0
    if l == " " then i = 27
    elseif l == "$" then i = 28
    else i = string.byte(string.lower(l)) - string.byte("a") + 1
    end
    lImg = LETTERS[i]
  else
    lImg = VALS[tonumber(l)+1]
  end
  return lImg
end
 
function drawLetter(m, l, x, y, override)
  local lImg = getLetterImg(l)
  drawImage(m,lImg,x,y,override)
  return lImg.width
end
 
function drawWord(m, w, x, y, override)
  local width = 0
  for i = 1, w:len() do
    width = width + 1 + drawLetter(m, w:sub(i,i),x+width,y,override)
  end
  return math.max(width - 1, 0)
end
 
function centerWord(m, w, x, y, override)
  local width = -1
  for i = 1, w:len() do
    width = width + 1 + getLetterImg(w:sub(i,i)).width
  end
  if width == -1 then return 0 end
  return drawWord(m, w, math.floor(x-width/2+1), math.floor(y-5/2+1), override)
end
 
function drawNumber(m,val,x,y,override)
  local i = 0
  
  if val == "A" then i = 14
  elseif val == "J" then i = 11
  elseif val == "Q" then i = 12
  elseif val == "K" then i = 13
  else i = tonumber(val)
  end
  
  drawImage(m,VALS[i+1],x,y,override)
end
 
VALS = loadImgs("/images/values",5)
LETTERS = loadImgs("/images/letters",5)