local a={cache={}::any}do do local function __modImpl()

















local b=game:GetService"TweenService"

local c={}






c.Presets={
Fast=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
Smooth=TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
Burst=TweenInfo.new(0.6,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),
SpinIdle=TweenInfo.new(8,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),
SpinBurst=TweenInfo.new(1.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),
Click=TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
ClickQuint=TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In),
Release=TweenInfo.new(0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
ClickRelease=TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
HoverIn=TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
HoverOut=TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
Hover=TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
OnOff=TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
PageSwap=TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
FadeOut=TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
Minimize=TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
MinimizeSnappy=TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
}




local d=setmetatable({},{__mode="k"})

local function propertyKey(e)
local f={}
for g in pairs(e)do
table.insert(f,tostring(g))
end
table.sort(f)
return table.concat(f,",")
end











function c.Play(e,f,g,h)
if h==nil then
h=true
end

local i=f
if type(f)=="string"then
i=c.Presets[f]
assert(i,"Unknown tween preset: "..f)
end

local j=propertyKey(g)
d[e]=d[e]or{}

local k=d[e][j]
if k and h then
k.Tween:Cancel()
end

local l=b:Create(e,i,g)
local m={
Tween=l,
Instance=e,
Key=j,
Paused=false,
}

l.Completed:Connect(function()
local n=d[e]
if n and n[j]==m then
n[j]=nil
end
end)

d[e][j]=m
l:Play()
return m
end



function c.Pause(e)
if e and e.Tween then
e.Tween:Pause()
e.Paused=true
end
end


function c.Resume(e)
if e and e.Tween then
e.Tween:Play()
e.Paused=false
end
end





function c.Cancel(e)
if not e or not e.Tween then
return
end
e.Tween:Cancel()
local f=d[e.Instance]
if f then
f[e.Key]=nil
end
end




function c.CancelAll(e)
local f=d[e]
if not f then
return
end
for g,h in pairs(f)do
h.Tween:Cancel()
end
d[e]=nil
end





function c.Group(e)
local f={}
for g,h in ipairs(e)do
table.insert(f,c.Play(h[1],h[2],h[3],h[4]))
end
return f
end

function c.CancelGroup(e)
for f,g in ipairs(e)do
c.Cancel(g)
end
end

function c.PauseGroup(e)
for f,g in ipairs(e)do
c.Pause(g)
end
end

function c.ResumeGroup(e)
for f,g in ipairs(e)do
c.Resume(g)
end
end






local e=setmetatable({},{__mode="k"})







c.SpinsEnabled=true

function c.StartSpin(f,g,h)

c.StopSpin(f)





for i in pairs(g)do
pcall(function()f[i]=0 end)
end


local i={
handle=nil,
properties=g,
preset=h,
}
e[f]=i

if not c.SpinsEnabled then
return nil
end

local j=c.Play(
f,
h or"SpinIdle",
g
)
i.handle=j
return j
end


function c.StopSpin(f)
local g=e[f]
if g then
if g.handle then
c.Cancel(g.handle)
end
e[f]=nil
end
end




function c.RestartSpins()


local f={}
for g,h in pairs(e)do
table.insert(f,{instance=g,data=h})
end
for g,h in ipairs(f)do
local i=h.instance
local j=h.data
if i and i.Parent and j.properties then
c.StartSpin(i,j.properties,j.preset)
end
end
end



function c.SetSpinsEnabled(f)
c.SpinsEnabled=f
if f then
c.RestartSpins()
return
end
local g={}
for h,i in pairs(e)do
table.insert(g,{instance=h,data=i})
end
for h,i in ipairs(g)do
local j=i.instance
local k=i.data
if k.handle then
c.Cancel(k.handle)
k.handle=nil
end
if j and j.Parent then
for l in pairs(k.properties)do
pcall(function()j[l]=0 end)
end
end
end
end

return c end function a.a():typeof(__modImpl())local b=a.cache.a if not b then b={c=__modImpl()}a.cache.a=b end return b.c end end do local function __modImpl()












local b=game:GetService"ContentProvider"
local c=game:GetService"SoundService"

local d={}




d.Assets={
UIStart="rbxassetid://82845990304289",
Notification="rbxassetid://17208361335",
UIOpen="rbxassetid://103088360945885",
UIClose="rbxassetid://110295449838315",
UIShutdown="rbxassetid://110807507368078",
}





local e={}
local f=false
local g=0
local h=0



local i
local function getSoundGroup()
if i and i.Parent then
return i
end
i=c:FindFirstChild"AetherisUI"
if not i then
i=Instance.new"SoundGroup"
i.Name="AetherisUI"
i.Volume=1
i.Parent=c
end
return i
end


function d.SetVolume(j)
getSoundGroup().Volume=math.clamp(j or 1,0,1)
end

function d.GetVolume()
return getSoundGroup().Volume
end

local function countAssets()
local j=0
for k in pairs(d.Assets)do
j+=1
end
return j
end

local function buildSoundInstances()
for j,k in pairs(d.Assets)do
if not e[j]then
local l=Instance.new"Sound"
l.Name=j
l.SoundId=k
l.SoundGroup=getSoundGroup()
l.Parent=c
e[j]=l
end
end
end












function d.Preload(j)
if f then
if j then
j(h,h,nil,nil)
end
return
end

buildSoundInstances()

h=countAssets()
g=0

if h==0 then
f=true
if j then
j(0,0,nil,nil)
end
return
end

local k={}
for l,m in pairs(e)do
table.insert(k,m)
end

b:PreloadAsync(k,function(l,m)
g+=1
if j then
j(g,h,l,m)
end
end)

f=true
end



function d.GetProgress()
if h==0 then
return 1
end
return g/h
end

function d.IsPreloaded()
return f and g>=h
end















function d.Play(j,k)
local l=e[j]
if not l then
local m=d.Assets[j]
if not m then
warn("SoundUtil.Play: unknown sound name '"..tostring(j).."'")
return nil
end
l=Instance.new"Sound"
l.Name=j
l.SoundId=m
l.SoundGroup=getSoundGroup()
l.Parent=c
e[j]=l
end

if k then
for m,n in pairs(k)do
l[m]=n
end
end




l:Stop()
l.TimePosition=0
l:Play()
return l
end

function d.Stop(j)
local k=e[j]
if k then
k:Stop()
end
end

function d.StopAll()
for j,k in pairs(e)do
k:Stop()
end
end




function d.Release(j)
local k=e[j]
if k then
k:Destroy()
e[j]=nil
end
end

function d.ReleaseAll()
for j in pairs(e)do
d.Release(j)
end
f=false
g=0
end

return d end function a.b():typeof(__modImpl())local b=a.cache.b if not b then b={c=__modImpl()}a.cache.b=b end return b.c end end do local function __modImpl()











return{
["a-arrow-down"]="rbxassetid://92867583610071",
["a-arrow-up"]="rbxassetid://132318504999733",
["a-large-small"]="rbxassetid://111491496660216",accessibility=
"rbxassetid://114029945302017",activity=
"rbxassetid://94212016861936",
["air-vent"]="rbxassetid://81517226012329",airplay=
"rbxassetid://115020759309179",
["alarm-clock-check"]="rbxassetid://76437352099157",
["alarm-clock-minus"]="rbxassetid://77364179863205",
["alarm-clock-off"]="rbxassetid://97904885874823",
["alarm-clock-plus"]="rbxassetid://80468822979214",
["alarm-clock"]="rbxassetid://126259032907535",
["alarm-smoke"]="rbxassetid://96965448419685",album=
"rbxassetid://127358331163602",
["align-center-horizontal"]="rbxassetid://81570549209434",
["align-center-vertical"]="rbxassetid://118470463752466",
["align-end-horizontal"]="rbxassetid://139502909745427",
["align-end-vertical"]="rbxassetid://96528869059554",
["align-horizontal-distribute-center"]="rbxassetid://97220086126656",
["align-horizontal-distribute-end"]="rbxassetid://106128590702022",
["align-horizontal-distribute-start"]="rbxassetid://76074660002997",
["align-horizontal-justify-center"]="rbxassetid://75732302772427",
["align-horizontal-justify-end"]="rbxassetid://129167626402283",
["align-horizontal-justify-start"]="rbxassetid://130161830325281",
["align-horizontal-space-around"]="rbxassetid://91646106782950",
["align-horizontal-space-between"]="rbxassetid://103886093046990",
["align-start-horizontal"]="rbxassetid://125674804697729",
["align-start-vertical"]="rbxassetid://105020230154823",
["align-vertical-distribute-center"]="rbxassetid://93791183635525",
["align-vertical-distribute-end"]="rbxassetid://139354223511433",
["align-vertical-distribute-start"]="rbxassetid://74961997822126",
["align-vertical-justify-center"]="rbxassetid://134754696166569",
["align-vertical-justify-end"]="rbxassetid://92569381441969",
["align-vertical-justify-start"]="rbxassetid://99692844572718",
["align-vertical-space-around"]="rbxassetid://96206012459190",
["align-vertical-space-between"]="rbxassetid://124998077349706",ambulance=
"rbxassetid://78599995190651",ampersand=
"rbxassetid://75272915739209",ampersands=
"rbxassetid://126947193455996",amphora=
"rbxassetid://137370389604364",anchor=
"rbxassetid://92181172123618",angry=
"rbxassetid://74237056000103",annoyed=
"rbxassetid://80064369052011",antenna=
"rbxassetid://99628923540956",anvil=
"rbxassetid://100203029845919",aperture=
"rbxassetid://83396154449972",
["app-window-mac"]="rbxassetid://79587216113811",
["app-window"]="rbxassetid://93142176757189",apple=
"rbxassetid://104349242902442",
["archive-restore"]="rbxassetid://78956681942188",
["archive-x"]="rbxassetid://75830115088395",archive=
"rbxassetid://122180020814574",armchair=
"rbxassetid://105384358373973",
["arrow-big-down-dash"]="rbxassetid://137987229582002",
["arrow-big-down"]="rbxassetid://81081164158885",
["arrow-big-left-dash"]="rbxassetid://97827621354677",
["arrow-big-left"]="rbxassetid://85973092492641",
["arrow-big-right-dash"]="rbxassetid://117825834972403",
["arrow-big-right"]="rbxassetid://82960676755590",
["arrow-big-up-dash"]="rbxassetid://99260194327483",
["arrow-big-up"]="rbxassetid://93136954756149",
["arrow-down-0-1"]="rbxassetid://120961896217875",
["arrow-down-1-0"]="rbxassetid://93474255891850",
["arrow-down-a-z"]="rbxassetid://99554596207900",
["arrow-down-from-line"]="rbxassetid://132045845807798",
["arrow-down-left"]="rbxassetid://102899325237364",
["arrow-down-narrow-wide"]="rbxassetid://129105261655061",
["arrow-down-right"]="rbxassetid://123109928624974",
["arrow-down-to-dot"]="rbxassetid://101675355931221",
["arrow-down-to-line"]="rbxassetid://87050478931254",
["arrow-down-up"]="rbxassetid://85780258549577",
["arrow-down-wide-narrow"]="rbxassetid://88461733425991",
["arrow-down-z-a"]="rbxassetid://76115279362232",
["arrow-down"]="rbxassetid://98764963621439",
["arrow-left-from-line"]="rbxassetid://87857914437603",
["arrow-left-right"]="rbxassetid://131324733048447",
["arrow-left-to-line"]="rbxassetid://118645136026970",
["arrow-left"]="rbxassetid://102531941843733",
["arrow-right-from-line"]="rbxassetid://74073639809355",
["arrow-right-left"]="rbxassetid://77015754304300",
["arrow-right-to-line"]="rbxassetid://78632510329852",
["arrow-right"]="rbxassetid://113692007244654",
["arrow-up-0-1"]="rbxassetid://105257823943016",
["arrow-up-1-0"]="rbxassetid://134175521693798",
["arrow-up-a-z"]="rbxassetid://77763416595160",
["arrow-up-down"]="rbxassetid://81019887641527",
["arrow-up-from-dot"]="rbxassetid://124408496673275",
["arrow-up-from-line"]="rbxassetid://95777664626453",
["arrow-up-left"]="rbxassetid://123490598231261",
["arrow-up-narrow-wide"]="rbxassetid://73006024672636",
["arrow-up-right"]="rbxassetid://129280608535523",
["arrow-up-to-line"]="rbxassetid://108818207813537",
["arrow-up-wide-narrow"]="rbxassetid://87437426951568",
["arrow-up-z-a"]="rbxassetid://107546173611884",
["arrow-up"]="rbxassetid://89282378235317",
["arrows-up-from-line"]="rbxassetid://133710016938621",asterisk=
"rbxassetid://88552752106723",
["at-sign"]="rbxassetid://79059152889146",atom=
"rbxassetid://73167696981648",
["audio-lines"]="rbxassetid://70930641819242",
["audio-waveform"]="rbxassetid://86462036665209",award=
"rbxassetid://132740088158419",axe=
"rbxassetid://132405197863294",
["axis-3d"]="rbxassetid://122438676546804",baby=
"rbxassetid://93472926933440",backpack=
"rbxassetid://140420225386018",
["badge-alert"]="rbxassetid://101829200081951",
["badge-cent"]="rbxassetid://133345018873154",
["badge-check"]="rbxassetid://76078495178149",
["badge-dollar-sign"]="rbxassetid://127139803581141",
["badge-euro"]="rbxassetid://120016477674659",
["badge-indian-rupee"]="rbxassetid://75659682309981",
["badge-info"]="rbxassetid://131995373201472",
["badge-japanese-yen"]="rbxassetid://99081574588615",
["badge-minus"]="rbxassetid://140321561183881",
["badge-percent"]="rbxassetid://121359224294885",
["badge-plus"]="rbxassetid://100325578561866",
["badge-pound-sterling"]="rbxassetid://119688217279444",
["badge-question-mark"]="rbxassetid://121464963737502",
["badge-russian-ruble"]="rbxassetid://108839463659864",
["badge-swiss-franc"]="rbxassetid://91447608372740",
["badge-turkish-lira"]="rbxassetid://137839965873529",
["badge-x"]="rbxassetid://122931434733842",badge=
"rbxassetid://116620312917084",
["baggage-claim"]="rbxassetid://86922213051957",ban=
"rbxassetid://90767043015246",banana=
"rbxassetid://140713420056179",bandage=
"rbxassetid://129660129590770",
["banknote-arrow-down"]="rbxassetid://139366449345199",
["banknote-arrow-up"]="rbxassetid://133758343082529",
["banknote-x"]="rbxassetid://95348701438065",banknote=
"rbxassetid://104840231536668",barcode=
"rbxassetid://118473018143689",barrel=
"rbxassetid://130647115622774",baseline=
"rbxassetid://124677132511270",bath=
"rbxassetid://76031400297942",
["battery-charging"]="rbxassetid://80139357470047",
["battery-full"]="rbxassetid://70906718268972",
["battery-low"]="rbxassetid://139659256984314",
["battery-medium"]="rbxassetid://105934079398915",
["battery-plus"]="rbxassetid://91931341486966",
["battery-warning"]="rbxassetid://115230083817257",battery=
"rbxassetid://70765800346189",beaker=
"rbxassetid://80902539995520",
["bean-off"]="rbxassetid://98164436608714",bean=
"rbxassetid://89491967076869",
["bed-double"]="rbxassetid://73820193212911",
["bed-single"]="rbxassetid://113423940880634",bed=
"rbxassetid://97726529032925",beef=
"rbxassetid://105850162318915",
["beer-off"]="rbxassetid://120333134736361",beer=
"rbxassetid://116404978807744",
["bell-dot"]="rbxassetid://93161277118810",
["bell-electric"]="rbxassetid://100277767266983",
["bell-minus"]="rbxassetid://126334890449727",
["bell-off"]="rbxassetid://78560046118930",
["bell-plus"]="rbxassetid://77014333795836",
["bell-ring"]="rbxassetid://94612128913941",bell=
"rbxassetid://97392696311902",
["between-horizontal-end"]="rbxassetid://81602774794322",
["between-horizontal-start"]="rbxassetid://76112384929846",
["between-vertical-end"]="rbxassetid://72817612571631",
["between-vertical-start"]="rbxassetid://85278312190301",
["biceps-flexed"]="rbxassetid://82004462003936",bike=
"rbxassetid://102930322246035",binary=
"rbxassetid://91751953950088",binoculars=
"rbxassetid://101460003267896",biohazard=
"rbxassetid://95956532900432",bird=
"rbxassetid://132284145117371",birdhouse=
"rbxassetid://83999157401433",bitcoin=
"rbxassetid://95459240442938",blend=
"rbxassetid://111679612185257",blinds=
"rbxassetid://71164165283925",blocks=
"rbxassetid://72212693357737",
["bluetooth-connected"]="rbxassetid://96315134002985",
["bluetooth-off"]="rbxassetid://80600044218117",
["bluetooth-searching"]="rbxassetid://100673019606426",bluetooth=
"rbxassetid://90506573139443",bold=
"rbxassetid://116141470019166",bolt=
"rbxassetid://102881251417484",bomb=
"rbxassetid://139223800924636",bone=
"rbxassetid://111242153474115",
["book-a"]="rbxassetid://104067275658465",
["book-alert"]="rbxassetid://124159928044853",
["book-audio"]="rbxassetid://109208148317037",
["book-check"]="rbxassetid://115999656081696",
["book-copy"]="rbxassetid://108543407492005",
["book-dashed"]="rbxassetid://127430784795958",
["book-down"]="rbxassetid://101011730128222",
["book-headphones"]="rbxassetid://108670200799574",
["book-heart"]="rbxassetid://112788845135284",
["book-image"]="rbxassetid://80808285757226",
["book-key"]="rbxassetid://116024426170705",
["book-lock"]="rbxassetid://118765061220571",
["book-marked"]="rbxassetid://73211024251780",
["book-minus"]="rbxassetid://112724962046282",
["book-open-check"]="rbxassetid://130848362492667",
["book-open-text"]="rbxassetid://100629528672195",
["book-open"]="rbxassetid://129845326810392",
["book-plus"]="rbxassetid://140267785051233",
["book-text"]="rbxassetid://94011772484232",
["book-type"]="rbxassetid://97817304725443",
["book-up-2"]="rbxassetid://130161620853665",
["book-up"]="rbxassetid://98640174079190",
["book-user"]="rbxassetid://128489189240523",
["book-x"]="rbxassetid://118754548186537",book=
"rbxassetid://125383279695672",
["bookmark-check"]="rbxassetid://93940443347986",
["bookmark-minus"]="rbxassetid://96807096039910",
["bookmark-plus"]="rbxassetid://121469724491615",
["bookmark-x"]="rbxassetid://112272342584706",bookmark=
"rbxassetid://121093149326239",
["boom-box"]="rbxassetid://99901322535868",
["bot-message-square"]="rbxassetid://96145330292478",
["bot-off"]="rbxassetid://140417690560013",bot=
"rbxassetid://80451686744860",
["bottle-wine"]="rbxassetid://131675403196921",
["bow-arrow"]="rbxassetid://124089655150375",box=
"rbxassetid://101768155599700",boxes=
"rbxassetid://136372617578355",braces=
"rbxassetid://117761094704041",brackets=
"rbxassetid://74368995728099",
["brain-circuit"]="rbxassetid://70547962410202",
["brain-cog"]="rbxassetid://132039205501538",brain=
"rbxassetid://92424107303177",
["brick-wall-fire"]="rbxassetid://92980588705520",
["brick-wall-shield"]="rbxassetid://75954432775071",
["brick-wall"]="rbxassetid://112878522258821",
["briefcase-business"]="rbxassetid://129135125207283",
["briefcase-conveyor-belt"]="rbxassetid://108665725653714",
["briefcase-medical"]="rbxassetid://119917756334087",briefcase=
"rbxassetid://96754188164225",
["bring-to-front"]="rbxassetid://132975903553748",
["brush-cleaning"]="rbxassetid://71728977448805",brush=
"rbxassetid://127035535799640",bubbles=
"rbxassetid://106183424168227",
["bug-off"]="rbxassetid://88020025049245",
["bug-play"]="rbxassetid://80107955888092",bug=
"rbxassetid://83626408925438",
["building-2"]="rbxassetid://77873775611951",building=
"rbxassetid://110616258983082",
["bus-front"]="rbxassetid://89863432456045",bus=
"rbxassetid://133798469717463",
["cable-car"]="rbxassetid://128643682205596",cable=
"rbxassetid://128449944504901",
["cake-slice"]="rbxassetid://136769828413242",cake=
"rbxassetid://103131590503275",calculator=
"rbxassetid://74915716529646",
["calendar-1"]="rbxassetid://98458364171044",
["calendar-arrow-down"]="rbxassetid://108415736543437",
["calendar-arrow-up"]="rbxassetid://70574654109118",
["calendar-check-2"]="rbxassetid://120231170248276",
["calendar-check"]="rbxassetid://71551019465748",
["calendar-clock"]="rbxassetid://119132152594595",
["calendar-cog"]="rbxassetid://122402172360287",
["calendar-days"]="rbxassetid://99072017568595",
["calendar-fold"]="rbxassetid://117368871270394",
["calendar-heart"]="rbxassetid://88839008103676",
["calendar-minus-2"]="rbxassetid://98846170279891",
["calendar-minus"]="rbxassetid://137354318924383",
["calendar-off"]="rbxassetid://109726151749217",
["calendar-plus-2"]="rbxassetid://112264562093883",
["calendar-plus"]="rbxassetid://125266115249843",
["calendar-range"]="rbxassetid://103641849247576",
["calendar-search"]="rbxassetid://92010083223634",
["calendar-sync"]="rbxassetid://78082218499697",
["calendar-x-2"]="rbxassetid://107518051061147",
["calendar-x"]="rbxassetid://106703374806500",calendar=
"rbxassetid://114792700814035",
["camera-off"]="rbxassetid://81057636835256",camera=
"rbxassetid://79950339943067",
["candy-cane"]="rbxassetid://71689468772492",
["candy-off"]="rbxassetid://110232752314832",candy=
"rbxassetid://107812129154678",cannabis=
"rbxassetid://98792006538601",
["captions-off"]="rbxassetid://105223545364193",captions=
"rbxassetid://104960225031445",
["car-front"]="rbxassetid://87380942739063",
["car-taxi-front"]="rbxassetid://122455403384057",car=
"rbxassetid://121065933462582",caravan=
"rbxassetid://120070979471783",
["card-sim"]="rbxassetid://134490550095771",carrot=
"rbxassetid://119118221444304",
["case-lower"]="rbxassetid://129303130603241",
["case-sensitive"]="rbxassetid://125410273293056",
["case-upper"]="rbxassetid://111633433531325",
["cassette-tape"]="rbxassetid://137065788934157",cast=
"rbxassetid://98202245922071",castle=
"rbxassetid://119275077187784",cat=
"rbxassetid://124252153404931",cctv=
"rbxassetid://99979894766624",
["chart-area"]="rbxassetid://123446436762366",
["chart-bar-big"]="rbxassetid://72336824986044",
["chart-bar-decreasing"]="rbxassetid://107217459044963",
["chart-bar-increasing"]="rbxassetid://88268905998571",
["chart-bar-stacked"]="rbxassetid://98478751113024",
["chart-bar"]="rbxassetid://105389816384108",
["chart-candlestick"]="rbxassetid://125676898615697",
["chart-column-big"]="rbxassetid://98598733210787",
["chart-column-decreasing"]="rbxassetid://73586137373563",
["chart-column-increasing"]="rbxassetid://120421615068601",
["chart-column-stacked"]="rbxassetid://86031449675105",
["chart-column"]="rbxassetid://97915995538580",
["chart-gantt"]="rbxassetid://88811660555940",
["chart-line"]="rbxassetid://101833156055618",
["chart-network"]="rbxassetid://104027882693561",
["chart-no-axes-column-decreasing"]="rbxassetid://123371717192542",
["chart-no-axes-column-increasing"]="rbxassetid://140383830943049",
["chart-no-axes-column"]="rbxassetid://94078751170351",
["chart-no-axes-combined"]="rbxassetid://121424233161912",
["chart-no-axes-gantt"]="rbxassetid://131936541106368",
["chart-pie"]="rbxassetid://113412261630136",
["chart-scatter"]="rbxassetid://108217585014571",
["chart-spline"]="rbxassetid://90307460742494",
["check-check"]="rbxassetid://95183312173858",
["check-line"]="rbxassetid://115122343485290",check=
"rbxassetid://93898873302694",
["chef-hat"]="rbxassetid://121744015002573",cherry=
"rbxassetid://139519182403183",
["chess-bishop"]="rbxassetid://121701705580238",
["chess-king"]="rbxassetid://90885687223462",
["chess-knight"]="rbxassetid://96467707042169",
["chess-pawn"]="rbxassetid://111318574652751",
["chess-queen"]="rbxassetid://98304702099749",
["chess-rook"]="rbxassetid://76223925830262",
["chevron-down"]="rbxassetid://134243273101015",
["chevron-first"]="rbxassetid://105243363790238",
["chevron-last"]="rbxassetid://89268452603731",
["chevron-left"]="rbxassetid://73780377692148",
["chevron-right"]="rbxassetid://92473583511724",
["chevron-up"]="rbxassetid://122444883127455",
["chevrons-down-up"]="rbxassetid://139404716013205",
["chevrons-down"]="rbxassetid://100524612205956",
["chevrons-left-right-ellipsis"]="rbxassetid://125035817741526",
["chevrons-left-right"]="rbxassetid://87910685945204",
["chevrons-left"]="rbxassetid://82617201744347",
["chevrons-right-left"]="rbxassetid://87149546686569",
["chevrons-right"]="rbxassetid://139121276490483",
["chevrons-up-down"]="rbxassetid://131833120209646",
["chevrons-up"]="rbxassetid://100467452364672",chromium=
"rbxassetid://128165143739006",church=
"rbxassetid://113714744350666",
["cigarette-off"]="rbxassetid://77797883078452",
["circle-alert"]="rbxassetid://83898160590116",
["circle-arrow-down"]="rbxassetid://95901860261344",
["circle-arrow-left"]="rbxassetid://102148876968988",
["circle-arrow-out-down-left"]="rbxassetid://140598097856694",
["circle-arrow-out-down-right"]="rbxassetid://119952801379305",
["circle-arrow-out-up-left"]="rbxassetid://132858212688303",
["circle-arrow-out-up-right"]="rbxassetid://81783743753173",
["circle-arrow-right"]="rbxassetid://70786767999559",
["circle-arrow-up"]="rbxassetid://84395128546494",
["circle-check-big"]="rbxassetid://93202927221730",
["circle-check"]="rbxassetid://85262178816537",
["circle-chevron-down"]="rbxassetid://137069490345718",
["circle-chevron-left"]="rbxassetid://130250009740827",
["circle-chevron-right"]="rbxassetid://125943696958495",
["circle-chevron-up"]="rbxassetid://111223574026321",
["circle-dashed"]="rbxassetid://126799443883746",
["circle-divide"]="rbxassetid://106398997754208",
["circle-dollar-sign"]="rbxassetid://91106238890387",
["circle-dot-dashed"]="rbxassetid://111451232827180",
["circle-dot"]="rbxassetid://82947033619201",
["circle-ellipsis"]="rbxassetid://91687150884779",
["circle-equal"]="rbxassetid://95133963751438",
["circle-fading-arrow-up"]="rbxassetid://104648212910336",
["circle-fading-plus"]="rbxassetid://91847890443490",
["circle-gauge"]="rbxassetid://108157549473765",
["circle-minus"]="rbxassetid://133556159576809",
["circle-off"]="rbxassetid://97923456918886",
["circle-parking-off"]="rbxassetid://128369410981252",
["circle-parking"]="rbxassetid://124034962915196",
["circle-pause"]="rbxassetid://139337739700879",
["circle-percent"]="rbxassetid://133311912860256",
["circle-play"]="rbxassetid://120408917249739",
["circle-plus"]="rbxassetid://113157136350384",
["circle-pound-sterling"]="rbxassetid://105476153083828",
["circle-power"]="rbxassetid://140676030155098",
["circle-question-mark"]="rbxassetid://97516698664325",
["circle-slash-2"]="rbxassetid://136766902186549",
["circle-slash"]="rbxassetid://125206439913049",
["circle-small"]="rbxassetid://73685402843600",
["circle-star"]="rbxassetid://120318414957104",
["circle-stop"]="rbxassetid://87400503942659",
["circle-user-round"]="rbxassetid://95489465399880",
["circle-user"]="rbxassetid://136220511671311",
["circle-x"]="rbxassetid://76821953846248",circle=
"rbxassetid://130359823580534",
["circuit-board"]="rbxassetid://107695264369312",citrus=
"rbxassetid://139018222976433",clapperboard=
"rbxassetid://132660667070200",
["clipboard-check"]="rbxassetid://92649798577170",
["clipboard-clock"]="rbxassetid://123957515687745",
["clipboard-copy"]="rbxassetid://125851897718493",
["clipboard-list"]="rbxassetid://96460215958908",
["clipboard-minus"]="rbxassetid://107968008485671",
["clipboard-paste"]="rbxassetid://74382068849983",
["clipboard-pen-line"]="rbxassetid://77711589791615",
["clipboard-pen"]="rbxassetid://75290966822953",
["clipboard-plus"]="rbxassetid://134285318675662",
["clipboard-type"]="rbxassetid://89949374318028",
["clipboard-x"]="rbxassetid://102222456890103",clipboard=
"rbxassetid://89601995828423",
["clock-1"]="rbxassetid://129363225422045",
["clock-10"]="rbxassetid://104332695855541",
["clock-11"]="rbxassetid://119023205186105",
["clock-12"]="rbxassetid://117789618723068",
["clock-2"]="rbxassetid://134710777209413",
["clock-3"]="rbxassetid://136385631189327",
["clock-4"]="rbxassetid://121808839832144",
["clock-5"]="rbxassetid://85082019959457",
["clock-6"]="rbxassetid://71009733505593",
["clock-7"]="rbxassetid://103111188546225",
["clock-8"]="rbxassetid://110059272125337",
["clock-9"]="rbxassetid://77610027126437",
["clock-alert"]="rbxassetid://97157344465162",
["clock-arrow-down"]="rbxassetid://92349314416042",
["clock-arrow-up"]="rbxassetid://111484286332629",
["clock-check"]="rbxassetid://85231630218857",
["clock-fading"]="rbxassetid://93205297285245",
["clock-plus"]="rbxassetid://93367709263150",clock=
"rbxassetid://121808839832144",
["closed-caption"]="rbxassetid://99832644030788",
["cloud-alert"]="rbxassetid://91967273658626",
["cloud-check"]="rbxassetid://97318598202432",
["cloud-cog"]="rbxassetid://96497764065749",
["cloud-download"]="rbxassetid://121435581993566",
["cloud-drizzle"]="rbxassetid://139525315752605",
["cloud-fog"]="rbxassetid://76650233148776",
["cloud-hail"]="rbxassetid://72320462748242",
["cloud-lightning"]="rbxassetid://133517088924849",
["cloud-moon-rain"]="rbxassetid://127667837827018",
["cloud-moon"]="rbxassetid://71938114737914",
["cloud-off"]="rbxassetid://131907154501444",
["cloud-rain-wind"]="rbxassetid://107414583736721",
["cloud-rain"]="rbxassetid://105547081967408",
["cloud-snow"]="rbxassetid://72307126270226",
["cloud-sun-rain"]="rbxassetid://99041604425705",
["cloud-sun"]="rbxassetid://86114208148727",
["cloud-upload"]="rbxassetid://93307473217005",cloud=
"rbxassetid://121226497050352",cloudy=
"rbxassetid://105360479023346",clover=
"rbxassetid://74925550436750",club=
"rbxassetid://108490365816628",
["code-xml"]="rbxassetid://130150477351734",code=
"rbxassetid://107380207681249",codepen=
"rbxassetid://135643965971885",codesandbox=
"rbxassetid://106911852964823",coffee=
"rbxassetid://106864403231093",cog=
"rbxassetid://116544501716299",coins=
"rbxassetid://116510979641930",
["columns-2"]="rbxassetid://113004100221850",
["columns-3-cog"]="rbxassetid://121589691981064",
["columns-3"]="rbxassetid://115223357399375",
["columns-4"]="rbxassetid://130807991968419",combine=
"rbxassetid://79908476334048",command=
"rbxassetid://93648221906330",compass=
"rbxassetid://115123411028382",component=
"rbxassetid://110027788875080",computer=
"rbxassetid://77480056459407",
["concierge-bell"]="rbxassetid://140384259310436",cone=
"rbxassetid://97759550688437",construction=
"rbxassetid://106539489968173",
["contact-round"]="rbxassetid://71907624112229",contact=
"rbxassetid://75868297719012",container=
"rbxassetid://91507237573499",contrast=
"rbxassetid://112796643981497",cookie=
"rbxassetid://73159504540002",
["cooking-pot"]="rbxassetid://94959783129799",
["copy-check"]="rbxassetid://91177247988892",
["copy-minus"]="rbxassetid://109524509933035",
["copy-plus"]="rbxassetid://113618379616952",
["copy-slash"]="rbxassetid://93805787810390",
["copy-x"]="rbxassetid://106557557978061",copy=
"rbxassetid://78979572434545",copyleft=
"rbxassetid://78559055698593",copyright=
"rbxassetid://129433635747111",
["corner-down-left"]="rbxassetid://90473561177832",
["corner-down-right"]="rbxassetid://86512767702085",
["corner-left-down"]="rbxassetid://139876989150630",
["corner-left-up"]="rbxassetid://126228268096099",
["corner-right-down"]="rbxassetid://89237035551302",
["corner-right-up"]="rbxassetid://112851237026705",
["corner-up-left"]="rbxassetid://84669279763024",
["corner-up-right"]="rbxassetid://115099889693145",cpu=
"rbxassetid://77549309870247",
["creative-commons"]="rbxassetid://90408210735312",
["credit-card"]="rbxassetid://99163352872346",croissant=
"rbxassetid://130710485559420",crop=
"rbxassetid://116344601101413",cross=
"rbxassetid://101833377863588",crosshair=
"rbxassetid://134242818164054",crown=
"rbxassetid://127843403295538",cuboid=
"rbxassetid://75618807946111",
["cup-soda"]="rbxassetid://121098640829562",currency=
"rbxassetid://90551250119972",cylinder=
"rbxassetid://90569677179169",dam=
"rbxassetid://76874486231393",
["database-backup"]="rbxassetid://103403210984699",
["database-zap"]="rbxassetid://131199921258418",database=
"rbxassetid://126791525623846",
["decimals-arrow-left"]="rbxassetid://120198500638749",
["decimals-arrow-right"]="rbxassetid://118263047146797",delete=
"rbxassetid://126279426372342",dessert=
"rbxassetid://71508133278830",diameter=
"rbxassetid://97429051503783",
["diamond-minus"]="rbxassetid://128989071438290",
["diamond-percent"]="rbxassetid://107717860105959",
["diamond-plus"]="rbxassetid://134701163723675",diamond=
"rbxassetid://105846996304890",
["dice-1"]="rbxassetid://112650149591038",
["dice-2"]="rbxassetid://112278274566793",
["dice-3"]="rbxassetid://118526270626312",
["dice-4"]="rbxassetid://113365650364004",
["dice-5"]="rbxassetid://72768312430593",
["dice-6"]="rbxassetid://85376239182543",dices=
"rbxassetid://81268120302865",diff=
"rbxassetid://135052708609715",
["disc-2"]="rbxassetid://91419420404185",
["disc-3"]="rbxassetid://135470554736048",
["disc-album"]="rbxassetid://74693460404344",disc=
"rbxassetid://101908120120777",divide=
"rbxassetid://136678191878278",
["dna-off"]="rbxassetid://89612426361540",dna=
"rbxassetid://74007982981741",dock=
"rbxassetid://121997427160252",dog=
"rbxassetid://71920105558570",
["dollar-sign"]="rbxassetid://127320961224019",donut=
"rbxassetid://72204922742657",
["door-closed-locked"]="rbxassetid://74027613267551",
["door-closed"]="rbxassetid://136249099949073",
["door-open"]="rbxassetid://91306356501736",dot=
"rbxassetid://137321056643916",download=
"rbxassetid://134814648082393",
["drafting-compass"]="rbxassetid://99701976182841",drama=
"rbxassetid://110297795801577",dribbble=
"rbxassetid://80231809663849",drill=
"rbxassetid://108644821412796",drone=
"rbxassetid://117299095794783",
["droplet-off"]="rbxassetid://119365002225172",droplet=
"rbxassetid://100597455015098",droplets=
"rbxassetid://140111846025180",drum=
"rbxassetid://136979060344890",drumstick=
"rbxassetid://104662462521709",dumbbell=
"rbxassetid://80277236776212",
["ear-off"]="rbxassetid://87421916192807",ear=
"rbxassetid://121894949934209",
["earth-lock"]="rbxassetid://88814147073745",earth=
"rbxassetid://76231597751076",eclipse=
"rbxassetid://114829622118222",
["egg-fried"]="rbxassetid://90622538210545",
["egg-off"]="rbxassetid://92288321309285",egg=
"rbxassetid://117851493400222",
["ellipsis-vertical"]="rbxassetid://117978708573781",ellipsis=
"rbxassetid://140019550645825",
["equal-approximately"]="rbxassetid://105382689698323",
["equal-not"]="rbxassetid://76864449458032",equal=
"rbxassetid://123467780715624",eraser=
"rbxassetid://133957773112410",
["ethernet-port"]="rbxassetid://75391715149314",euro=
"rbxassetid://72229646524456",
["ev-charger"]="rbxassetid://97906158859623",expand=
"rbxassetid://137492887754537",
["external-link"]="rbxassetid://129331830773832",
["eye-closed"]="rbxassetid://111063268625789",
["eye-off"]="rbxassetid://135928786788378",eye=
"rbxassetid://100033680381365",facebook=
"rbxassetid://72098528632192",factory=
"rbxassetid://102170024318039",fan=
"rbxassetid://78391400440696",
["fast-forward"]="rbxassetid://121615540167909",feather=
"rbxassetid://91872927606406",fence=
"rbxassetid://123451565578029",
["ferris-wheel"]="rbxassetid://79729205796176",figma=
"rbxassetid://134182122852301",
["file-archive"]="rbxassetid://77018106869967",
["file-axis-3d"]="rbxassetid://133912328009885",
["file-badge"]="rbxassetid://74564895394477",
["file-box"]="rbxassetid://119264004071690",
["file-braces-corner"]="rbxassetid://77253337986109",
["file-braces"]="rbxassetid://95314128621234",
["file-chart-column-increasing"]="rbxassetid://134449481172067",
["file-chart-column"]="rbxassetid://82048481252560",
["file-chart-line"]="rbxassetid://71954360551345",
["file-chart-pie"]="rbxassetid://81072193564497",
["file-check-corner"]="rbxassetid://76295552859171",
["file-check"]="rbxassetid://82604001452455",
["file-clock"]="rbxassetid://102325208830990",
["file-code-corner"]="rbxassetid://78293841184371",
["file-code"]="rbxassetid://130978036895504",
["file-cog"]="rbxassetid://101385347151368",
["file-diff"]="rbxassetid://96147216772241",
["file-digit"]="rbxassetid://89220220354580",
["file-down"]="rbxassetid://120650154178290",
["file-exclamation-point"]="rbxassetid://102821865889635",
["file-headphone"]="rbxassetid://100533735901986",
["file-heart"]="rbxassetid://132214916401696",
["file-image"]="rbxassetid://123334057511782",
["file-input"]="rbxassetid://124728604166044",
["file-key"]="rbxassetid://118790255921100",
["file-lock"]="rbxassetid://72170228691242",
["file-minus-corner"]="rbxassetid://119263271735124",
["file-minus"]="rbxassetid://111014798459222",
["file-music"]="rbxassetid://134948051536671",
["file-output"]="rbxassetid://92146832572911",
["file-pen-line"]="rbxassetid://104622936345006",
["file-pen"]="rbxassetid://79556179730240",
["file-play"]="rbxassetid://89006821567838",
["file-plus-corner"]="rbxassetid://76544604043974",
["file-plus"]="rbxassetid://78881710800060",
["file-question-mark"]="rbxassetid://127617422859576",
["file-scan"]="rbxassetid://129480105228213",
["file-search-corner"]="rbxassetid://90974165234008",
["file-search"]="rbxassetid://97780235974933",
["file-signal"]="rbxassetid://122070252538165",
["file-sliders"]="rbxassetid://85787771732439",
["file-spreadsheet"]="rbxassetid://134501869359270",
["file-stack"]="rbxassetid://138929929862605",
["file-symlink"]="rbxassetid://91865722036510",
["file-terminal"]="rbxassetid://116757454755476",
["file-text"]="rbxassetid://90496405707281",
["file-type-corner"]="rbxassetid://124902230275209",
["file-type"]="rbxassetid://115272552799361",
["file-up"]="rbxassetid://131173039312748",
["file-user"]="rbxassetid://99552018455009",
["file-video-camera"]="rbxassetid://81719056173960",
["file-volume"]="rbxassetid://111264764438958",
["file-x-corner"]="rbxassetid://87554136773609",
["file-x"]="rbxassetid://107333775515154",file=
"rbxassetid://74748492079329",files=
"rbxassetid://102806336233202",film=
"rbxassetid://120978945609706",fingerprint=
"rbxassetid://112173305232811",
["fire-extinguisher"]="rbxassetid://111643493006960",
["fish-off"]="rbxassetid://89756724887508",
["fish-symbol"]="rbxassetid://118475177681618",fish=
"rbxassetid://124360663785796",
["flag-off"]="rbxassetid://112944528856799",
["flag-triangle-left"]="rbxassetid://88045221285272",
["flag-triangle-right"]="rbxassetid://108292480304566",flag=
"rbxassetid://78183383236196",
["flame-kindling"]="rbxassetid://139728976917928",flame=
"rbxassetid://98218034436456",
["flashlight-off"]="rbxassetid://79780362871740",flashlight=
"rbxassetid://100286985600444",
["flask-conical-off"]="rbxassetid://112597970025298",
["flask-conical"]="rbxassetid://128406680901165",
["flask-round"]="rbxassetid://127508287324940",
["flip-horizontal-2"]="rbxassetid://103726993598186",
["flip-horizontal"]="rbxassetid://122937530107837",
["flip-vertical-2"]="rbxassetid://103836358956328",
["flip-vertical"]="rbxassetid://108003917346888",
["flower-2"]="rbxassetid://72934574245145",flower=
"rbxassetid://86129438272762",focus=
"rbxassetid://87493973153317",
["fold-horizontal"]="rbxassetid://92835712442240",
["fold-vertical"]="rbxassetid://108873727253656",
["folder-archive"]="rbxassetid://97312009460206",
["folder-check"]="rbxassetid://128492920904557",
["folder-clock"]="rbxassetid://111964836738545",
["folder-closed"]="rbxassetid://118286209350843",
["folder-code"]="rbxassetid://70624096349370",
["folder-cog"]="rbxassetid://85299519462846",
["folder-dot"]="rbxassetid://138687772725278",
["folder-down"]="rbxassetid://118044108459225",
["folder-git-2"]="rbxassetid://101394054141166",
["folder-git"]="rbxassetid://121885778095158",
["folder-heart"]="rbxassetid://79104747211105",
["folder-input"]="rbxassetid://90699920697871",
["folder-kanban"]="rbxassetid://78313285104072",
["folder-key"]="rbxassetid://85270407596791",
["folder-lock"]="rbxassetid://119201572260567",
["folder-minus"]="rbxassetid://85648718999010",
["folder-open-dot"]="rbxassetid://74741494767354",
["folder-open"]="rbxassetid://76018996254888",
["folder-output"]="rbxassetid://101532447937612",
["folder-pen"]="rbxassetid://112770491173911",
["folder-plus"]="rbxassetid://91865663406119",
["folder-root"]="rbxassetid://103333751154693",
["folder-search-2"]="rbxassetid://71276453442655",
["folder-search"]="rbxassetid://110568075123861",
["folder-symlink"]="rbxassetid://127485747227189",
["folder-sync"]="rbxassetid://91544602659796",
["folder-tree"]="rbxassetid://85577554337861",
["folder-up"]="rbxassetid://72008269765857",
["folder-x"]="rbxassetid://91699618247635",folder=
"rbxassetid://80846616596607",folders=
"rbxassetid://110351216219061",footprints=
"rbxassetid://139192589041315",forklift=
"rbxassetid://72030930983101",forward=
"rbxassetid://97545944739523",frame=
"rbxassetid://109080612832751",framer=
"rbxassetid://108384807262391",frown=
"rbxassetid://124407301067982",fuel=
"rbxassetid://106447647274511",fullscreen=
"rbxassetid://77793665526178",
["funnel-plus"]="rbxassetid://100780233821928",
["funnel-x"]="rbxassetid://70984385812555",funnel=
"rbxassetid://108829540827529",
["gallery-horizontal-end"]="rbxassetid://74672430161161",
["gallery-horizontal"]="rbxassetid://80004001442122",
["gallery-thumbnails"]="rbxassetid://136219289862706",
["gallery-vertical-end"]="rbxassetid://106461402088317",
["gallery-vertical"]="rbxassetid://119299431466725",
["gamepad-2"]="rbxassetid://92483947987410",
["gamepad-directional"]="rbxassetid://84342305212226",gamepad=
"rbxassetid://121607283959010",gauge=
"rbxassetid://110273524101447",gavel=
"rbxassetid://78952298198456",gem=
"rbxassetid://112904952151156",
["georgian-lari"]="rbxassetid://98084432591687",ghost=
"rbxassetid://113822048130017",gift=
"rbxassetid://109855212076373",
["git-branch-minus"]="rbxassetid://97385010649411",
["git-branch-plus"]="rbxassetid://125944221134316",
["git-branch"]="rbxassetid://90490195516649",
["git-commit-horizontal"]="rbxassetid://133646041800147",
["git-commit-vertical"]="rbxassetid://122098032990350",
["git-compare-arrows"]="rbxassetid://84874426520216",
["git-compare"]="rbxassetid://91945124438792",
["git-fork"]="rbxassetid://89954992404765",
["git-graph"]="rbxassetid://86166832019304",
["git-merge"]="rbxassetid://131833355158059",
["git-pull-request-arrow"]="rbxassetid://94507974577439",
["git-pull-request-closed"]="rbxassetid://78070600389091",
["git-pull-request-create-arrow"]="rbxassetid://127422677061091",
["git-pull-request-create"]="rbxassetid://105929577383926",
["git-pull-request-draft"]="rbxassetid://76173459869943",
["git-pull-request"]="rbxassetid://138463010991471",github=
"rbxassetid://120349554354380",gitlab=
"rbxassetid://114054627192933",
["glass-water"]="rbxassetid://115526102400988",glasses=
"rbxassetid://87936407455373",
["globe-lock"]="rbxassetid://134065526704402",globe=
"rbxassetid://114238209622913",goal=
"rbxassetid://120517954878160",gpu=
"rbxassetid://95577823614219",
["graduation-cap"]="rbxassetid://93771896340220",grape=
"rbxassetid://134760640415561",
["grid-2x2-check"]="rbxassetid://138468840220821",
["grid-2x2-plus"]="rbxassetid://91811610580247",
["grid-2x2-x"]="rbxassetid://72407303981388",
["grid-2x2"]="rbxassetid://99050491897640",
["grid-3x2"]="rbxassetid://95528684210010",
["grid-3x3"]="rbxassetid://70419024781206",
["grip-horizontal"]="rbxassetid://136255899715930",
["grip-vertical"]="rbxassetid://137183678565296",grip=
"rbxassetid://109058783556768",group=
"rbxassetid://107643418926671",guitar=
"rbxassetid://75915531867926",ham=
"rbxassetid://74465607934635",hamburger=
"rbxassetid://93086916815495",hammer=
"rbxassetid://83545120140895",
["hand-coins"]="rbxassetid://126990543175462",
["hand-fist"]="rbxassetid://83341608917591",
["hand-grab"]="rbxassetid://88867162163985",
["hand-heart"]="rbxassetid://117507367668412",
["hand-helping"]="rbxassetid://89897738419446",
["hand-metal"]="rbxassetid://113619498548713",
["hand-platter"]="rbxassetid://88594727743168",hand=
"rbxassetid://130703864968637",handbag=
"rbxassetid://135675846264061",handshake=
"rbxassetid://78442115255814",
["hard-drive-download"]="rbxassetid://73913801230614",
["hard-drive-upload"]="rbxassetid://85762133615118",
["hard-drive"]="rbxassetid://88183305858463",
["hard-hat"]="rbxassetid://128050846767382",hash=
"rbxassetid://82890331678520",
["hat-glasses"]="rbxassetid://101165538224815",haze=
"rbxassetid://108857561768901",
["hdmi-port"]="rbxassetid://103693661037020",
["heading-1"]="rbxassetid://118129315662110",
["heading-2"]="rbxassetid://110209069670094",
["heading-3"]="rbxassetid://90267885237062",
["heading-4"]="rbxassetid://129625620307602",
["heading-5"]="rbxassetid://120386663181267",
["heading-6"]="rbxassetid://90959079775093",heading=
"rbxassetid://129254312067735",
["headphone-off"]="rbxassetid://85038251615641",headphones=
"rbxassetid://118833729589183",headset=
"rbxassetid://129269236787694",
["heart-crack"]="rbxassetid://110987638564119",
["heart-handshake"]="rbxassetid://111483078692002",
["heart-minus"]="rbxassetid://96827380163326",
["heart-off"]="rbxassetid://89748414415617",
["heart-plus"]="rbxassetid://94877796283249",
["heart-pulse"]="rbxassetid://129352925579546",heart=
"rbxassetid://116559368303288",heater=
"rbxassetid://140478466880916",helicopter=
"rbxassetid://111557171735930",hexagon=
"rbxassetid://127592089339199",highlighter=
"rbxassetid://77411555641113",history=
"rbxassetid://123980022019922",
["hop-off"]="rbxassetid://103386036934034",hop=
"rbxassetid://82778923997672",hospital=
"rbxassetid://105868763850707",hotel=
"rbxassetid://132283390859718",hourglass=
"rbxassetid://86160434939203",
["house-heart"]="rbxassetid://136054771868597",
["house-plug"]="rbxassetid://71438263712075",
["house-plus"]="rbxassetid://118495165208309",
["house-wifi"]="rbxassetid://126495519725698",house=
"rbxassetid://98755624629571",
["ice-cream-bowl"]="rbxassetid://124867218454386",
["ice-cream-cone"]="rbxassetid://90751397288639",
["id-card-lanyard"]="rbxassetid://90761480469224",
["id-card"]="rbxassetid://75354294622640",
["image-down"]="rbxassetid://78972295741235",
["image-minus"]="rbxassetid://101066016918565",
["image-off"]="rbxassetid://81934811700938",
["image-play"]="rbxassetid://129501806784210",
["image-plus"]="rbxassetid://70391970623917",
["image-up"]="rbxassetid://126610009605241",
["image-upscale"]="rbxassetid://106963545024679",images=
"rbxassetid://79350649395557",import=
"rbxassetid://116545008906029",inbox=
"rbxassetid://112591360302868",
["indian-rupee"]="rbxassetid://113038778381805",infinity=
"rbxassetid://98083086936965",info=
"rbxassetid://124560466474914",
["inspection-panel"]="rbxassetid://70905313146088",instagram=
"rbxassetid://119864798614855",italic=
"rbxassetid://96220378864282",
["iteration-ccw"]="rbxassetid://140221832794083",
["iteration-cw"]="rbxassetid://95534489554662",
["japanese-yen"]="rbxassetid://106362863465813",joystick=
"rbxassetid://99416790224739",kanban=
"rbxassetid://125934100055431",kayak=
"rbxassetid://136107544609389",
["key-round"]="rbxassetid://83619031955390",
["key-square"]="rbxassetid://94621420033649",key=
"rbxassetid://96510194465420",
["keyboard-music"]="rbxassetid://121058541758636",
["keyboard-off"]="rbxassetid://92466375369772",keyboard=
"rbxassetid://121474456068237",
["lamp-ceiling"]="rbxassetid://80032758469141",
["lamp-desk"]="rbxassetid://85290686983238",
["lamp-floor"]="rbxassetid://104585881375892",
["lamp-wall-down"]="rbxassetid://91271394132073",
["lamp-wall-up"]="rbxassetid://132141464337445",lamp=
"rbxassetid://110730830653382",
["land-plot"]="rbxassetid://96449039620294",landmark=
"rbxassetid://76885079756393",languages=
"rbxassetid://90816903776498",
["laptop-minimal-check"]="rbxassetid://114352019833865",
["laptop-minimal"]="rbxassetid://136705765566068",laptop=
"rbxassetid://111387063244975",
["lasso-select"]="rbxassetid://105609719912753",lasso=
"rbxassetid://121072936884007",laugh=
"rbxassetid://104491311361166",
["layers-2"]="rbxassetid://70536710516357",layers=
"rbxassetid://81973586053257",
["layout-dashboard"]="rbxassetid://139929981863901",
["layout-grid"]="rbxassetid://81344910161871",
["layout-list"]="rbxassetid://87462136296578",
["layout-panel-left"]="rbxassetid://125092469751491",
["layout-panel-top"]="rbxassetid://91943941515944",
["layout-template"]="rbxassetid://115564446417985",leaf=
"rbxassetid://119951075637174",
["leafy-green"]="rbxassetid://105146290493154",lectern=
"rbxassetid://106166425183862",
["library-big"]="rbxassetid://106794530191412",library=
"rbxassetid://114334671982047",
["life-buoy"]="rbxassetid://81168450671956",ligature=
"rbxassetid://111397873269411",
["lightbulb-off"]="rbxassetid://83795722296178",lightbulb=
"rbxassetid://103871245626488",
["line-squiggle"]="rbxassetid://109555164424447",
["link-2-off"]="rbxassetid://76885956296867",
["link-2"]="rbxassetid://86072351557466",link=
"rbxassetid://131607023382430",linkedin=
"rbxassetid://132842789255788",
["list-check"]="rbxassetid://72374358471156",
["list-checks"]="rbxassetid://99809353635593",
["list-chevrons-down-up"]="rbxassetid://137409641500711",
["list-chevrons-up-down"]="rbxassetid://81825351389084",
["list-collapse"]="rbxassetid://124505247702401",
["list-end"]="rbxassetid://77650610048119",
["list-filter-plus"]="rbxassetid://96385120752336",
["list-filter"]="rbxassetid://103321376129527",
["list-indent-decrease"]="rbxassetid://137879979228193",
["list-indent-increase"]="rbxassetid://79051053161201",
["list-minus"]="rbxassetid://138507965142671",
["list-music"]="rbxassetid://126380635781840",
["list-ordered"]="rbxassetid://83212528113913",
["list-plus"]="rbxassetid://112384738137814",
["list-restart"]="rbxassetid://91703153577421",
["list-start"]="rbxassetid://84828348299727",
["list-todo"]="rbxassetid://132980603752108",
["list-tree"]="rbxassetid://97685396239010",
["list-video"]="rbxassetid://93648525452489",
["list-x"]="rbxassetid://113025303988861",list=
"rbxassetid://113179976918783",
["loader-circle"]="rbxassetid://116535712789945",
["loader-pinwheel"]="rbxassetid://108513357940900",loader=
"rbxassetid://78408734580845",
["locate-fixed"]="rbxassetid://137367361548433",
["locate-off"]="rbxassetid://73729216338137",locate=
"rbxassetid://84467676590391",
["lock-keyhole-open"]="rbxassetid://110863509313073",
["lock-keyhole"]="rbxassetid://78672912777756",
["lock-open"]="rbxassetid://93597915325122",lock=
"rbxassetid://134724289526879",
["log-in"]="rbxassetid://103768533135201",
["log-out"]="rbxassetid://84895399304975",logs=
"rbxassetid://89772091251787",lollipop=
"rbxassetid://84681611583044",luggage=
"rbxassetid://76619236486400",magnet=
"rbxassetid://135162361226972",
["mail-check"]="rbxassetid://86921536259917",
["mail-minus"]="rbxassetid://81989813236553",
["mail-open"]="rbxassetid://122785416858638",
["mail-plus"]="rbxassetid://104886401588341",
["mail-question-mark"]="rbxassetid://126540170949819",
["mail-search"]="rbxassetid://135616173775287",
["mail-warning"]="rbxassetid://81495303676089",
["mail-x"]="rbxassetid://74607841705644",mail=
"rbxassetid://103945161245599",mailbox=
"rbxassetid://82765503320335",mails=
"rbxassetid://90673453450080",
["map-minus"]="rbxassetid://129525760577747",
["map-pin-check-inside"]="rbxassetid://107130529843809",
["map-pin-check"]="rbxassetid://118110914690154",
["map-pin-house"]="rbxassetid://80546885029816",
["map-pin-minus-inside"]="rbxassetid://79005529692964",
["map-pin-minus"]="rbxassetid://74518762643623",
["map-pin-off"]="rbxassetid://82474689391020",
["map-pin-pen"]="rbxassetid://113515395277504",
["map-pin-plus-inside"]="rbxassetid://134639656514430",
["map-pin-plus"]="rbxassetid://91875228967029",
["map-pin-x-inside"]="rbxassetid://126235934252379",
["map-pin-x"]="rbxassetid://101085273547316",
["map-pin"]="rbxassetid://84279202219901",
["map-pinned"]="rbxassetid://103963788475034",
["map-plus"]="rbxassetid://129388826743495",map=
"rbxassetid://95107167260947",
["mars-stroke"]="rbxassetid://131973193186828",mars=
"rbxassetid://111287112372511",martini=
"rbxassetid://82977695401058",
["maximize-2"]="rbxassetid://73085922906397",maximize=
"rbxassetid://76045941763188",medal=
"rbxassetid://79016002264450",
["megaphone-off"]="rbxassetid://124280774193935",megaphone=
"rbxassetid://118759541854879",meh=
"rbxassetid://132197867028557",
["memory-stick"]="rbxassetid://93212591343119",menu=
"rbxassetid://77021539815611",merge=
"rbxassetid://126201866476775",
["message-circle-code"]="rbxassetid://112865244991651",
["message-circle-dashed"]="rbxassetid://81525157881897",
["message-circle-heart"]="rbxassetid://101990756073677",
["message-circle-more"]="rbxassetid://92856823884663",
["message-circle-off"]="rbxassetid://134955643890328",
["message-circle-plus"]="rbxassetid://106562979649273",
["message-circle-question-mark"]="rbxassetid://107700302759934",
["message-circle-reply"]="rbxassetid://137071749508334",
["message-circle-warning"]="rbxassetid://119020096067894",
["message-circle-x"]="rbxassetid://126843387725536",
["message-circle"]="rbxassetid://127255077587058",
["message-square-code"]="rbxassetid://110968863152123",
["message-square-dashed"]="rbxassetid://107653455516238",
["message-square-diff"]="rbxassetid://75472190472625",
["message-square-dot"]="rbxassetid://127806382463916",
["message-square-heart"]="rbxassetid://75612811742074",
["message-square-lock"]="rbxassetid://81268215619563",
["message-square-more"]="rbxassetid://120139782405970",
["message-square-off"]="rbxassetid://99961019005789",
["message-square-plus"]="rbxassetid://76934450256199",
["message-square-quote"]="rbxassetid://116670768629340",
["message-square-reply"]="rbxassetid://130985622754637",
["message-square-share"]="rbxassetid://131017005324026",
["message-square-text"]="rbxassetid://94899503194205",
["message-square-warning"]="rbxassetid://138432903962261",
["message-square-x"]="rbxassetid://137285463279462",
["message-square"]="rbxassetid://83881670383280",
["messages-square"]="rbxassetid://97532166733358",
["mic-off"]="rbxassetid://82123034444822",
["mic-vocal"]="rbxassetid://99082286164362",mic=
"rbxassetid://89640799126523",microchip=
"rbxassetid://73937907669903",microscope=
"rbxassetid://116875530102782",microwave=
"rbxassetid://108411735353008",milestone=
"rbxassetid://101618292325920",
["milk-off"]="rbxassetid://72388480962742",milk=
"rbxassetid://96221903896918",
["minimize-2"]="rbxassetid://116269596042539",minimize=
"rbxassetid://121304296213645",minus=
"rbxassetid://118026365011536",
["monitor-check"]="rbxassetid://86651948439229",
["monitor-cloud"]="rbxassetid://85931096038318",
["monitor-cog"]="rbxassetid://94345128715799",
["monitor-dot"]="rbxassetid://130394010063680",
["monitor-down"]="rbxassetid://97466933743423",
["monitor-off"]="rbxassetid://74395526657953",
["monitor-pause"]="rbxassetid://76002184067562",
["monitor-play"]="rbxassetid://133018824306217",
["monitor-smartphone"]="rbxassetid://84335680433378",
["monitor-speaker"]="rbxassetid://81744810060380",
["monitor-stop"]="rbxassetid://98708958984757",
["monitor-up"]="rbxassetid://96035360858377",
["monitor-x"]="rbxassetid://126265210441423",monitor=
"rbxassetid://72664649203050",
["moon-star"]="rbxassetid://82782200506348",moon=
"rbxassetid://83380517901735",motorbike=
"rbxassetid://94580787368233",
["mountain-snow"]="rbxassetid://105315495740588",mountain=
"rbxassetid://73269957566415",
["mouse-off"]="rbxassetid://75267871697595",
["mouse-pointer-2-off"]="rbxassetid://104701076865632",
["mouse-pointer-2"]="rbxassetid://117093892862228",
["mouse-pointer-ban"]="rbxassetid://106849413057133",
["mouse-pointer-click"]="rbxassetid://107150227368485",
["mouse-pointer"]="rbxassetid://72322454962935",mouse=
"rbxassetid://73096068864710",
["move-3d"]="rbxassetid://103365982054003",
["move-diagonal-2"]="rbxassetid://117298577948096",
["move-diagonal"]="rbxassetid://101433481954184",
["move-down-left"]="rbxassetid://102819433534567",
["move-down-right"]="rbxassetid://101479760041877",
["move-down"]="rbxassetid://70510115135583",
["move-horizontal"]="rbxassetid://88513523439149",
["move-left"]="rbxassetid://137614740247980",
["move-right"]="rbxassetid://132455779472989",
["move-up-left"]="rbxassetid://139079815540148",
["move-up-right"]="rbxassetid://105885140592646",
["move-up"]="rbxassetid://84505444262658",
["move-vertical"]="rbxassetid://86234730730899",move=
"rbxassetid://116138709011735",
["music-2"]="rbxassetid://134397426600888",
["music-3"]="rbxassetid://94466120066498",
["music-4"]="rbxassetid://132459323665838",music=
"rbxassetid://113343203848535",
["navigation-2-off"]="rbxassetid://116569611780763",
["navigation-2"]="rbxassetid://81889066747907",
["navigation-off"]="rbxassetid://87003270290777",navigation=
"rbxassetid://79308213542922",network=
"rbxassetid://127410729922644",newspaper=
"rbxassetid://123479530460544",nfc=
"rbxassetid://76822396542242",
["non-binary"]="rbxassetid://78442360386235",
["notebook-pen"]="rbxassetid://140380614761023",
["notebook-tabs"]="rbxassetid://127371085570083",
["notebook-text"]="rbxassetid://93061585217270",notebook=
"rbxassetid://136132108664987",
["notepad-text-dashed"]="rbxassetid://135793446376219",
["notepad-text"]="rbxassetid://93404682958966",
["nut-off"]="rbxassetid://78795397311573",nut=
"rbxassetid://127146410705656",
["octagon-alert"]="rbxassetid://140438367956051",
["octagon-minus"]="rbxassetid://74720436795421",
["octagon-pause"]="rbxassetid://103161463909039",
["octagon-x"]="rbxassetid://90498161006311",octagon=
"rbxassetid://120803515514852",omega=
"rbxassetid://70414080018786",option=
"rbxassetid://100776883894054",orbit=
"rbxassetid://108926136860562",origami=
"rbxassetid://136020626667101",
["package-2"]="rbxassetid://70394974762575",
["package-check"]="rbxassetid://102374216055130",
["package-minus"]="rbxassetid://114492858789692",
["package-open"]="rbxassetid://132890233237818",
["package-plus"]="rbxassetid://129261988138366",
["package-search"]="rbxassetid://95465120894145",
["package-x"]="rbxassetid://70818501607442",package=
"rbxassetid://97261141732706",
["paint-bucket"]="rbxassetid://124275586663284",
["paint-roller"]="rbxassetid://115248074358348",
["paintbrush-vertical"]="rbxassetid://105151296591292",paintbrush=
"rbxassetid://125572663700289",palette=
"rbxassetid://86350350950064",panda=
"rbxassetid://132509022802512",
["panel-bottom-close"]="rbxassetid://74287004071159",
["panel-bottom-dashed"]="rbxassetid://131084651621603",
["panel-bottom-open"]="rbxassetid://107768659586540",
["panel-bottom"]="rbxassetid://132127145048511",
["panel-left-close"]="rbxassetid://126579818823552",
["panel-left-dashed"]="rbxassetid://75536606374585",
["panel-left-open"]="rbxassetid://111075816195767",
["panel-left-right-dashed"]="rbxassetid://110100707973959",
["panel-left"]="rbxassetid://97419752870313",
["panel-right-close"]="rbxassetid://139528655524132",
["panel-right-dashed"]="rbxassetid://94959793877311",
["panel-right-open"]="rbxassetid://118114419142794",
["panel-right"]="rbxassetid://116365035443156",
["panel-top-bottom-dashed"]="rbxassetid://134737235653344",
["panel-top-close"]="rbxassetid://83578325777808",
["panel-top-dashed"]="rbxassetid://70522913169237",
["panel-top-open"]="rbxassetid://137959875507454",
["panel-top"]="rbxassetid://75838479462875",
["panels-left-bottom"]="rbxassetid://72996856149149",
["panels-right-bottom"]="rbxassetid://90659068960726",
["panels-top-left"]="rbxassetid://79858853850600",paperclip=
"rbxassetid://92088291163453",parentheses=
"rbxassetid://78950955173096",
["parking-meter"]="rbxassetid://84652733960568",
["party-popper"]="rbxassetid://111626795712193",pause=
"rbxassetid://74873705394436",
["paw-print"]="rbxassetid://112218825427601",
["pc-case"]="rbxassetid://122978648019101",
["pen-line"]="rbxassetid://109108135755303",
["pen-off"]="rbxassetid://84807123119438",
["pen-tool"]="rbxassetid://106145404953445",pen=
"rbxassetid://72037878096321",
["pencil-line"]="rbxassetid://88392917053533",
["pencil-off"]="rbxassetid://103330927652832",
["pencil-ruler"]="rbxassetid://110120288284597",pencil=
"rbxassetid://137986121120732",pentagon=
"rbxassetid://79184802179890",percent=
"rbxassetid://130155041032013",
["person-standing"]="rbxassetid://125020872044147",
["philippine-peso"]="rbxassetid://91173798254675",
["phone-call"]="rbxassetid://70555587592860",
["phone-forwarded"]="rbxassetid://113269614319737",
["phone-incoming"]="rbxassetid://82863576359288",
["phone-missed"]="rbxassetid://130156165198376",
["phone-off"]="rbxassetid://133318623553383",
["phone-outgoing"]="rbxassetid://104576478735825",phone=
"rbxassetid://128804946640049",pi=
"rbxassetid://74936036243146",piano=
"rbxassetid://85008880789520",pickaxe=
"rbxassetid://105888023317688",
["picture-in-picture-2"]="rbxassetid://112803319544468",
["picture-in-picture"]="rbxassetid://80579597835123",
["piggy-bank"]="rbxassetid://79498575790721",
["pilcrow-left"]="rbxassetid://103803000849583",
["pilcrow-right"]="rbxassetid://104881733911870",pilcrow=
"rbxassetid://139512780392871",
["pill-bottle"]="rbxassetid://118394692404597",pill=
"rbxassetid://73280534813448",
["pin-off"]="rbxassetid://127696372451750",pin=
"rbxassetid://120978111007514",pipette=
"rbxassetid://133167932934404",pizza=
"rbxassetid://126964453193501",
["plane-landing"]="rbxassetid://122555692211889",
["plane-takeoff"]="rbxassetid://117179478829575",plane=
"rbxassetid://126985561580989",play=
"rbxassetid://135609604299893",
["plug-2"]="rbxassetid://97912386476366",
["plug-zap"]="rbxassetid://74506269884055",plug=
"rbxassetid://99782373064495",plus=
"rbxassetid://111774323017047",
["pocket-knife"]="rbxassetid://134075428063965",pocket=
"rbxassetid://136686762542964",podcast=
"rbxassetid://109577075549215",
["pointer-off"]="rbxassetid://95488389312794",pointer=
"rbxassetid://92615117311099",popcorn=
"rbxassetid://139446511232750",popsicle=
"rbxassetid://112696318077073",
["pound-sterling"]="rbxassetid://127482649469130",
["power-off"]="rbxassetid://118768311012214",power=
"rbxassetid://96479131758775",presentation=
"rbxassetid://106134583757890",
["printer-check"]="rbxassetid://130273549443689",printer=
"rbxassetid://76080649734247",projector=
"rbxassetid://103281856385283",proportions=
"rbxassetid://130046855997237",puzzle=
"rbxassetid://136837798892463",pyramid=
"rbxassetid://107811442374127",
["qr-code"]="rbxassetid://105329945723350",quote=
"rbxassetid://103271711590001",rabbit=
"rbxassetid://98580518804206",radar=
"rbxassetid://138528222906635",radiation=
"rbxassetid://104499586848433",radical=
"rbxassetid://132758286926047",
["radio-receiver"]="rbxassetid://129598303378835",
["radio-tower"]="rbxassetid://93958663130054",radio=
"rbxassetid://85611589536956",radius=
"rbxassetid://89814505307129",
["rail-symbol"]="rbxassetid://134295386306962",rainbow=
"rbxassetid://132488862841895",rat=
"rbxassetid://127400975953159",ratio=
"rbxassetid://126369423897295",
["receipt-cent"]="rbxassetid://91557573925201",
["receipt-euro"]="rbxassetid://94015722210295",
["receipt-indian-rupee"]="rbxassetid://89718170439990",
["receipt-japanese-yen"]="rbxassetid://132472560758851",
["receipt-pound-sterling"]="rbxassetid://73934967569625",
["receipt-russian-ruble"]="rbxassetid://105164576936853",
["receipt-swiss-franc"]="rbxassetid://72503668620116",
["receipt-text"]="rbxassetid://138483536013737",
["receipt-turkish-lira"]="rbxassetid://91950765836342",receipt=
"rbxassetid://77877895901792",
["rectangle-circle"]="rbxassetid://100642423153903",
["rectangle-ellipsis"]="rbxassetid://112919953980965",
["rectangle-goggles"]="rbxassetid://98605436666727",
["rectangle-horizontal"]="rbxassetid://90224199814966",
["rectangle-vertical"]="rbxassetid://117277050590967",recycle=
"rbxassetid://140417023381961",
["redo-2"]="rbxassetid://70451039017914",
["redo-dot"]="rbxassetid://94252981719732",redo=
"rbxassetid://116150342119054",
["refresh-ccw-dot"]="rbxassetid://106702246753270",
["refresh-ccw"]="rbxassetid://117913330389477",
["refresh-cw-off"]="rbxassetid://140179498843054",
["refresh-cw"]="rbxassetid://138133190015277",refrigerator=
"rbxassetid://102614042652753",regex=
"rbxassetid://100727200791841",
["remove-formatting"]="rbxassetid://112833162022628",
["repeat-1"]="rbxassetid://130144534857095",
["repeat-2"]="rbxassetid://85927537182704",
["repeat"]="rbxassetid://121886242955173",
["replace-all"]="rbxassetid://127862728198635",replace=
"rbxassetid://128404082279430",
["reply-all"]="rbxassetid://71723137343562",reply=
"rbxassetid://109788633497028",rewind=
"rbxassetid://95205297521988",ribbon=
"rbxassetid://94265331526851",rocket=
"rbxassetid://87412317685854",
["rocking-chair"]="rbxassetid://110420269495360",
["roller-coaster"]="rbxassetid://112426178972099",rose=
"rbxassetid://126336840238769",
["rotate-3d"]="rbxassetid://76300551576392",
["rotate-ccw-key"]="rbxassetid://74976035240976",
["rotate-ccw-square"]="rbxassetid://90515853170424",
["rotate-ccw"]="rbxassetid://110116685948665",
["rotate-cw-square"]="rbxassetid://77095448159303",
["rotate-cw"]="rbxassetid://84183336178654",
["route-off"]="rbxassetid://106350402024079",route=
"rbxassetid://89968303228953",router=
"rbxassetid://102130331994471",
["rows-2"]="rbxassetid://112556185960101",
["rows-3"]="rbxassetid://117215586961375",
["rows-4"]="rbxassetid://125646021959055",rss=
"rbxassetid://131789058984793",
["ruler-dimension-line"]="rbxassetid://70673861371412",ruler=
"rbxassetid://81432445547423",
["russian-ruble"]="rbxassetid://126357936542156",sailboat=
"rbxassetid://87110567187540",salad=
"rbxassetid://128864507821603",sandwich=
"rbxassetid://104573187458917",
["satellite-dish"]="rbxassetid://136742443888305",satellite=
"rbxassetid://134967053164645",
["saudi-riyal"]="rbxassetid://102282769104635",
["save-all"]="rbxassetid://116946975799440",
["save-off"]="rbxassetid://87085435778560",save=
"rbxassetid://126116963775616",
["scale-3d"]="rbxassetid://72414199620352",scale=
"rbxassetid://108203682317477",scaling=
"rbxassetid://122360365318466",
["scan-barcode"]="rbxassetid://96889457154761",
["scan-eye"]="rbxassetid://99244790601968",
["scan-face"]="rbxassetid://109959345069668",
["scan-heart"]="rbxassetid://106280819776142",
["scan-line"]="rbxassetid://126544908146540",
["scan-qr-code"]="rbxassetid://105409149549927",
["scan-search"]="rbxassetid://80009010551347",
["scan-text"]="rbxassetid://73702396787766",scan=
"rbxassetid://123104789658180",school=
"rbxassetid://76351530290068",
["scissors-line-dashed"]="rbxassetid://122237447974173",scissors=
"rbxassetid://118665510911274",
["screen-share-off"]="rbxassetid://107677572669805",
["screen-share"]="rbxassetid://85137895705653",
["scroll-text"]="rbxassetid://97321022666868",scroll=
"rbxassetid://74072101474951",
["search-check"]="rbxassetid://75442076191356",
["search-code"]="rbxassetid://117114794592802",
["search-slash"]="rbxassetid://96483932261041",
["search-x"]="rbxassetid://137319957522951",search=
"rbxassetid://121018724060431",section=
"rbxassetid://91732188298948",
["send-horizontal"]="rbxassetid://111734392411664",
["send-to-back"]="rbxassetid://75340312862253",send=
"rbxassetid://127751956873796",
["separator-horizontal"]="rbxassetid://84864453699927",
["separator-vertical"]="rbxassetid://84031801478581",
["server-cog"]="rbxassetid://138470287250966",
["server-crash"]="rbxassetid://132810618000212",
["server-off"]="rbxassetid://114048751507723",server=
"rbxassetid://92188766517878",
["settings-2"]="rbxassetid://135684703553372",settings=
"rbxassetid://80758916183665",shapes=
"rbxassetid://129989433311409",
["share-2"]="rbxassetid://71210767962065",share=
"rbxassetid://87340985053299",sheet=
"rbxassetid://134902122480171",shell=
"rbxassetid://140212943563599",
["shield-alert"]="rbxassetid://114995877719925",
["shield-ban"]="rbxassetid://108765041044649",
["shield-check"]="rbxassetid://87354736164608",
["shield-ellipsis"]="rbxassetid://114794739892123",
["shield-half"]="rbxassetid://117842634172647",
["shield-minus"]="rbxassetid://89965059528921",
["shield-off"]="rbxassetid://133426959132690",
["shield-plus"]="rbxassetid://100664857995498",
["shield-question-mark"]="rbxassetid://135722075265150",
["shield-user"]="rbxassetid://124832775645347",
["shield-x"]="rbxassetid://73370117343811",shield=
"rbxassetid://110987169760162",
["ship-wheel"]="rbxassetid://130797795829448",ship=
"rbxassetid://83995100553930",shirt=
"rbxassetid://106579555405966",
["shopping-bag"]="rbxassetid://71885477293226",
["shopping-basket"]="rbxassetid://138646411956433",
["shopping-cart"]="rbxassetid://128420521375441",shovel=
"rbxassetid://102465000512056",
["shower-head"]="rbxassetid://75884944024117",shredder=
"rbxassetid://122125164414463",shrimp=
"rbxassetid://102625900815307",shrink=
"rbxassetid://90953687918880",shrub=
"rbxassetid://127326280714343",shuffle=
"rbxassetid://132382786975101",sigma=
"rbxassetid://126884244870899",
["signal-high"]="rbxassetid://130436670012270",
["signal-low"]="rbxassetid://73674683500458",
["signal-medium"]="rbxassetid://125003021367019",
["signal-zero"]="rbxassetid://130045332414754",signal=
"rbxassetid://78424889355261",signature=
"rbxassetid://114402748013000",
["signpost-big"]="rbxassetid://115780185675001",signpost=
"rbxassetid://106584743791433",siren=
"rbxassetid://134210267818039",
["skip-back"]="rbxassetid://70466132711334",
["skip-forward"]="rbxassetid://124844823753990",skull=
"rbxassetid://137726256442333",slack=
"rbxassetid://96089719516736",slash=
"rbxassetid://117792185664263",slice=
"rbxassetid://95810504278179",
["sliders-horizontal"]="rbxassetid://85538382643347",
["sliders-vertical"]="rbxassetid://101190569086853",
["smartphone-charging"]="rbxassetid://102837532613995",
["smartphone-nfc"]="rbxassetid://82326425754446",smartphone=
"rbxassetid://96623008834511",
["smile-plus"]="rbxassetid://131981881472144",smile=
"rbxassetid://105880397565283",snail=
"rbxassetid://70904536548363",snowflake=
"rbxassetid://101235206534566",
["soap-dispenser-droplet"]="rbxassetid://77258480479465",sofa=
"rbxassetid://114427687218324",
["solar-panel"]="rbxassetid://132448188047921",soup=
"rbxassetid://115092551871618",space=
"rbxassetid://87072088914178",spade=
"rbxassetid://131444449466462",sparkle=
"rbxassetid://111044800239623",sparkles=
"rbxassetid://138635884129147",speaker=
"rbxassetid://96227183003618",speech=
"rbxassetid://87013139446349",
["spell-check-2"]="rbxassetid://81556731785534",
["spell-check"]="rbxassetid://91913483031334",
["spline-pointer"]="rbxassetid://84842840956804",spline=
"rbxassetid://129406685807412",split=
"rbxassetid://105112438805988",spool=
"rbxassetid://124541981347743",spotlight=
"rbxassetid://77571742539344",
["spray-can"]="rbxassetid://128372039366326",sprout=
"rbxassetid://100091687832508",
["square-activity"]="rbxassetid://89496630185293",
["square-arrow-down-left"]="rbxassetid://108194680296901",
["square-arrow-down-right"]="rbxassetid://99403846801050",
["square-arrow-down"]="rbxassetid://135962519626588",
["square-arrow-left"]="rbxassetid://111671474549238",
["square-arrow-out-down-left"]="rbxassetid://125714881756353",
["square-arrow-out-down-right"]="rbxassetid://89971003001390",
["square-arrow-out-up-left"]="rbxassetid://103759986579087",
["square-arrow-out-up-right"]="rbxassetid://91221896066807",
["square-arrow-right"]="rbxassetid://113920471701361",
["square-arrow-up-left"]="rbxassetid://112424670290693",
["square-arrow-up-right"]="rbxassetid://76602291406940",
["square-arrow-up"]="rbxassetid://106998604646718",
["square-asterisk"]="rbxassetid://89186832353625",
["square-bottom-dashed-scissors"]="rbxassetid://79076980104803",
["square-chart-gantt"]="rbxassetid://104034017316411",
["square-check-big"]="rbxassetid://115320390907184",
["square-check"]="rbxassetid://134682053539509",
["square-chevron-down"]="rbxassetid://91032307924592",
["square-chevron-left"]="rbxassetid://73143404829510",
["square-chevron-right"]="rbxassetid://90612077729930",
["square-chevron-up"]="rbxassetid://85565910197337",
["square-code"]="rbxassetid://81604576616881",
["square-dashed-bottom-code"]="rbxassetid://100354801563230",
["square-dashed-bottom"]="rbxassetid://101102319625624",
["square-dashed-kanban"]="rbxassetid://90388067649847",
["square-dashed-mouse-pointer"]="rbxassetid://121016142178467",
["square-dashed-top-solid"]="rbxassetid://117157577548540",
["square-dashed"]="rbxassetid://136905537847606",
["square-divide"]="rbxassetid://99894657101970",
["square-dot"]="rbxassetid://116613421354866",
["square-equal"]="rbxassetid://110283363706707",
["square-function"]="rbxassetid://86075219551088",
["square-kanban"]="rbxassetid://114537101260131",
["square-library"]="rbxassetid://73810931222081",
["square-m"]="rbxassetid://117662700410577",
["square-menu"]="rbxassetid://104067089444415",
["square-minus"]="rbxassetid://116764432015770",
["square-mouse-pointer"]="rbxassetid://76141850603920",
["square-parking-off"]="rbxassetid://100857293535141",
["square-parking"]="rbxassetid://133116656122387",
["square-pause"]="rbxassetid://86608552787615",
["square-pen"]="rbxassetid://120239476110475",
["square-percent"]="rbxassetid://87111930314567",
["square-pi"]="rbxassetid://75383328781618",
["square-pilcrow"]="rbxassetid://131854284699367",
["square-play"]="rbxassetid://108186325238481",
["square-plus"]="rbxassetid://114713264461873",
["square-power"]="rbxassetid://129240437805187",
["square-radical"]="rbxassetid://132645931868292",
["square-round-corner"]="rbxassetid://104592745113567",
["square-scissors"]="rbxassetid://110601255612411",
["square-sigma"]="rbxassetid://113231244246816",
["square-slash"]="rbxassetid://105477013908757",
["square-split-horizontal"]="rbxassetid://76095370148660",
["square-split-vertical"]="rbxassetid://88589192032058",
["square-square"]="rbxassetid://136555087357875",
["square-stack"]="rbxassetid://100463396619394",
["square-star"]="rbxassetid://94506958703720",
["square-stop"]="rbxassetid://80018708472943",
["square-terminal"]="rbxassetid://83969264476798",
["square-user-round"]="rbxassetid://86484997229302",
["square-user"]="rbxassetid://70771214183445",
["square-x"]="rbxassetid://125136183850190",square=
"rbxassetid://86304921356806",
["squares-exclude"]="rbxassetid://102345385822324",
["squares-intersect"]="rbxassetid://120869602570119",
["squares-subtract"]="rbxassetid://131484650948795",
["squares-unite"]="rbxassetid://96673080107843",
["squircle-dashed"]="rbxassetid://129936702532522",squircle=
"rbxassetid://82426632573807",squirrel=
"rbxassetid://112864252085343",stamp=
"rbxassetid://92370779813368",
["star-half"]="rbxassetid://117449275562979",
["star-off"]="rbxassetid://75742832732503",star=
"rbxassetid://136141469398409",
["step-back"]="rbxassetid://108672750005121",
["step-forward"]="rbxassetid://126131872136145",stethoscope=
"rbxassetid://122331031702148",sticker=
"rbxassetid://79938203791608",
["sticky-note"]="rbxassetid://111894074643919",store=
"rbxassetid://90338129673705",
["stretch-horizontal"]="rbxassetid://87665042192343",
["stretch-vertical"]="rbxassetid://95265463417122",strikethrough=
"rbxassetid://103417324549613",subscript=
"rbxassetid://74553514785183",
["sun-dim"]="rbxassetid://129141645592715",
["sun-medium"]="rbxassetid://130278807964710",
["sun-moon"]="rbxassetid://75752898854559",
["sun-snow"]="rbxassetid://112791898014579",sun=
"rbxassetid://110150589884127",sunrise=
"rbxassetid://134705665494098",sunset=
"rbxassetid://75904872203588",superscript=
"rbxassetid://96887696590118",
["swatch-book"]="rbxassetid://126786244872453",
["swiss-franc"]="rbxassetid://113497920041625",
["switch-camera"]="rbxassetid://76841154349737",sword=
"rbxassetid://124448418211665",swords=
"rbxassetid://81872698913435",syringe=
"rbxassetid://123891270479254",
["table-2"]="rbxassetid://95751552281545",
["table-cells-merge"]="rbxassetid://95363715175258",
["table-cells-split"]="rbxassetid://114799086088649",
["table-columns-split"]="rbxassetid://111011625447949",
["table-of-contents"]="rbxassetid://135044763275414",
["table-properties"]="rbxassetid://125062886015372",
["table-rows-split"]="rbxassetid://96443733673997",table=
"rbxassetid://109109148250737",
["tablet-smartphone"]="rbxassetid://133680859813404",tablet=
"rbxassetid://128403991264386",tablets=
"rbxassetid://80835787970735",tag=
"rbxassetid://129104970103940",tags=
"rbxassetid://107179263080798",
["tally-1"]="rbxassetid://115301298241643",
["tally-2"]="rbxassetid://110363186864027",
["tally-3"]="rbxassetid://97655344572540",
["tally-4"]="rbxassetid://102633494371890",
["tally-5"]="rbxassetid://88031817475886",tangent=
"rbxassetid://123263132981724",target=
"rbxassetid://87563802520297",telescope=
"rbxassetid://91755049143647",
["tent-tree"]="rbxassetid://76698322463977",tent=
"rbxassetid://109779587826330",terminal=
"rbxassetid://106783148545356",
["test-tube-diagonal"]="rbxassetid://75662704378840",
["test-tube"]="rbxassetid://98801015650164",
["test-tubes"]="rbxassetid://92555361447433",
["text-align-center"]="rbxassetid://84051028246390",
["text-align-end"]="rbxassetid://130041738343555",
["text-align-justify"]="rbxassetid://80279880143030",
["text-align-start"]="rbxassetid://134489585487649",
["text-cursor-input"]="rbxassetid://107551944047171",
["text-cursor"]="rbxassetid://115984654447300",
["text-initial"]="rbxassetid://129458097472087",
["text-quote"]="rbxassetid://139278366448736",
["text-search"]="rbxassetid://92345384671606",
["text-select"]="rbxassetid://117087320884956",
["text-wrap"]="rbxassetid://114804318314018",theater=
"rbxassetid://108558145549163",
["thermometer-snowflake"]="rbxassetid://121876188028425",
["thermometer-sun"]="rbxassetid://106693240074310",thermometer=
"rbxassetid://106546011492311",
["thumbs-down"]="rbxassetid://87794009914015",
["thumbs-up"]="rbxassetid://111137070767020",
["ticket-check"]="rbxassetid://105428777212507",
["ticket-minus"]="rbxassetid://78966299769328",
["ticket-percent"]="rbxassetid://80834774406405",
["ticket-plus"]="rbxassetid://110086734392189",
["ticket-slash"]="rbxassetid://89045681172265",
["ticket-x"]="rbxassetid://88674114109926",ticket=
"rbxassetid://126527071492145",
["tickets-plane"]="rbxassetid://100367018248695",tickets=
"rbxassetid://135268612687833",
["timer-off"]="rbxassetid://110916370767271",
["timer-reset"]="rbxassetid://110052125369932",timer=
"rbxassetid://85473888890506",
["toggle-left"]="rbxassetid://85887872573050",
["toggle-right"]="rbxassetid://90411952142550",toilet=
"rbxassetid://80930782432931",
["tool-case"]="rbxassetid://87533537832522",tornado=
"rbxassetid://88358291515768",torus=
"rbxassetid://70855707283051",
["touchpad-off"]="rbxassetid://78784008075456",touchpad=
"rbxassetid://74882354908014",
["tower-control"]="rbxassetid://95937619060532",
["toy-brick"]="rbxassetid://86293483924633",tractor=
"rbxassetid://103376704722051",
["traffic-cone"]="rbxassetid://74110220470369",
["train-front-tunnel"]="rbxassetid://105194827005114",
["train-front"]="rbxassetid://125237934215370",
["train-track"]="rbxassetid://77451032453723",
["tram-front"]="rbxassetid://93315182364998",transgender=
"rbxassetid://135530817673639",
["trash-2"]="rbxassetid://109843431391323",trash=
"rbxassetid://106723740584310",
["tree-deciduous"]="rbxassetid://123124389219004",
["tree-palm"]="rbxassetid://103846705893963",
["tree-pine"]="rbxassetid://124662547202594",trees=
"rbxassetid://121203841375919",trello=
"rbxassetid://130987241149527",
["trending-down"]="rbxassetid://139309232226438",
["trending-up-down"]="rbxassetid://85083293981691",
["trending-up"]="rbxassetid://81819858538839",
["triangle-alert"]="rbxassetid://125920361880643",
["triangle-dashed"]="rbxassetid://124324079103935",
["triangle-right"]="rbxassetid://116930791412791",triangle=
"rbxassetid://126330486745540",trophy=
"rbxassetid://131545003268773",
["truck-electric"]="rbxassetid://111873446387359",truck=
"rbxassetid://86662707764771",
["turkish-lira"]="rbxassetid://114589876174070",turntable=
"rbxassetid://129870346487856",turtle=
"rbxassetid://118295081560334",
["tv-minimal-play"]="rbxassetid://99201833426972",
["tv-minimal"]="rbxassetid://100382201729427",tv=
"rbxassetid://135687724791776",twitch=
"rbxassetid://71383308134888",twitter=
"rbxassetid://88791703276842",
["type-outline"]="rbxassetid://80108627791690",type=
"rbxassetid://133543553793564",
["umbrella-off"]="rbxassetid://72395143739955",umbrella=
"rbxassetid://127502210274589",underline=
"rbxassetid://123709229216544",
["undo-2"]="rbxassetid://113885292059932",
["undo-dot"]="rbxassetid://132055277744844",undo=
"rbxassetid://111258459077271",
["unfold-horizontal"]="rbxassetid://117128358526398",
["unfold-vertical"]="rbxassetid://116593025265499",ungroup=
"rbxassetid://106674800451003",university=
"rbxassetid://84652528263642",
["unlink-2"]="rbxassetid://128131898892572",unlink=
"rbxassetid://139835795227752",unplug=
"rbxassetid://90171381619874",upload=
"rbxassetid://138212042425501",usb=
"rbxassetid://117230058949613",
["user-check"]="rbxassetid://81775205032725",
["user-cog"]="rbxassetid://92795491530865",
["user-lock"]="rbxassetid://78892639693821",
["user-minus"]="rbxassetid://126976941957511",
["user-pen"]="rbxassetid://87445472574836",
["user-plus"]="rbxassetid://118514469915884",
["user-round-check"]="rbxassetid://118794737621941",
["user-round-cog"]="rbxassetid://78239503290053",
["user-round-minus"]="rbxassetid://98944176636447",
["user-round-pen"]="rbxassetid://108155244324878",
["user-round-plus"]="rbxassetid://113301899567470",
["user-round-search"]="rbxassetid://71565774381870",
["user-round-x"]="rbxassetid://122367980560930",
["user-round"]="rbxassetid://136485052187963",
["user-search"]="rbxassetid://101335649828115",
["user-star"]="rbxassetid://98777846316000",
["user-x"]="rbxassetid://139748155894754",user=
"rbxassetid://81589895647169",
["users-round"]="rbxassetid://103005444008339",users=
"rbxassetid://115398113982385",
["utensils-crossed"]="rbxassetid://109520762270383",utensils=
"rbxassetid://139952569804235",
["utility-pole"]="rbxassetid://101965541238242",variable=
"rbxassetid://104743088438151",vault=
"rbxassetid://108049164599845",
["vector-square"]="rbxassetid://86713728565344",vegan=
"rbxassetid://119489190688082",
["venetian-mask"]="rbxassetid://102636443033920",
["venus-and-mars"]="rbxassetid://120227752103771",venus=
"rbxassetid://82891342220859",
["vibrate-off"]="rbxassetid://113446447326246",vibrate=
"rbxassetid://108330910738733",
["video-off"]="rbxassetid://132239189859305",video=
"rbxassetid://107587444636945",videotape=
"rbxassetid://114816894323398",view=
"rbxassetid://118717253976805",voicemail=
"rbxassetid://134313454010227",volleyball=
"rbxassetid://83889351124153",
["volume-1"]="rbxassetid://98514588731639",
["volume-2"]="rbxassetid://89344380902620",
["volume-off"]="rbxassetid://103047478058767",
["volume-x"]="rbxassetid://139252359189540",volume=
"rbxassetid://103236289817396",vote=
"rbxassetid://89409762851246",
["wallet-cards"]="rbxassetid://129728715308337",
["wallet-minimal"]="rbxassetid://137800448816116",wallet=
"rbxassetid://132331555762628",Wallpaper=
"rbxassetid://74682121235494",
["wand-sparkles"]="rbxassetid://82546429942392",wand=
"rbxassetid://114580617777835",warehouse=
"rbxassetid://78388887451080",
["washing-machine"]="rbxassetid://104194127573858",watch=
"rbxassetid://130544621618405",
["waves-ladder"]="rbxassetid://101808619355514",waves=
"rbxassetid://96340135183647",waypoints=
"rbxassetid://102450133666017",webcam=
"rbxassetid://104148487911129",
["webhook-off"]="rbxassetid://96370548093471",webhook=
"rbxassetid://112812457747322",weight=
"rbxassetid://103860559844854",
["wheat-off"]="rbxassetid://133294844612307",wheat=
"rbxassetid://85261952080359",
["whole-word"]="rbxassetid://90111083954485",
["wifi-cog"]="rbxassetid://110500263326209",
["wifi-high"]="rbxassetid://81954601342139",
["wifi-low"]="rbxassetid://138217335635913",
["wifi-off"]="rbxassetid://74113634330106",
["wifi-pen"]="rbxassetid://91290205064712",
["wifi-sync"]="rbxassetid://84043971055177",
["wifi-zero"]="rbxassetid://124286465246123",wifi=
"rbxassetid://104669375183960",
["wind-arrow-down"]="rbxassetid://127753987414870",wind=
"rbxassetid://114551690399915",
["wine-off"]="rbxassetid://108294164302317",wine=
"rbxassetid://115743721332829",workflow=
"rbxassetid://99186544029189",worm=
"rbxassetid://115752311548091",wrench=
"rbxassetid://112148279212860",x=
"rbxassetid://110786993356448",youtube=
"rbxassetid://123663668456341",
["zap-off"]="rbxassetid://81385483183652",zap=
"rbxassetid://130551565616516",
["zoom-in"]="rbxassetid://127956924984803",
["zoom-out"]="rbxassetid://108334162607319",balloon=
"rbxassetid://97489111621526",
["beef-off"]="rbxassetid://99869959725200",
["book-search"]="rbxassetid://132585409504950",calendars=
"rbxassetid://130944763042289",
["cannabis-off"]="rbxassetid://101938500363812",
["cctv-off"]="rbxassetid://75925370187295",cigarette=
"rbxassetid://137149549886852",
["circle-pile"]="rbxassetid://116353155251541",
["cloud-backup"]="rbxassetid://111649579696132",
["cloud-sync"]="rbxassetid://79393911188593",
["database-search"]="rbxassetid://92017137080138",ellipse=
"rbxassetid://71559658267482",
["fingerprint-pattern"]="rbxassetid://80934710831288",
["fishing-hook"]="rbxassetid://121038780855899",
["fishing-rod"]="rbxassetid://71754848048049",form=
"rbxassetid://72999643971000",
["git-merge-conflict"]="rbxassetid://85677801675703",
["globe-off"]="rbxassetid://77775243585824",
["globe-x"]="rbxassetid://109268097029296",hd=
"rbxassetid://71682790698278",image=
"rbxassetid://112751259236831",
["layers-plus"]="rbxassetid://77587765623057",
["lens-concave"]="rbxassetid://94819631937027",
["lens-convex"]="rbxassetid://74736504195474",
["line-dot-right-horizontal"]="rbxassetid://104718593155221",
["line-style"]="rbxassetid://90176717785772",
["map-pin-search"]="rbxassetid://89065012915078",
["message-circle-check"]="rbxassetid://132772297689418",
["message-square-check"]="rbxassetid://125789987055668",metronome=
"rbxassetid://101991829345965",
["mirror-rectangular"]="rbxassetid://109046769760336",
["mirror-round"]="rbxassetid://121534049429097",
["mouse-left"]="rbxassetid://99144293708743",
["mouse-right"]="rbxassetid://88331710212594",
["printer-x"]="rbxassetid://103002721801548",
["radio-off"]="rbxassetid://80359258046586",road=
"rbxassetid://120251329173530",scooter=
"rbxassetid://100035452787934",
["search-alert"]="rbxassetid://127597984617505",
["shelving-unit"]="rbxassetid://80116568514793",
["shield-cog-corner"]="rbxassetid://111694066132698",
["shield-cog"]="rbxassetid://129235695057857",
["sport-shoe"]="rbxassetid://120495992692630",
["square-arrow-right-enter"]="rbxassetid://138867831495334",
["square-arrow-right-exit"]="rbxassetid://133688575845430",
["square-centerline-dashed-horizontal"]="rbxassetid://77780104374341",
["square-centerline-dashed-vertical"]="rbxassetid://107878435803525",stone=
"rbxassetid://135161057497830",toolbox=
"rbxassetid://85341033903792",
["towel-rack"]="rbxassetid://125223915620991",
["user-key"]="rbxassetid://105403041782190",
["user-round-key"]="rbxassetid://124547549008939",van=
"rbxassetid://122066377022942",
["waves-arrow-down"]="rbxassetid://129215220911792",
["waves-arrow-up"]="rbxassetid://102314705716217",
["weight-tilde"]="rbxassetid://112081212176951",
["x-line-top"]="rbxassetid://140592656289509",
["zodiac-aquarius"]="rbxassetid://74560047770362",
["zodiac-aries"]="rbxassetid://73255859670234",
["zodiac-cancer"]="rbxassetid://131985162532947",
["zodiac-capricorn"]="rbxassetid://97859568140652",
["zodiac-gemini"]="rbxassetid://80997588122992",
["zodiac-leo"]="rbxassetid://75509406718106",
["zodiac-libra"]="rbxassetid://113222735060218",
["zodiac-ophiuchus"]="rbxassetid://129180108892480",
["zodiac-pisces"]="rbxassetid://95845819440327",
["zodiac-sagittarius"]="rbxassetid://82651026742181",
["zodiac-scorpio"]="rbxassetid://113640924054631",
["zodiac-taurus"]="rbxassetid://123053219704400",
["zodiac-virgo"]="rbxassetid://99462994613661",
}end function a.c():typeof(__modImpl())local b=a.cache.c if not b then b={c=__modImpl()}a.cache.c=b end return b.c end end do local function __modImpl()
























































































local b={}





b.Default={

WindowColor=Color3.fromRGB(15,15,16),
WindowTransparency=0.1,
WindowControlColor=Color3.fromRGB(255,255,255),
ContentBackgroundColor=Color3.fromRGB(15,15,16),
ContentBackgroundTransparency=1,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(20,20,20),
SidebarTransparency=1,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0.985,
InputBackgroundColor=Color3.fromRGB(26,26,28),
InputBackgroundTransparency=1,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(255,255,255),
StrokeTransparency=0.95,
PrimaryColor=Color3.fromRGB(13,44,177),
SecondaryColor=Color3.fromRGB(13,44,177),
TertiaryColor=Color3.fromRGB(150,150,150),
Undercolor=Color3.fromRGB(30,30,30),
AccentColor=Color3.fromRGB(14,45,178),


PrimaryTextColor=Color3.fromRGB(255,255,255),
PrimaryTextTransparency=0.1,
SecondaryTextColor=Color3.fromRGB(200,200,200),
SecondaryTextTransparency=0.4,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(200,200,200),
InactiveTabIconColor=Color3.fromRGB(200,200,200),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0.2,
InactiveTabTextTransparency=0.5,
ActiveTabIconTransparency=0.2,
InactiveTabIconTransparency=0.5,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0.99,
InactiveTabButtonColor=Color3.fromRGB(255,255,255),
InactiveTabButtonTransparency=1,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0.98,
SectionStrokeTransparency=0.95,
SectionDividerColor=Color3.fromRGB(255,255,255),
SectionDividerTransparency=0.9,
SearchBarBackgroundColor=Color3.fromRGB(26,30,255),
SearchBarBackgroundTransparency=1,


PopupBackgroundColor=Color3.fromRGB(15,15,16),
PopupBackgroundTransparency=0.07,
PopupNeutralColor=Color3.fromRGB(46,46,46),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(255,255,255),
PopupTextTransparency=0.2,


NotificationBackgroundColor=Color3.fromRGB(30,41,59),
NotificationBackgroundTransparency=0.1,
NotificationShadowColor=Color3.fromRGB(0,0,0),
NotificationHeaderColor=Color3.fromRGB(255,255,255),
NotificationHeaderTransparency=0.2,
NotificationTextColor=Color3.fromRGB(226,232,240),
NotificationTextTransparency=0.4,
NotificationDividerColor=Color3.fromRGB(148,163,184),
NotificationDividerTransparency=0.7,
NotificationDismissColor=Color3.fromRGB(203,213,225),
NotificationActionButtonColor=Color3.fromRGB(51,65,85),
NotificationActionButtonTextColor=Color3.fromRGB(241,245,249),
NotificationAlertAccent=Color3.fromRGB(219,153,10),
NotificationErrorAccent=Color3.fromRGB(220,70,60),
NotificationVariableAccent=Color3.fromRGB(74,200,120),


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Black={

WindowColor=Color3.fromRGB(3,3,4),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(3,3,4),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(9,9,11),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(9,9,11),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(24,24,27),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(39,39,42),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(59,130,246),
SecondaryColor=Color3.fromRGB(63,63,70),
TertiaryColor=Color3.fromRGB(113,113,122),
Undercolor=Color3.fromRGB(39,39,42),
AccentColor=Color3.fromRGB(96,165,250),


PrimaryTextColor=Color3.fromRGB(250,250,250),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(161,161,170),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(161,161,170),
InactiveTabIconColor=Color3.fromRGB(161,161,170),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(59,130,246),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(9,9,11),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(9,9,11),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(39,39,42),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(24,24,27),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(9,9,11),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(24,24,27),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(250,250,250),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}




b.Light={

WindowColor=Color3.fromRGB(241,245,249),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(241,245,249),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(148,163,184),


SidebarColor=Color3.fromRGB(248,250,252),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(248,250,252),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(203,213,225),
StrokeColor=Color3.fromRGB(203,213,225),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(37,99,235),
SecondaryColor=Color3.fromRGB(148,163,184),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(226,232,240),
AccentColor=Color3.fromRGB(37,99,235),


PrimaryTextColor=Color3.fromRGB(15,23,42),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(71,85,105),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(15,23,42),
InactiveTabTextColor=Color3.fromRGB(100,116,139),
InactiveTabIconColor=Color3.fromRGB(100,116,139),
ActiveTabTextColor=Color3.fromRGB(15,23,42),
ActiveTabIconColor=Color3.fromRGB(15,23,42),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(248,250,252),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(226,232,240),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(241,245,249),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(241,245,249),
PopupShadowColor=Color3.fromRGB(148,163,184),
PopupTextColor=Color3.fromRGB(15,23,42),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Midnight={

WindowColor=Color3.fromRGB(17,17,27),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(17,17,27),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(27,27,41),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(27,27,41),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(39,39,58),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(55,55,78),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(129,140,248),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(113,113,122),
Undercolor=Color3.fromRGB(55,55,78),
AccentColor=Color3.fromRGB(167,139,250),


PrimaryTextColor=Color3.fromRGB(238,238,245),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(161,161,178),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(161,161,178),
InactiveTabIconColor=Color3.fromRGB(161,161,178),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(129,140,248),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(27,27,41),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(27,27,41),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(55,55,78),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(39,39,58),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(27,27,41),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(39,39,58),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(238,238,245),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Graphite={

WindowColor=Color3.fromRGB(24,26,30),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(24,26,30),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(33,36,41),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(33,36,41),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(45,49,56),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(55,61,69),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(45,212,191),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(113,122,135),
Undercolor=Color3.fromRGB(55,61,69),
AccentColor=Color3.fromRGB(56,189,248),


PrimaryTextColor=Color3.fromRGB(229,231,235),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(156,163,175),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(156,163,175),
InactiveTabIconColor=Color3.fromRGB(156,163,175),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(45,212,191),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(33,36,41),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(33,36,41),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(55,61,69),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(45,49,56),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(33,36,41),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(45,49,56),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(229,231,235),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Pearl={

WindowColor=Color3.fromRGB(250,249,247),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(250,249,247),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(180,170,160),


SidebarColor=Color3.fromRGB(245,243,240),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(246,244,241),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(214,211,209),
StrokeColor=Color3.fromRGB(231,229,228),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(99,102,241),
SecondaryColor=Color3.fromRGB(168,162,158),
TertiaryColor=Color3.fromRGB(120,113,108),
Undercolor=Color3.fromRGB(231,229,228),
AccentColor=Color3.fromRGB(124,58,237),


PrimaryTextColor=Color3.fromRGB(28,25,23),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(87,83,78),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(28,25,23),
InactiveTabTextColor=Color3.fromRGB(120,113,108),
InactiveTabIconColor=Color3.fromRGB(120,113,108),
ActiveTabTextColor=Color3.fromRGB(28,25,23),
ActiveTabIconColor=Color3.fromRGB(28,25,23),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(245,243,240),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(231,229,228),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(246,244,241),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(245,243,240),
PopupShadowColor=Color3.fromRGB(180,170,160),
PopupTextColor=Color3.fromRGB(28,25,23),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Slate={

WindowColor=Color3.fromRGB(248,250,252),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(248,250,252),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(148,163,184),


SidebarColor=Color3.fromRGB(241,245,249),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(241,245,249),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(203,213,225),
StrokeColor=Color3.fromRGB(226,232,240),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(16,185,129),
SecondaryColor=Color3.fromRGB(148,163,184),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(226,232,240),
AccentColor=Color3.fromRGB(20,184,166),


PrimaryTextColor=Color3.fromRGB(15,23,42),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(71,85,105),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(15,23,42),
InactiveTabTextColor=Color3.fromRGB(100,116,139),
InactiveTabIconColor=Color3.fromRGB(100,116,139),
ActiveTabTextColor=Color3.fromRGB(15,23,42),
ActiveTabIconColor=Color3.fromRGB(15,23,42),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(241,245,249),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(226,232,240),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(241,245,249),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(241,245,249),
PopupShadowColor=Color3.fromRGB(148,163,184),
PopupTextColor=Color3.fromRGB(15,23,42),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Ocean={

WindowColor=Color3.fromRGB(8,15,26),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(8,15,26),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(15,25,41),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(15,25,41),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(26,40,61),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(35,53,79),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(56,189,248),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(35,53,79),
AccentColor=Color3.fromRGB(34,211,238),


PrimaryTextColor=Color3.fromRGB(226,240,253),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(148,173,199),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(148,173,199),
InactiveTabIconColor=Color3.fromRGB(148,173,199),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(56,189,248),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(15,25,41),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(15,25,41),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(35,53,79),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(26,40,61),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(15,25,41),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(26,40,61),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(226,240,253),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Nord={

WindowColor=Color3.fromRGB(46,52,64),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(46,52,64),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(59,66,82),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(59,66,82),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(67,76,94),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(76,86,106),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(136,192,208),
SecondaryColor=Color3.fromRGB(76,86,106),
TertiaryColor=Color3.fromRGB(129,161,193),
Undercolor=Color3.fromRGB(67,76,94),
AccentColor=Color3.fromRGB(94,129,172),


PrimaryTextColor=Color3.fromRGB(236,239,244),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(180,190,205),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(236,239,244),
InactiveTabTextColor=Color3.fromRGB(180,190,205),
InactiveTabIconColor=Color3.fromRGB(180,190,205),
ActiveTabTextColor=Color3.fromRGB(236,239,244),
ActiveTabIconColor=Color3.fromRGB(236,239,244),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(136,192,208),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(59,66,82),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(59,66,82),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(76,86,106),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(67,76,94),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(59,66,82),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(67,76,94),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(236,239,244),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Forest={

WindowColor=Color3.fromRGB(11,20,16),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(11,20,16),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(18,31,26),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(18,31,26),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(28,45,38),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(37,58,49),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(52,211,153),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(107,128,120),
Undercolor=Color3.fromRGB(37,58,49),
AccentColor=Color3.fromRGB(163,230,53),


PrimaryTextColor=Color3.fromRGB(226,245,236),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(148,173,162),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(148,173,162),
InactiveTabIconColor=Color3.fromRGB(148,173,162),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(52,211,153),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(18,31,26),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(18,31,26),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(37,58,49),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(28,45,38),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(18,31,26),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(28,45,38),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(226,245,236),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Rose={

WindowColor=Color3.fromRGB(24,15,22),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(24,15,22),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(38,24,35),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(38,24,35),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(55,36,51),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(68,45,63),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(244,114,182),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(130,108,122),
Undercolor=Color3.fromRGB(68,45,63),
AccentColor=Color3.fromRGB(217,70,239),


PrimaryTextColor=Color3.fromRGB(250,240,246),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(178,156,171),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(178,156,171),
InactiveTabIconColor=Color3.fromRGB(178,156,171),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(244,114,182),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(38,24,35),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(38,24,35),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(68,45,63),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(55,36,51),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(38,24,35),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(55,36,51),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(250,240,246),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Amethyst={

WindowColor=Color3.fromRGB(20,16,32),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(20,16,32),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(31,26,48),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(31,26,48),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(44,38,66),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(57,49,84),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(167,139,250),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(126,122,148),
Undercolor=Color3.fromRGB(57,49,84),
AccentColor=Color3.fromRGB(232,121,249),


PrimaryTextColor=Color3.fromRGB(240,238,250),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(165,160,190),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(165,160,190),
InactiveTabIconColor=Color3.fromRGB(165,160,190),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(167,139,250),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(31,26,48),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(31,26,48),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(57,49,84),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(44,38,66),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(31,26,48),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(44,38,66),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(240,238,250),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Retro={

WindowColor=Color3.fromRGB(240,230,211),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(240,230,211),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(150,120,90),


SidebarColor=Color3.fromRGB(232,220,198),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(250,243,228),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(232,220,198),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(201,178,145),
StrokeColor=Color3.fromRGB(214,190,156),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(217,119,6),
SecondaryColor=Color3.fromRGB(168,152,128),
TertiaryColor=Color3.fromRGB(146,116,84),
Undercolor=Color3.fromRGB(224,208,180),
AccentColor=Color3.fromRGB(15,118,110),


PrimaryTextColor=Color3.fromRGB(60,42,26),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(120,96,70),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(60,42,26),
InactiveTabTextColor=Color3.fromRGB(146,116,84),
InactiveTabIconColor=Color3.fromRGB(146,116,84),
ActiveTabTextColor=Color3.fromRGB(60,42,26),
ActiveTabIconColor=Color3.fromRGB(60,42,26),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(250,243,228),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(232,220,198),
InactiveTabButtonTransparency=0,


SectionBackgroundColor=Color3.fromRGB(250,243,228),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(214,190,156),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(232,220,198),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(250,243,228),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(232,220,198),
PopupShadowColor=Color3.fromRGB(150,120,90),
PopupTextColor=Color3.fromRGB(60,42,26),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}




b.Glass={

WindowColor=Color3.fromRGB(20,24,33),
WindowTransparency=0.35,
ContentBackgroundColor=Color3.fromRGB(20,24,33),
ContentBackgroundTransparency=0.15,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(28,33,45),
SidebarTransparency=0.45,


ComponentBackgroundColor=Color3.fromRGB(38,45,60),
ComponentBackgroundTransparency=0.25,
InputBackgroundColor=Color3.fromRGB(48,56,74),
InputBackgroundTransparency=0.2,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(120,140,170),
StrokeTransparency=0.6,
PrimaryColor=Color3.fromRGB(96,165,250),
SecondaryColor=Color3.fromRGB(100,116,139),
TertiaryColor=Color3.fromRGB(148,163,184),
Undercolor=Color3.fromRGB(71,85,105),
AccentColor=Color3.fromRGB(56,189,248),


PrimaryTextColor=Color3.fromRGB(241,245,249),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(203,213,225),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(203,213,225),
InactiveTabIconColor=Color3.fromRGB(203,213,225),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(96,165,250),
ActiveTabButtonTransparency=0.1,
InactiveTabButtonColor=Color3.fromRGB(28,33,45),
InactiveTabButtonTransparency=0.6,


SectionBackgroundColor=Color3.fromRGB(38,45,60),
SectionBackgroundTransparency=0.35,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(100,116,139),
SectionDividerTransparency=0.4,
SearchBarBackgroundColor=Color3.fromRGB(48,56,74),
SearchBarBackgroundTransparency=0.2,


PopupBackgroundColor=Color3.fromRGB(28,33,45),
PopupBackgroundTransparency=0.05,
PopupNeutralColor=Color3.fromRGB(48,56,74),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(241,245,249),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}



b.Porcelain={

WindowColor=Color3.fromRGB(245,247,250),
WindowTransparency=0.2,
ContentBackgroundColor=Color3.fromRGB(255,255,255),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(148,163,184),


SidebarColor=Color3.fromRGB(226,232,240),
SidebarTransparency=0.5,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(248,250,252),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(203,213,225),
StrokeColor=Color3.fromRGB(203,213,225),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(14,165,233),
SecondaryColor=Color3.fromRGB(148,163,184),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(226,232,240),
AccentColor=Color3.fromRGB(14,165,233),


PrimaryTextColor=Color3.fromRGB(15,23,42),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(71,85,105),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(15,23,42),
InactiveTabTextColor=Color3.fromRGB(100,116,139),
InactiveTabIconColor=Color3.fromRGB(100,116,139),
ActiveTabTextColor=Color3.fromRGB(15,23,42),
ActiveTabIconColor=Color3.fromRGB(15,23,42),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(226,232,240),
InactiveTabButtonTransparency=0.4,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(226,232,240),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(248,250,252),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(241,245,249),
PopupShadowColor=Color3.fromRGB(148,163,184),
PopupTextColor=Color3.fromRGB(15,23,42),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Mist={

WindowColor=Color3.fromRGB(226,232,240),
WindowTransparency=0.35,
ContentBackgroundColor=Color3.fromRGB(255,255,255),
ContentBackgroundTransparency=0,
WindowControlColor=Color3.fromRGB(71,85,105),
MainframeShadowColor=Color3.fromRGB(148,163,184),


SidebarColor=Color3.fromRGB(203,213,225),
SidebarTransparency=0.5,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(248,250,252),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(203,213,225),
StrokeColor=Color3.fromRGB(203,213,225),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(99,102,241),
SecondaryColor=Color3.fromRGB(148,163,184),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(226,232,240),
AccentColor=Color3.fromRGB(14,165,233),


PrimaryTextColor=Color3.fromRGB(15,23,42),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(71,85,105),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(15,23,42),
InactiveTabTextColor=Color3.fromRGB(100,116,139),
InactiveTabIconColor=Color3.fromRGB(100,116,139),
ActiveTabTextColor=Color3.fromRGB(15,23,42),
ActiveTabIconColor=Color3.fromRGB(15,23,42),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(226,232,240),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(226,232,240),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(248,250,252),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(241,245,249),
PopupShadowColor=Color3.fromRGB(148,163,184),
PopupTextColor=Color3.fromRGB(15,23,42),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Dusk={

WindowColor=Color3.fromRGB(30,22,38),
WindowTransparency=0.3,
ContentBackgroundColor=Color3.fromRGB(26,19,34),
ContentBackgroundTransparency=0,
WindowControlColor=Color3.fromRGB(196,181,212),
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(44,33,55),
SidebarTransparency=0.45,


ComponentBackgroundColor=Color3.fromRGB(38,28,48),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(52,39,65),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(70,54,88),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(192,132,252),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(148,138,168),
Undercolor=Color3.fromRGB(70,54,88),
AccentColor=Color3.fromRGB(244,114,182),


PrimaryTextColor=Color3.fromRGB(245,240,250),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(190,176,205),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(190,176,205),
InactiveTabIconColor=Color3.fromRGB(190,176,205),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(192,132,252),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(44,33,55),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(38,28,48),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(70,54,88),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(52,39,65),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(38,28,48),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(52,39,65),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(245,240,250),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Frost={

WindowColor=Color3.fromRGB(24,32,44),
WindowTransparency=0.3,
ContentBackgroundColor=Color3.fromRGB(20,27,38),
ContentBackgroundTransparency=0,
WindowControlColor=Color3.fromRGB(148,190,220),
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(37,49,66),
SidebarTransparency=0.45,


ComponentBackgroundColor=Color3.fromRGB(30,40,54),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(43,56,74),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(56,72,94),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(125,211,252),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(148,163,184),
Undercolor=Color3.fromRGB(56,72,94),
AccentColor=Color3.fromRGB(45,212,191),


PrimaryTextColor=Color3.fromRGB(226,240,253),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(160,180,200),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(160,180,200),
InactiveTabIconColor=Color3.fromRGB(160,180,200),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(125,211,252),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(37,49,66),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(30,40,54),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(56,72,94),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(43,56,74),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(30,40,54),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(43,56,74),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(226,240,253),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Sandstone={

WindowColor=Color3.fromRGB(233,224,209),
WindowTransparency=0.3,
ContentBackgroundColor=Color3.fromRGB(252,248,240),
ContentBackgroundTransparency=0,
WindowControlColor=Color3.fromRGB(120,96,70),
MainframeShadowColor=Color3.fromRGB(180,170,160),


SidebarColor=Color3.fromRGB(216,202,180),
SidebarTransparency=0.45,


ComponentBackgroundColor=Color3.fromRGB(255,252,246),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(246,240,230),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(214,205,190),
StrokeColor=Color3.fromRGB(224,214,196),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(180,83,9),
SecondaryColor=Color3.fromRGB(168,162,158),
TertiaryColor=Color3.fromRGB(146,116,84),
Undercolor=Color3.fromRGB(228,220,205),
AccentColor=Color3.fromRGB(15,118,110),


PrimaryTextColor=Color3.fromRGB(60,42,26),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(120,96,70),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(60,42,26),
InactiveTabTextColor=Color3.fromRGB(146,116,84),
InactiveTabIconColor=Color3.fromRGB(146,116,84),
ActiveTabTextColor=Color3.fromRGB(60,42,26),
ActiveTabIconColor=Color3.fromRGB(60,42,26),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,252,246),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(216,202,180),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(255,252,246),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(224,214,196),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(246,240,230),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,252,246),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(246,240,230),
PopupShadowColor=Color3.fromRGB(180,170,160),
PopupTextColor=Color3.fromRGB(60,42,26),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Azure={

WindowColor=Color3.fromRGB(10,18,30),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(15,24,40),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(17,27,45),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(20,31,50),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(30,44,68),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(40,58,86),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(56,189,248),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(40,58,86),
AccentColor=Color3.fromRGB(96,165,250),


PrimaryTextColor=Color3.fromRGB(226,240,253),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(148,173,199),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(148,173,199),
InactiveTabIconColor=Color3.fromRGB(148,173,199),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(56,189,248),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(17,27,45),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(20,31,50),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(40,58,86),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(30,44,68),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(20,31,50),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(30,44,68),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(226,240,253),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Blossom={

WindowColor=Color3.fromRGB(253,245,249),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(255,250,253),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(214,170,190),


SidebarColor=Color3.fromRGB(248,233,241),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(251,242,247),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(219,196,208),
StrokeColor=Color3.fromRGB(238,222,231),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(236,72,153),
SecondaryColor=Color3.fromRGB(168,162,158),
TertiaryColor=Color3.fromRGB(150,110,128),
Undercolor=Color3.fromRGB(238,222,231),
AccentColor=Color3.fromRGB(219,39,119),


PrimaryTextColor=Color3.fromRGB(60,30,45),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(130,90,110),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(60,30,45),
InactiveTabTextColor=Color3.fromRGB(150,110,128),
InactiveTabIconColor=Color3.fromRGB(150,110,128),
ActiveTabTextColor=Color3.fromRGB(60,30,45),
ActiveTabIconColor=Color3.fromRGB(60,30,45),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(248,233,241),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(238,222,231),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(251,242,247),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(251,242,247),
PopupShadowColor=Color3.fromRGB(214,170,190),
PopupTextColor=Color3.fromRGB(60,30,45),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Fjord={

WindowColor=Color3.fromRGB(26,32,44),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(32,40,54),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(0,0,0),


SidebarColor=Color3.fromRGB(36,44,58),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(36,44,58),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(48,58,74),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(0,0,0),
StrokeColor=Color3.fromRGB(58,70,88),
StrokeTransparency=0.4,
PrimaryColor=Color3.fromRGB(125,211,252),
SecondaryColor=Color3.fromRGB(71,85,105),
TertiaryColor=Color3.fromRGB(130,145,165),
Undercolor=Color3.fromRGB(58,70,88),
AccentColor=Color3.fromRGB(56,189,248),


PrimaryTextColor=Color3.fromRGB(226,236,248),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(160,175,195),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(255,255,255),
InactiveTabTextColor=Color3.fromRGB(160,175,195),
InactiveTabIconColor=Color3.fromRGB(160,175,195),
ActiveTabTextColor=Color3.fromRGB(255,255,255),
ActiveTabIconColor=Color3.fromRGB(255,255,255),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.3,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(125,211,252),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(36,44,58),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(36,44,58),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(58,70,88),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(48,58,74),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(36,44,58),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(48,58,74),
PopupShadowColor=Color3.fromRGB(0,0,0),
PopupTextColor=Color3.fromRGB(226,236,248),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}


b.Summit={

WindowColor=Color3.fromRGB(240,246,252),
WindowTransparency=0,
ContentBackgroundColor=Color3.fromRGB(255,255,255),
ContentBackgroundTransparency=0,
MainframeShadowColor=Color3.fromRGB(148,163,184),


SidebarColor=Color3.fromRGB(226,236,248),
SidebarTransparency=0,


ComponentBackgroundColor=Color3.fromRGB(255,255,255),
ComponentBackgroundTransparency=0,
InputBackgroundColor=Color3.fromRGB(240,246,252),
InputBackgroundTransparency=0,
ComponentShadowColor=Color3.fromRGB(203,213,225),
StrokeColor=Color3.fromRGB(214,226,240),
StrokeTransparency=0,
PrimaryColor=Color3.fromRGB(59,130,246),
SecondaryColor=Color3.fromRGB(148,163,184),
TertiaryColor=Color3.fromRGB(100,116,139),
Undercolor=Color3.fromRGB(226,236,248),
AccentColor=Color3.fromRGB(14,165,233),


PrimaryTextColor=Color3.fromRGB(15,30,50),
PrimaryTextTransparency=0,
SecondaryTextColor=Color3.fromRGB(71,90,115),
SecondaryTextTransparency=0,
TitleTextColor=Color3.fromRGB(15,30,50),
InactiveTabTextColor=Color3.fromRGB(100,116,139),
InactiveTabIconColor=Color3.fromRGB(100,116,139),
ActiveTabTextColor=Color3.fromRGB(15,30,50),
ActiveTabIconColor=Color3.fromRGB(15,30,50),
ActiveTabTextTransparency=0,
InactiveTabTextTransparency=0.2,
ActiveTabIconTransparency=0,
InactiveTabIconTransparency=0.3,
ActiveTabButtonColor=Color3.fromRGB(255,255,255),
ActiveTabButtonTransparency=0,
InactiveTabButtonColor=Color3.fromRGB(226,236,248),
InactiveTabButtonTransparency=0.35,


SectionBackgroundColor=Color3.fromRGB(255,255,255),
SectionBackgroundTransparency=0,
SectionStrokeTransparency=0.985,
SectionDividerColor=Color3.fromRGB(214,226,240),
SectionDividerTransparency=0,
SearchBarBackgroundColor=Color3.fromRGB(240,246,252),
SearchBarBackgroundTransparency=0,


PopupBackgroundColor=Color3.fromRGB(255,255,255),
PopupBackgroundTransparency=0,
PopupNeutralColor=Color3.fromRGB(240,246,252),
PopupShadowColor=Color3.fromRGB(148,163,184),
PopupTextColor=Color3.fromRGB(15,30,50),
PopupTextTransparency=0,


Wallpaper=nil,
WallpaperEnabled=true,
}



local c={
Default="rbxassetid://11094025229",
Black="rbxassetid://18571374017",
Light="rbxassetid://5164282825",
Midnight="rbxassetid://107868116663356",
Graphite="rbxassetid://116321051235221",
Pearl="rbxassetid://117100465436400",
Slate="rbxassetid://121017686291110",
Ocean="rbxassetid://135568871834704",
Nord="rbxassetid://121017686291110",
Forest="rbxassetid://116321051235221",
Rose="rbxassetid://8350591200",
Amethyst="rbxassetid://107868116663356",
Retro="rbxassetid://12868775918",
Glass="rbxassetid://15955473206",
Porcelain="rbxassetid://121017686291110",
Mist="rbxassetid://309321999",
Dusk="rbxassetid://123519222162021",
Frost="rbxassetid://84403490778114",
Sandstone="rbxassetid://123519222162021",
Azure="rbxassetid://121017686291110",
Blossom="rbxassetid://131979800493713",
Fjord="rbxassetid://98228102412425",
Summit="rbxassetid://123969479560901",
}

for d,e in pairs(c)do
if b[d]then
b[d].Wallpaper=e
end
end



local d={
Default=Color3.fromRGB(255,255,255),
Black=Color3.fromRGB(161,161,170),
Light=Color3.fromRGB(51,65,85),
Midnight=Color3.fromRGB(165,160,190),
Graphite=Color3.fromRGB(156,163,175),
Pearl=Color3.fromRGB(87,83,78),
Slate=Color3.fromRGB(71,85,105),
Ocean=Color3.fromRGB(148,173,199),
Nord=Color3.fromRGB(180,190,205),
Forest=Color3.fromRGB(148,173,162),
Rose=Color3.fromRGB(178,156,171),
Amethyst=Color3.fromRGB(165,160,190),
Retro=Color3.fromRGB(120,96,70),
Glass=Color3.fromRGB(203,213,225),
Porcelain=Color3.fromRGB(71,85,105),
Mist=Color3.fromRGB(71,85,105),
Sandstone=Color3.fromRGB(120,96,70),
Dusk=Color3.fromRGB(196,181,212),
Frost=Color3.fromRGB(148,190,220),
Azure=Color3.fromRGB(148,173,199),
Blossom=Color3.fromRGB(150,110,128),
Fjord=Color3.fromRGB(160,175,195),
Summit=Color3.fromRGB(71,90,115),
}

for e,f in pairs(d)do
if b[e]then
b[e].WindowControlColor=f
end
end





local e={

Black={0,0,0},
Nord={0,0,0},


Default={0.15,0.65,0.1},




Light={0.2,0.6,0},
Midnight={0.2,0.6,0},
Graphite={0.2,0.6,0},
Pearl={0.2,0.6,0},
Slate={0.2,0.6,0},
Forest={0.2,0.6,0},
Amethyst={0.2,0.65,0},
Rose={0.2,0.6,0},
Retro={0.2,0.6,0},
Azure={0.2,0.6,0},
Blossom={0.2,0.6,0},
Fjord={0.2,0.6,0},
Summit={0.2,0.6,0},



Ocean={0.3,0,0.45},
Mist={0.3,0,0.45},
Sandstone={0.3,0,0.45},
Dusk={0.3,0,0.45},
Frost={0.3,0,0.45},


Glass={0.45,0.7,0.4},
Porcelain={0.3,0.6,0},
}

for f,g in pairs(e)do
local h=b[f]
if h then
h.WindowTransparency=g[1]
h.SidebarTransparency=g[2]
h.ContentBackgroundTransparency=g[3]
end
end



for f,g in pairs(b)do
if g.NotificationBackgroundColor==nil then
g.NotificationBackgroundColor=g.PopupBackgroundColor or g.WindowColor
g.NotificationBackgroundTransparency=math.clamp((g.PopupBackgroundTransparency or 0)+0.1,0,1)
g.NotificationShadowColor=g.PopupShadowColor or Color3.fromRGB(0,0,0)
g.NotificationHeaderColor=g.TitleTextColor or g.PopupTextColor or Color3.fromRGB(255,255,255)
g.NotificationHeaderTransparency=0.2
g.NotificationTextColor=g.SecondaryTextColor or g.PopupTextColor or Color3.fromRGB(226,232,240)
g.NotificationTextTransparency=0.4
g.NotificationDividerColor=g.TertiaryColor or Color3.fromRGB(148,163,184)
g.NotificationDividerTransparency=0.7
g.NotificationDismissColor=g.SecondaryTextColor or Color3.fromRGB(203,213,225)
g.NotificationActionButtonColor=g.InputBackgroundColor or g.PopupNeutralColor or Color3.fromRGB(51,65,85)
g.NotificationActionButtonTextColor=g.PopupTextColor or Color3.fromRGB(241,245,249)
g.NotificationAlertAccent=Color3.fromRGB(219,153,10)
g.NotificationErrorAccent=Color3.fromRGB(220,70,60)
g.NotificationVariableAccent=g.PrimaryColor or Color3.fromRGB(74,200,120)
end
end

return b end function a.d():typeof(__modImpl())local b=a.cache.d if not b then b={c=__modImpl()}a.cache.d=b end return b.c end end do local function __modImpl()













local b={}
b.theme=nil
b.name=nil
return b end function a.e():typeof(__modImpl())local b=a.cache.e if not b then b={c=__modImpl()}a.cache.e=b end return b.c end end do local function __modImpl()



















local b=a.d()
local c=a.a()
local d=a.e()

local e={}






e._components=setmetatable({},{__mode="k"})

function e.Register(f,g)
if f and g then
e._components[f]=g
end
end




e.ColorFadeTime=0.35





local f={"BackgroundColor3","TextColor3","ImageColor3"}

local function snapshotColors(g)
local h={}
for i,j in ipairs(g.Base:GetDescendants())do
local k={}
for l,m in ipairs(f)do
local n,o=pcall(function()return j[m]end)
if n and typeof(o)=="Color3"then
table.insert(k,{m,o})
end
end
if j:IsA"UIStroke"then
local l,m=pcall(function()return j.Color end)
if l and typeof(m)=="Color3"then
table.insert(k,{"Color",m})
end
end
if#k>0 then
table.insert(h,{instance=j,props=k})
end
end
return h
end

local function applyColorFade(g)
for h,i in ipairs(g)do
local j=i.instance
if j.Parent then
for k,l in ipairs(i.props)do
local m,n=l[1],l[2]
local o=j[m]
if typeof(o)=="Color3"and o~=n then
j[m]=n
local p=TweenInfo.new(
e.ColorFadeTime,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
)
c.Play(j,p,{[m]=o})
end
end
end
end
end

function e.GetTheme(g)

local h
if type(g)=="string"then
h=b[g]
if not h then
warn("[ThemeManager] Theme '"..tostring(g).."' not found, using Default")
h=b.Default
end
elseif type(g)=="table"then
h=g
else
h=b.Default
end


local i={}
for j,k in pairs(b.Default)do
i[j]=h[j]~=nil and h[j]or k
end
return i
end

function e.ApplyTheme(g,h)
local i=e.GetTheme(h)




d.theme=i
d.name=(type(h)=="string")and h or nil




c.CancelAll(g.Base)
for j,k in ipairs(g.Base:GetDescendants())do
c.CancelAll(k)
end


local j=snapshotColors(g)


if i.WindowColor then
g.MainFrame.BackgroundColor3=i.WindowColor
end
if i.WindowTransparency~=nil then
g.MainFrame.BackgroundTransparency=i.WindowTransparency
end



if g.ContentBackground then
g.ContentBackground.BackgroundColor3=i.ContentBackgroundColor or i.WindowColor
local k=i.ContentBackgroundTransparency
if k==nil then k=i.WindowTransparency end
if k~=nil then
g.ContentBackground.BackgroundTransparency=k
end
end


if i.SidebarColor then
g.Sidebar.BackgroundColor3=i.SidebarColor
end
if i.SidebarTransparency~=nil then
g.Sidebar.BackgroundTransparency=i.SidebarTransparency
end


if i.MainframeShadowColor then
local k=g.MainFrame:FindFirstChildWhichIsA"UIShadow"
if k then
k.Color=i.MainframeShadowColor
end
end


g._theme=i



if g.TabGroup then
g.TabGroup._theme=i
g.TabGroup._fadeCaches={}
if g.TabGroup.Tabs then
for k,l in ipairs(g.TabGroup.Tabs)do
l._theme=i
end
end
end


if g.SettingsTabGroup then
g.SettingsTabGroup._theme=i
g.SettingsTabGroup._fadeCaches={}
if g.SettingsTabGroup.Tabs then
for k,l in ipairs(g.SettingsTabGroup.Tabs)do
l._theme=i
end
end
end




if g.ApplyTheme then
pcall(function()g:ApplyTheme(i)end)
end





for k,l in ipairs(g.Base:GetDescendants())do
local m=e._components[l]
if m and m.ApplyTheme then
pcall(function()m:ApplyTheme(i)end)
end
end




if g.TabGroup and g.TabGroup.ActiveTab and g.TabGroup.ActiveTab.BackImageGradient then
g.TabGroup:_resumeSpin(g.TabGroup.ActiveTab.BackImageGradient,true)
end
if g.SettingsTabGroup and g.SettingsTabGroup.ActiveTab and g.SettingsTabGroup.ActiveTab.BackImageGradient then
g.SettingsTabGroup:_resumeSpin(g.SettingsTabGroup.ActiveTab.BackImageGradient,true)
end





c.RestartSpins()






if g.SettingsTabGroup and g.SettingsTabGroup.Tabs then
local k=g.SettingsTabGroup.ActiveTab
for l,m in ipairs(g.SettingsTabGroup.Tabs)do
local n=m==k
if n then
m.SelectionStatus.BackgroundTransparency=0
m.SelectionStatus.Size=UDim2.new(0,2,0.7,0)
m.BackImage.ImageTransparency=0
else
m.SelectionStatus.BackgroundTransparency=1
m.SelectionStatus.Size=UDim2.new(0,2,0,0)
m.BackImage.ImageTransparency=1
end
end
end









if g.TabGroup and g.TabGroup.InvalidateCaches then
g.TabGroup:InvalidateCaches()
end
if g.SettingsTabGroup and g.SettingsTabGroup.InvalidateCaches then
g.SettingsTabGroup:InvalidateCaches()
end




if g.TabGroup and g.TabGroup.RestoreActiveTab then
g.TabGroup:RestoreActiveTab()
end
if g.SettingsTabGroup and g.SettingsTabGroup.RestoreActivePage then
g.SettingsTabGroup:RestoreActivePage()
end


applyColorFade(j)
end


function e.UpdateTheme(g,h)
e.ApplyTheme(g,h)
end

return e end function a.f():typeof(__modImpl())local b=a.cache.f if not b then b={c=__modImpl()}a.cache.f=b end return b.c end end do local function __modImpl()

















local b=a.f()
local c=a.e()
local d=a.a()
local e={}
e.__index=e
function e.new(f,g,h,i)
i=b.GetTheme(i)
g=g or{}
local j=setmetatable({},e)
j._theme=i
j._themeResolved=i
local k=g.Name or"Toggle"
local l=g.Default or false
local m=g.Confirm or{}
local n=m.Enabled or false



local o=Instance.new"TextButton"
o.Name=k.." [Toggle]"
o.BorderSizePixel=0
o.BackgroundColor3=Color3.fromRGB(31,32,34)
o.BackgroundTransparency=1
o.Size=UDim2.new(1,0,0,45)
o.AnchorPoint=Vector2.new(0.5,0.5)
o.Position=UDim2.new(0.5,0,0.5,0)
o.Text=""
o.TextTransparency=1
o.AutoButtonColor=false
o.Parent=f



local p=Instance.new"TextLabel"
p.Name="ElementName"
p.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.Regular,
Enum.FontStyle.Normal
)
p.Text=k
p.TextColor3=(i and i.PrimaryTextColor)
p.TextSize=14
p.TextTransparency=(i and i.PrimaryTextTransparency)or 0.45
p.TextTruncate=Enum.TextTruncate.AtEnd
p.TextWrapped=true
p.TextXAlignment=Enum.TextXAlignment.Left
p.AnchorPoint=Vector2.new(0,0.5)
p.BackgroundTransparency=1
p.Size=UDim2.new(0.486,0,0.714,0)
p.Position=UDim2.new(0,0,0.5,0)
p.Parent=o

local q=Instance.new"Frame"
q.Name="InterractionHolder"
q.BackgroundTransparency=1
q.AnchorPoint=Vector2.new(1,0.5)
q.Size=UDim2.new(0,65,1,0)
q.Position=UDim2.new(1,0,0.5,0)
q.Parent=o




local r=Instance.new"Frame"
r.Name="ToggleSlidingFrame"
r.BorderSizePixel=0
r.BackgroundColor3=i.SecondaryColor
r.BackgroundTransparency=0.9
r.AnchorPoint=Vector2.new(0.5,0.5)
r.Size=UDim2.new(0,34,0,2)
r.Position=UDim2.new(0.5,0,0.5,0)
r.Parent=q
j.track=r



local s=Instance.new"TextButton"
s.Name="Toggle"
s.BorderSizePixel=0
s.BackgroundColor3=(i and i.PrimaryColor)
s.BackgroundTransparency=1
s.AnchorPoint=Vector2.new(0.5,0.5)
s.Size=UDim2.new(0,14,0,14)
s.Position=UDim2.new(0,-6,0.5,0)
s.Text=""
s.TextTransparency=1
s.AutoButtonColor=false
s.Parent=r


s:SetAttribute("ThemePrimary",i.PrimaryColor)
s:SetAttribute("ThemeSecondary",i.SecondaryColor)



local t=Instance.new"UISizeConstraint"
t.Parent=s



local u=Instance.new"UICorner"
u.CornerRadius=UDim.new(1,0)
u.Parent=s



local v=Instance.new"UIStroke"
v.Transparency=(i and i.StrokeTransparency)or 0.7
v.Thickness=1.5
v.Color=i.PrimaryColor
v.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
v.Parent=s



local w=Instance.new"ImageLabel"
w.Name="BackImage"
w.BorderSizePixel=0
w.BackgroundTransparency=1
w.Image=i.Wallpaper or"rbxassetid://11094025229"
w:SetAttribute("IsThemeSheen",true)
w.ImageTransparency=1
w.AnchorPoint=Vector2.new(0.5,0.5)
w.Position=UDim2.new(0.5,0,0.5,0)
w.Size=UDim2.new(1,0,1,0)
w.Parent=s
local x=Instance.new"UICorner"
x.CornerRadius=UDim.new(1,0)
x.Parent=w
local y=Instance.new"UIGradient"
y.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(0.324,0.80625),
NumberSequenceKeypoint.new(0.600,0.6875),
NumberSequenceKeypoint.new(0.726,0.55),
NumberSequenceKeypoint.new(0.844,0.36875),
NumberSequenceKeypoint.new(1.000,0),
}
y.Parent=w


y.Rotation=0
d.StartSpin(y,{Rotation=360},"SpinIdle")



local z=l
local A=UDim2.new(0,-6,0.5,0)
local B=UDim2.new(0,41,0.5,0)

local C=false



local function applyState(D,E,F)
if z==D and F then
return
end
z=D
s:SetAttribute("IsOn",z)





local G=s:GetAttribute"ThemePrimary"
or(c.theme and c.theme.PrimaryColor)
or i.PrimaryColor
local H=s:GetAttribute"ThemeSecondary"
or(c.theme and c.theme.SecondaryColor)
or i.SecondaryColor
local I=z and B or A
local J=
z and 0 or 1
local K=
z and 0 or 0.7
local L=z and G or H
local M=z and G or H
local N=
z and 0 or 0.9
local O=
z and 0.1 or 0.45
if E then
d.Play(s,"Fast",{
Position=I,
BackgroundColor3=G,
BackgroundTransparency=J
})
d.Play(v,"Fast",{
Transparency=K,
Color=L
})
d.Play(p,"Fast",{
TextTransparency=O
})
d.Play(r,"Fast",{
BackgroundColor3=M,
BackgroundTransparency=N
})
d.Play(w,"Fast",{
ImageTransparency=z and 0 or 1
})
else
s:SetAttribute("IsOn",z)
s.Position=I
s.BackgroundColor3=G
s.BackgroundTransparency=J
v.Transparency=K
v.Color=L
p.TextTransparency=O
r.BackgroundColor3=M
r.BackgroundTransparency=N
w.ImageTransparency=z and 0 or 1
end
if F and g.Callback then
g.Callback(z)
end
end



local function handleClick()


if C then
return
end
local D=not z



if n and h and D then
C=true
h{
Title=
m.Title
or"Confirm Action",
Description=
m.Description
or"Are you sure you want to change this setting?",
TitleColor=
m.TitleColor,
ConfirmText=
m.ConfirmText
or"Yes",
CancelText=
m.CancelText
or"No",



OnConfirm=function()
C=false


applyState(
D,
true,
true
)
end,



OnCancel=function()




C=false
end,
}



else
applyState(
D,
true,
true
)
end
end



o.MouseButton1Click:Connect(function()
handleClick()
end)
s.MouseButton1Click:Connect(function()
handleClick()
end)





applyState(
l,
false,
false
)



function j.UpdateState(D,E)
if typeof(E)~="boolean"then
warn(
"[Toggle] UpdateState expected a boolean, got:",
typeof(E)
)
return
end


if E~=z then
applyState(
E,
true,
true
)
end
end
function j.GetState(D)
return z
end
function j.SetVisibility(D,E)
o.Visible=E
end
function j.UpdateName(D,E)
p.Text=E
end



function j.ApplyTheme(D,E)
i=b.GetTheme(E)
D._theme=i
D._themeResolved=i
s:SetAttribute("ThemePrimary",i.PrimaryColor)
s:SetAttribute("ThemeSecondary",i.SecondaryColor)
p.TextColor3=i.PrimaryTextColor or p.TextColor3
w.Image=i.Wallpaper or"rbxassetid://11094025229"
w.Visible=not(i.WallpaperEnabled==false)
applyState(z,false,false)
end
b.Register(o,j)
return j
end
return e end function a.g():typeof(__modImpl())local b=a.cache.g if not b then b={c=__modImpl()}a.cache.g=b end return b.c end end do local function __modImpl()
















local b=a.a()
local c=a.c()
local d=a.f()
local e=a.e()

local f={}
f.__index=f

f.SpinningEnabled=true
function f.new(g,h,i)
i=d.GetTheme(i)
h=h or{}
local j=setmetatable({},f)
j._theme=i
local k=h.Name or"Slider"
local l=h.Min or 0
local m=h.Max or 100
local n=h.Default or 50
local o=h.Precision or 0

local p=Instance.new"Frame"
p.Name=k.."Slider"
p.BorderSizePixel=0
p.BackgroundColor3=Color3.fromRGB(31,32,34)
p.BackgroundTransparency=1
p.Size=UDim2.new(1,0,0,45)
p.AnchorPoint=Vector2.new(0.5,0.5)
p.Position=UDim2.new(0.5,0,0.5,0)
p.BorderColor3=Color3.fromRGB(0,0,0)
p.Parent=g

local q=Instance.new"TextLabel"
q.Name="ElementName"
q.TextWrapped=true
q.TextTruncate=Enum.TextTruncate.AtEnd
q.BorderSizePixel=0
q.TextSize=14
q.TextXAlignment=Enum.TextXAlignment.Left
q.TextTransparency=i.PrimaryTextTransparency
q.BackgroundColor3=Color3.fromRGB(55,55,55)
q.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
q.TextColor3=i.PrimaryTextColor
q.BackgroundTransparency=1
q.Size=UDim2.new(0.59985,0,0.31745,0)
q.Position=UDim2.new(0,0,0.12063,0)
q.BorderColor3=Color3.fromRGB(0,0,0)
q.Text=k
q.Parent=p

local r=Instance.new"Frame"
r.Name="SliderHolder"
r.BorderSizePixel=0
r.BackgroundColor3=i.Undercolor
r.BackgroundTransparency=0
r.AnchorPoint=Vector2.new(0.5,0.5)
r.Size=UDim2.new(1,0,0.18946,0)
r.Position=UDim2.new(0.5003,0,0.72338,0)
r.BorderColor3=Color3.fromRGB(255,255,255)
r.Parent=p
local s=Instance.new"UICorner"
s.CornerRadius=UDim.new(0,5)
s.Parent=r
local t=Instance.new"UIShadow"
t.Parent=r

local u=Instance.new"Frame"
u.Name="SliderVisual"
u.BorderSizePixel=0
u.BackgroundColor3=(i and i.PrimaryColor)
u.Size=UDim2.new(0.201,0,1,0)
u.BorderColor3=Color3.fromRGB(0,0,0)
u.Parent=r
local v=Instance.new"UICorner"
v.CornerRadius=UDim.new(0,6)
v.Parent=u

local w=Instance.new"ImageLabel"
w.Name="BackImage"
w.BorderSizePixel=0
w.BackgroundColor3=Color3.fromRGB(255,255,255)
w.ImageTransparency=0.5
w.AnchorPoint=Vector2.new(0.5,0.5)
w.Image=i.Wallpaper or"rbxassetid://11094025229"
w:SetAttribute("IsThemeSheen",true)
w.Size=UDim2.new(1,0,1,0)
w.BorderColor3=Color3.fromRGB(0,0,0)
w.BackgroundTransparency=1
w.Position=UDim2.new(0.5,0,0.5,0)
w.Parent=u

if i and i.WallpaperEnabled==false then
w.Visible=false
else
w.Visible=true
end
local x=Instance.new"UICorner"
x.CornerRadius=UDim.new(0,6)
x.Parent=w
local y=Instance.new"UIGradient"
y.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(0.324,0.80625),
NumberSequenceKeypoint.new(0.600,0.6875),
NumberSequenceKeypoint.new(0.726,0.55),
NumberSequenceKeypoint.new(0.844,0.36875),
NumberSequenceKeypoint.new(1.000,0)
}
y.Parent=w

local z=Instance.new"ImageButton"
z.Name="SliderButton"
z.BorderSizePixel=0
z.AutoButtonColor=false
z.ImageTransparency=1
z.BackgroundTransparency=1
z.BackgroundColor3=Color3.fromRGB(255,255,255)
z.AnchorPoint=Vector2.new(1,0.5)
z.Image="rbxasset://textures/ui/GuiImagePlaceholder.png"
z.Size=UDim2.new(0.4,0,1,0)
z.Position=UDim2.new(1,0,0.5,0)
z.BorderColor3=Color3.fromRGB(0,0,0)
z.Parent=u
local A=Instance.new"UICorner"
A.CornerRadius=UDim.new(0,10)
A.Parent=z

local B=Instance.new"Frame"
B.Name="ControlHolder"
B.AnchorPoint=Vector2.new(1,0)
B.Position=UDim2.new(1,0,0.12063,0)
B.Size=UDim2.new(0,50,0,10)
B.BackgroundTransparency=1
B.Parent=p

local C=Instance.new"UIListLayout"
C.FillDirection=Enum.FillDirection.Horizontal
C.Padding=UDim.new(0,5)
C.SortOrder=Enum.SortOrder.LayoutOrder
C.VerticalAlignment=Enum.VerticalAlignment.Center
C.HorizontalAlignment=Enum.HorizontalAlignment.Right
C.Parent=B


local D=Instance.new"ImageButton"
D.Name="ResetButton"
D.LayoutOrder=3
D.BorderSizePixel=0
D.AutoButtonColor=false
D.BackgroundTransparency=1
D.BackgroundColor3=Color3.fromRGB(255,255,255)
D.AnchorPoint=Vector2.new(0.5,0.5)
D.Image=c["rotate-ccw"]or"rbxassetid://110116685948665"
D.ImageColor3=i.AccentColor
D.Size=UDim2.new(0,13,0,13)
D.BorderColor3=Color3.fromRGB(0,0,0)
D.AnchorPoint=Vector2.new(1,0.5)
D.Parent=B
local E=Instance.new"UIAspectRatioConstraint"
E.Parent=D

local F=Instance.new"TextLabel"
F.Name="PercentageStat"
F.LayoutOrder=2
F.TextWrapped=true
F.TextTruncate=Enum.TextTruncate.AtEnd
F.BorderSizePixel=0
F.TextSize=11
F.TextTransparency=i.SecondaryTextTransparency
F.BackgroundColor3=Color3.fromRGB(55,55,55)
F.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
F.TextColor3=i.SecondaryTextColor
F.BackgroundTransparency=1


F.AnchorPoint=Vector2.new(1,0)
F.Size=UDim2.new(0,35,0,14)
F.BorderColor3=Color3.fromRGB(0,0,0)
F.Text="0%"
F.Parent=B

local G=Instance.new"TextBox"
G.Name="SliderStat"
G.LayoutOrder=1
G.PlaceholderColor3=Color3.fromRGB(100,100,100)
G.BorderSizePixel=0
G.TextTransparency=i.SecondaryTextTransparency
G.TextSize=9
G.TextColor3=i.SecondaryTextColor
G.BackgroundColor3=i.InputBackgroundColor
G.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
G.AutomaticSize=Enum.AutomaticSize.X
G.AnchorPoint=Vector2.new(1,0)
G.TextTruncate=Enum.TextTruncate.AtEnd
G.PlaceholderText="0"
G.Size=UDim2.new(0,56,0,14)
G.BorderColor3=Color3.fromRGB(0,0,0)
G.Text=""
G.BackgroundTransparency=i.InputBackgroundTransparency
G.Parent=B
local H=Instance.new"UIStroke"
H.Transparency=i.StrokeTransparency
H.Color=i.StrokeColor
H.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
H.Parent=G
local I=Instance.new"UICorner"
I.CornerRadius=UDim.new(0,4)
I.Parent=G
local J=Instance.new"UIPadding"
J.PaddingBottom=UDim.new(0,3)
J.Parent=G
local K=Instance.new"UISizeConstraint"
K.MaxSize=Vector2.new(56,20)
K.Parent=G

local L=n
local M=false
local N=false


local function formatValue(O)
return string.format("%."..o.."f",O)
end

local function updateSlider(O,P)
O=math.clamp(O,l,m)
L=O
local Q=(O-l)/(m-l)
local R=UDim2.new(Q,0,1,0)
if P then
b.Play(u,"Smooth",{Size=R})
else
u.Size=R
end

F.Text=math.round(Q*100).."%"
G.Text=formatValue(O)
G.PlaceholderText=formatValue(O)
if h.Callback then
h.Callback(O)
end
end

G.FocusLost:Connect(function()
local O=tonumber(G.Text)
if O then
updateSlider(O,true)
else
G.Text=formatValue(L)
end
end)

local function updateVisibility()
local O=(N or M)and 0 or 0.5
b.Play(F,"Fast",{TextTransparency=O})
b.Play(w,"Fast",{ImageTransparency=O})

end

local function processInput(O)
local P=r.AbsoluteSize.X
if P<=0 then return end
local Q=O.Position.X-r.AbsolutePosition.X
local R=math.clamp(Q/P,0,1)
local S=l+R*(m-l)
updateSlider(S,false)
end

z.InputBegan:Connect(function(O)
if O.UserInputType==Enum.UserInputType.MouseButton1 or O.UserInputType==Enum.UserInputType.Touch then
M=true
updateVisibility()
end
end)



local O=game:GetService"UserInputService"
local P=O.InputChanged:Connect(function(P)
if M and(P.UserInputType==Enum.UserInputType.MouseMovement or P.UserInputType==Enum.UserInputType.Touch)then
processInput(P)
end
end)
local Q=O.InputEnded:Connect(function(Q)
if M and(Q.UserInputType==Enum.UserInputType.MouseButton1 or Q.UserInputType==Enum.UserInputType.Touch)then
M=false
updateVisibility()
end
end)
p.Destroying:Connect(function()
P:Disconnect()
Q:Disconnect()
b.StopSpin(y)
end)

r.InputBegan:Connect(function(R)
if R.UserInputType==Enum.UserInputType.MouseButton1 or R.UserInputType==Enum.UserInputType.Touch then
M=true
updateVisibility()
processInput(R)
end
end)

z.MouseEnter:Connect(function()
N=true
updateVisibility()
end)
z.MouseLeave:Connect(function()
N=false
updateVisibility()
end)

D.MouseButton1Click:Connect(function()
updateSlider(n,true)
end)
D.MouseEnter:Connect(function()
D.ImageColor3=(e.theme or i).AccentColor
b.Play(D,"Fast",{ImageTransparency=0.2})
end)
D.MouseLeave:Connect(function()
D.ImageColor3=(e.theme or i).AccentColor
b.Play(D,"Fast",{ImageTransparency=0})
end)

local function startSpin()
if not f.SpinningEnabled then return end
y.Rotation=0
b.StartSpin(y,{Rotation=360},"SpinIdle")
end
local function stopSpin()
b.StopSpin(y)
end

if f.SpinningEnabled then
startSpin()
end

updateSlider(n,false)
updateVisibility()

j.UpdateValue=function(R)
updateSlider(R,true)
end
j.GetValue=function()
return L
end
j.SetVisibility=function(R)
p.Visible=R
end
j.UpdateName=function(R)
q.Text=R
end
j.EnableSpinning=function(R)
if R then
startSpin()
else
stopSpin()
end
end

function j.ApplyTheme(R,S)
i=d.GetTheme(S)
R._theme=i
q.TextColor3=i.PrimaryTextColor or q.TextColor3
q.TextTransparency=i.PrimaryTextTransparency or q.TextTransparency
r.BackgroundColor3=i.Undercolor or r.BackgroundColor3
u.BackgroundColor3=i.PrimaryColor or u.BackgroundColor3
D.ImageColor3=i.AccentColor or D.ImageColor3
F.TextColor3=i.SecondaryTextColor or F.TextColor3
G.TextColor3=i.SecondaryTextColor or G.TextColor3
G.BackgroundColor3=i.InputBackgroundColor or G.BackgroundColor3
G.BackgroundTransparency=i.InputBackgroundTransparency or G.BackgroundTransparency
H.Color=i.StrokeColor or H.Color
H.Transparency=i.StrokeTransparency or H.Transparency
w.Image=i.Wallpaper or"rbxassetid://11094025229"
w.Visible=not(i.WallpaperEnabled==false)
t.Color=i.ComponentShadowColor or t.Color
end
d.Register(p,j)
return j
end
return f end function a.h():typeof(__modImpl())local b=a.cache.h if not b then b={c=__modImpl()}a.cache.h=b end return b.c end end do local function __modImpl()




















local b=a.a()
local c=game:GetService"UserInputService"
local d=a.f()
local e=a.e()
local f={}
f.__index=f



local g={
LeftControl="LtCtrl",RightControl="RtCtrl",
LeftShift="LtShift",RightShift="RtShift",
LeftAlt="LtAlt",RightAlt="RtAlt",

Zero="0",One="1",Two="2",Three="3",Four="4",
Five="5",Six="6",Seven="7",Eight="8",Nine="9",

Backquote="`",Equals="=",Minus="-",
LeftBracket="[",RightBracket="]",BackSlash="\\",
Quote="'",Comma=",",Period=".",Semicolon=";",
}



local h={}
for i,j in ipairs{
Enum.KeyCode.A,Enum.KeyCode.B,Enum.KeyCode.C,Enum.KeyCode.D,Enum.KeyCode.E,
Enum.KeyCode.F,Enum.KeyCode.G,Enum.KeyCode.H,Enum.KeyCode.I,Enum.KeyCode.J,
Enum.KeyCode.K,Enum.KeyCode.L,Enum.KeyCode.M,Enum.KeyCode.N,Enum.KeyCode.O,
Enum.KeyCode.P,Enum.KeyCode.Q,Enum.KeyCode.R,Enum.KeyCode.S,Enum.KeyCode.T,
Enum.KeyCode.U,Enum.KeyCode.V,Enum.KeyCode.W,Enum.KeyCode.X,Enum.KeyCode.Y,
Enum.KeyCode.Z,
Enum.KeyCode.Zero,Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,
Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,
Enum.KeyCode.Eight,Enum.KeyCode.Nine,
Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,
Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,
Enum.KeyCode.LeftAlt,Enum.KeyCode.RightAlt,
Enum.KeyCode.Backquote,Enum.KeyCode.Equals,Enum.KeyCode.Minus,
Enum.KeyCode.LeftBracket,Enum.KeyCode.RightBracket,Enum.KeyCode.BackSlash,
Enum.KeyCode.Quote,Enum.KeyCode.Comma,Enum.KeyCode.Period,Enum.KeyCode.Semicolon,
}do
h[j]=true
end

function f.new(i,j,k)
k=d.GetTheme(k)
j=j or{}
local l=setmetatable({},f)
l._theme=k
local m=j.Name or"Keybind"
local n=j.Default or""

local o=Instance.new"Frame"
o.Name=m.."Keybind"
o.BorderSizePixel=0
o.BackgroundColor3=Color3.fromRGB(31,32,34)
o.BackgroundTransparency=1
o.Size=UDim2.new(1,0,0,45)
o.AnchorPoint=Vector2.new(0.5,0.5)
o.Position=UDim2.new(0.5,0,0.5,0)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Parent=i

local p=Instance.new"TextLabel"
p.Name="ElementName"
p.TextWrapped=true
p.BorderSizePixel=0
p.TextSize=14
p.TextXAlignment=Enum.TextXAlignment.Left
p.TextTransparency=(k and k.PrimaryTextTransparency)or 0.45
p.BackgroundColor3=Color3.fromRGB(255,255,255)
p.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
p.TextColor3=(k and k.PrimaryTextColor)
p.BackgroundTransparency=1
p.AnchorPoint=Vector2.new(0,0.5)
p.Size=UDim2.new(0.48591,0,0.71359,0)
p.Position=UDim2.new(0,0,0.5,0)
p.BorderColor3=Color3.fromRGB(0,0,0)
p.Text=m
p.Parent=o

local q=Instance.new"TextBox"
q.Name="InputBox"
q.PlaceholderColor3=Color3.fromRGB(100,100,100)
q.BorderSizePixel=0
q.TextWrapped=true
q.TextTransparency=(k and k.SecondaryTextTransparency)or 0.4
q.TextSize=11
q.TextColor3=(k and k.SecondaryTextColor)
q.BackgroundColor3=k.InputBackgroundColor
q.BackgroundTransparency=k.InputBackgroundTransparency
q:SetAttribute("IsInputBackground",true)
q.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
q.AnchorPoint=Vector2.new(1,0.5)
q.ClearTextOnFocus=true
q.PlaceholderText="[...]"
q.Size=UDim2.new(0,45,0,29)
q.Position=UDim2.new(1,0,0.5,0)
q.BorderColor3=Color3.fromRGB(0,0,0)
q.Text=""
q.Parent=o
local r=Instance.new"UICorner"
r.CornerRadius=UDim.new(0,6)
r.Parent=q
local s=Instance.new"UIStroke"
s.Transparency=(k and k.StrokeTransparency)or 0.95
s.Thickness=0.7
s.Color=(k and k.StrokeColor)
s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
s.Parent=q

local t=n or""
local u=t
local v=false
local w

local function setKey(x)
t=x
if x and x~=""then


q.Text=g[x]or((#x==1)and string.upper(x)or x)
else
q.Text=""
end

if j.OnRebind then
j.OnRebind(t)
end
end





local x=c.InputBegan:Connect(function(x,y)

if v then return end

if y then return end
if x.UserInputType~=Enum.UserInputType.Keyboard then return end
if t~=""and x.KeyCode.Name==t then
if j.Callback then
j.Callback(t)
end
end
end)

local function setStrokeBright(y)
local z=e.theme or k
local A=y and 0.3 or(z and z.StrokeTransparency or 0.95)
local B=z.StrokeColor
b.Play(s,"Fast",{Transparency=A,Color=B})
end

local function onHoverEnter()
setStrokeBright(true)
end
local function onHoverLeave()
if not q:IsFocused()then
setStrokeBright(false)
end
end
o.MouseEnter:Connect(onHoverEnter)
o.MouseLeave:Connect(onHoverLeave)
q.MouseEnter:Connect(onHoverEnter)
q.MouseLeave:Connect(onHoverLeave)

q.Focused:Connect(function()

u=t
setStrokeBright(true)
v=true
q.Text=""

w=c.InputBegan:Connect(function(y,z)





if not v then return end
if y.UserInputType==Enum.UserInputType.Keyboard then
local A=y.KeyCode



if A==Enum.KeyCode.Backspace then
setKey""
v=false
q:ReleaseFocus()
if w then w:Disconnect()end
setStrokeBright(false)
elseif h[A]then
setKey(A.Name)
v=false
q:ReleaseFocus()
if w then w:Disconnect()end
setStrokeBright(false)
end
end
end)
end)
q.FocusLost:Connect(function()

if v then

v=false
if w then w:Disconnect()end

t=u
if t and t~=""then
q.Text=string.upper(t)
else
q.Text=""
end
end

setStrokeBright(false)
end)

setKey(n)

l.GetBind=function()
return t
end
l.SetBind=function(y)
setKey(y)
end
l.SetVisibility=function(y)
o.Visible=y
end
l.UpdateName=function(y)
p.Text=y
end


local function disconnectAll()
if x then x:Disconnect()end
if w then w:Disconnect()end
end
o.Destroying:Connect(disconnectAll)
l.Destroy=function()
disconnectAll()
if o.Parent then o:Destroy()end
end

function l.ApplyTheme(y,z)
k=d.GetTheme(z)
y._theme=k
p.TextColor3=k.PrimaryTextColor or p.TextColor3
p.TextTransparency=k.PrimaryTextTransparency or p.TextTransparency
q.TextColor3=k.SecondaryTextColor or q.TextColor3
q.TextTransparency=k.SecondaryTextTransparency or q.TextTransparency
q.BackgroundColor3=k.InputBackgroundColor or q.BackgroundColor3
q.BackgroundTransparency=k.InputBackgroundTransparency or q.BackgroundTransparency
s.Color=k.StrokeColor or s.Color
s.Transparency=k.StrokeTransparency or s.Transparency
end
d.Register(o,l)
return l
end
return f end function a.i():typeof(__modImpl())local b=a.cache.i if not b then b={c=__modImpl()}a.cache.i=b end return b.c end end do local function __modImpl()















local b=a.f()
local c={}
c.__index=c
function c.new(d,e,f)
f=b.GetTheme(f)
e=e or{}
local g=setmetatable({},c)
local h=e.Color or f.SectionDividerColor
local i=e.Transparency or f.SectionDividerTransparency
local j=e.Color~=nil
local k=e.Transparency~=nil
local l=e.Thickness or 1

local m=Instance.new"Frame"
m.Name="Divider"
m.BorderSizePixel=0
m.BackgroundColor3=h
m.BackgroundTransparency=i
m.Size=UDim2.new(0.90447,0,0,l)
m.AnchorPoint=Vector2.new(0.5,0.5)
m.Position=UDim2.new(0.5,0,0.5,0)
m.BorderColor3=Color3.fromRGB(0,0,0)
m:SetAttribute("IsSectionDivider",true)
m:SetAttribute("HasCustomDividerColor",j)
m:SetAttribute("HasCustomDividerTransparency",k)
m.Parent=d
g.Frame=m

g.SetVisibility=function(n)
m.Visible=n
end
function g.SetColor(n,o)
m.BackgroundColor3=o
end
function g.SetTransparency(n,o)
m.BackgroundTransparency=o
end


function g.ApplyTheme(n,o)
f=b.GetTheme(o)
n._theme=f
if not j then
m.BackgroundColor3=f.SectionDividerColor or m.BackgroundColor3
end
if not k then
m.BackgroundTransparency=f.SectionDividerTransparency or m.BackgroundTransparency
end
end
b.Register(m,g)
return g
end
return c end function a.j():typeof(__modImpl())local b=a.cache.j if not b then b={c=__modImpl()}a.cache.j=b end return b.c end end do local function __modImpl()















local b=a.a()
local c=a.f()
local d=a.e()

local e={}
e.__index=e
function e.new(f,g,h)
h=c.GetTheme(h)
g=g or{}
local i=setmetatable({},e)
i._theme=h
local j=g.Name or"Text Input"
local k=g.Placeholder or"[...]"
local l=g.Default or""

local m=Instance.new"Frame"
m.Name=j.."TextInput"
m.BorderSizePixel=0
m.BackgroundColor3=Color3.fromRGB(31,32,34)
m.BackgroundTransparency=1
m.Size=UDim2.new(1,0,0,45)
m.AnchorPoint=Vector2.new(0.5,0.5)
m.Position=UDim2.new(0.5,0,0.5,0)
m.BorderColor3=Color3.fromRGB(0,0,0)
m.Parent=f

local n=Instance.new"TextLabel"
n.Name="ElementName"
n.TextWrapped=true
n.BorderSizePixel=0
n.TextSize=14
n.TextXAlignment=Enum.TextXAlignment.Left
n.TextTransparency=(h and h.PrimaryTextTransparency)or 0.45
n.BackgroundColor3=Color3.fromRGB(55,55,55)
n.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
n.TextColor3=(h and h.PrimaryTextColor)
n.BackgroundTransparency=1
n.AnchorPoint=Vector2.new(0,0.5)
n.Size=UDim2.new(0.48591,0,0.71359,0)
n.Position=UDim2.new(0,0,0.5,0)
n.BorderColor3=Color3.fromRGB(0,0,0)
n.Text=j
n.Parent=m

local o=Instance.new"TextBox"
o.Name="InputBox"
o.PlaceholderColor3=Color3.fromRGB(100,100,100)
o.BorderSizePixel=0
o.TextWrapped=true
o.TextTransparency=(h and h.SecondaryTextTransparency)or 0.4
o.TextSize=11
o.TextColor3=(h and h.SecondaryTextColor)
o.BackgroundColor3=h.InputBackgroundColor
o.BackgroundTransparency=h.InputBackgroundTransparency
o:SetAttribute("IsInputBackground",true)
o.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
o.AutomaticSize=Enum.AutomaticSize.X
o.AnchorPoint=Vector2.new(1,0.5)
o.ClearTextOnFocus=false
o.PlaceholderText=k
o.Position=UDim2.new(1,0,0.5,0)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Text=l
o.Parent=m
local p=Instance.new"UICorner"
p.CornerRadius=UDim.new(0,6)
p.Parent=o
local q=Instance.new"UIStroke"
q.Transparency=(h and h.StrokeTransparency)or 0.95
q.Thickness=0.7
q.Color=(h and h.StrokeColor)
q.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
q.Parent=o
local r=Instance.new"UIPadding"
r.PaddingRight=UDim.new(0,7)
r.PaddingLeft=UDim.new(0,7)
r.Parent=o
local s=Instance.new"UISizeConstraint"
s.MinSize=Vector2.new(60,25)
s.MaxSize=Vector2.new(105,25)
s.Parent=o

local function setStrokeBright(t)
local u=d.theme or h
local v=t and 0.3 or(u and u.StrokeTransparency or 0.95)
local w=u.StrokeColor
b.Play(q,"Fast",{Transparency=v,Color=w})
end

o.MouseEnter:Connect(function()
setStrokeBright(true)
end)
o.MouseLeave:Connect(function()
if not o:IsFocused()then
setStrokeBright(false)
end
end)

o.Focused:Connect(function()
setStrokeBright(true)
end)
o.FocusLost:Connect(function()
setStrokeBright(false)
if g.Callback then
g.Callback(o.Text)
end
end)

i.GetText=function()
return o.Text
end
i.SetText=function(t)
o.Text=t
end
i.SetVisibility=function(t)
m.Visible=t
end
i.UpdateName=function(t)
n.Text=t
end
i.SetPlaceholder=function(t)
o.PlaceholderText=t
end

function i.ApplyTheme(t,u)
h=c.GetTheme(u)
t._theme=h
n.TextColor3=h.PrimaryTextColor or n.TextColor3
n.TextTransparency=h.PrimaryTextTransparency or n.TextTransparency
o.TextColor3=h.SecondaryTextColor or o.TextColor3
o.TextTransparency=h.SecondaryTextTransparency or o.TextTransparency
o.BackgroundColor3=h.InputBackgroundColor or o.BackgroundColor3
o.BackgroundTransparency=h.InputBackgroundTransparency or o.BackgroundTransparency
q.Color=h.StrokeColor or q.Color
q.Transparency=h.StrokeTransparency or q.Transparency
end
c.Register(m,i)
return i
end
return e end function a.k():typeof(__modImpl())local b=a.cache.k if not b then b={c=__modImpl()}a.cache.k=b end return b.c end end do local function __modImpl()










local b={}

b.FallbackImage="rbxassetid://11094025229"

return b end function a.l():typeof(__modImpl())local b=a.cache.l if not b then b={c=__modImpl()}a.cache.l=b end return b.c end end do local function __modImpl()









local b=a.f()
local c=a.a()
local d=a.l().FallbackImage
local e={}
e.__index=e
function e.new(f,g,h,i)
i=b.GetTheme(i)
h=h or{}
local j=setmetatable({},e)
j._theme=i
local k=h.Name or"Radio Button"
local l=h.Default or false
local m=h.Callback

local n=Instance.new"Frame"
n.Name=k.."RadioButton"
n.BorderSizePixel=0
n.BackgroundColor3=Color3.fromRGB(38,39,41)
n.BackgroundTransparency=1
n.Size=UDim2.new(1,0,0,45)
n.AnchorPoint=Vector2.new(0.5,0.5)
n.Position=UDim2.new(0.5,0,0.5,0)
n.BorderColor3=Color3.fromRGB(0,0,0)
n.Parent=f

local o=Instance.new"TextLabel"
o.Name="ElementName"
o.TextWrapped=true
o.BorderSizePixel=0
o.TextSize=14
o.TextXAlignment=Enum.TextXAlignment.Left
o.TextTransparency=i.PrimaryTextTransparency
o.BackgroundColor3=Color3.fromRGB(55,55,55)
o.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.Regular,
Enum.FontStyle.Normal
)
o.TextColor3=i.PrimaryTextColor
o.BackgroundTransparency=1
o.AnchorPoint=Vector2.new(0,0.5)
o.Size=UDim2.new(0.48591,0,0.71359,0)
o.Position=UDim2.new(0,0,0.5,0)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Text=k
o.Parent=n

local p=Instance.new"Frame"
p.Name="RadioHolderFrame"
p.BorderSizePixel=0
p.BackgroundColor3=Color3.fromRGB(255,255,255)
p.BackgroundTransparency=1
p.AnchorPoint=Vector2.new(1,0.5)
p.Size=UDim2.new(0.16584,0,0.563,0)
p.Position=UDim2.new(1,0,0.5,0)
p.BorderColor3=Color3.fromRGB(0,0,0)
p.Parent=n
local q=Instance.new"UICorner"
q.CornerRadius=UDim.new(0,6)
q.Parent=p
local r=Instance.new"UIStroke"
r.Transparency=i.StrokeTransparency or 0.4
r.Thickness=0.7
r.Color=i.StrokeColor
r.Parent=p

local s=Instance.new"TextButton"
s.Name="RadioButtonElement"
s.BorderSizePixel=0
s.TextTransparency=1
s.AutoButtonColor=false
s.BackgroundColor3=(i and i.PrimaryColor)
s.BackgroundTransparency=1
s.Size=UDim2.new(1,0,1,0)
s.BorderColor3=Color3.fromRGB(0,0,0)
s.Text=""
s.Parent=p
local t=Instance.new"UICorner"
t.CornerRadius=UDim.new(0,6)
t.Parent=s

local u=Instance.new"ImageLabel"
u.Name="BackImage"
u.BorderSizePixel=0
u.BackgroundColor3=Color3.fromRGB(255,255,255)
u.ImageTransparency=1
u.AnchorPoint=Vector2.new(0.5,0.5)
local v=(i and i.Wallpaper)or d
u.Image=v
u:SetAttribute("IsThemeSheen",true)
u.Size=UDim2.new(1,0,1,0)
u.BorderColor3=Color3.fromRGB(0,0,0)
u.BackgroundTransparency=1
u.Position=UDim2.new(0.5,0,0.5,0)
u.Parent=s

u.Visible=not(i and i.WallpaperEnabled==false)
local w=Instance.new"UICorner"
w.CornerRadius=UDim.new(0,6)
w.Parent=u
local x=Instance.new"UIGradient"
x.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(0.324,0.80625),
NumberSequenceKeypoint.new(0.600,0.6875),
NumberSequenceKeypoint.new(0.726,0.55),
NumberSequenceKeypoint.new(0.844,0.36875),
NumberSequenceKeypoint.new(1.000,0)
}
x.Parent=u

local y=Instance.new"ImageLabel"
y.Name="ActivatedImage"
y.ImageTransparency=1
y.AnchorPoint=Vector2.new(0.5,0.5)
y.Image="rbxassetid://8445470984"
y.ImageRectSize=Vector2.new(96,96)
y.ImageRectOffset=Vector2.new(804,904)
y.Size=UDim2.new(0,17,0,17)
y.BackgroundTransparency=1
y.Position=UDim2.new(0.5,0,0.5,0)
y.Parent=s
local z=Instance.new"UIAspectRatioConstraint"
z.DominantAxis=Enum.DominantAxis.Height
z.Parent=y

j.Row=n
j.Label=o
j.Button=s
j.Holder=p
j.HolderStroke=r
j.ActivatedImage=y
j.BackImage=u
j.Gradient=x
j.Group=g
j.IsSelected=false

local A=y.Size
local B=UDim2.new(
A.X.Scale*1.20,
A.X.Offset,
A.Y.Scale*1.20,
A.Y.Offset
)



local function playOn()



c.Play(o,"OnOff",{
TextTransparency=i.PrimaryTextTransparency
})
c.Play(s,"OnOff",{
BackgroundTransparency=0
})
c.Play(y,"OnOff",{
ImageTransparency=0,
Size=A,
ImageColor3=Color3.fromRGB(255,255,255)
})
c.Play(u,"OnOff",{
ImageTransparency=0
})
c.Play(r,"OnOff",{
Transparency=1
})
end



local function playOff()


c.Play(o,"OnOff",{
TextTransparency=i.PrimaryTextTransparency
})
c.Play(s,"OnOff",{
BackgroundTransparency=1
})
c.Play(y,"OnOff",{
ImageTransparency=1,
Size=A,
ImageColor3=Color3.fromRGB(180,180,180)
})
c.Play(u,"OnOff",{
ImageTransparency=1
})
c.Play(r,"OnOff",{
Transparency=i.StrokeTransparency or 0.4
})
end



s.MouseEnter:Connect(function()
if j.IsSelected then
c.Play(y,"HoverIn",{
Size=B,
ImageColor3=Color3.fromRGB(255,255,255)
})
c.Play(r,"HoverIn",{
Transparency=1
})
else
c.Play(r,"HoverIn",{
Transparency=(i.StrokeTransparency or 0.4)*0.5
})
end
end)
s.MouseLeave:Connect(function()
local C=j.IsSelected
local D=C and Color3.fromRGB(255,255,255)or Color3.fromRGB(180,180,180)
c.Play(y,"HoverOut",{
Size=A,
ImageColor3=D
})
c.Play(r,"HoverOut",{
Transparency=C and 1 or(i.StrokeTransparency or 0.4)
})
end)



s.MouseButton1Click:Connect(function()
if j.Group then
j.Group:Select(j)
end
end)



local function startSpin()
x.Rotation=0
c.StartSpin(x,{Rotation=360},"SpinIdle")
end
local function stopSpin()
c.StopSpin(x)
end
startSpin()



function j.SetSelected(C,D)
C.IsSelected=D
C.Button:SetAttribute("IsSelected",D)
if D then
playOn()
if m then
m(C)
end
else
playOff()
end
end
function j.GetSelected(C)
return C.IsSelected
end
function j.SetVisibility(C,D)
n.Visible=D
end
function j.UpdateName(C,D)
o.Text=D
end
function j.EnableSpinning(C,D)
if D then
startSpin()
else
stopSpin()
end
end



if l then
j._default=true
end

function j.ApplyTheme(C,D)
i=b.GetTheme(D)
C._theme=i
o.TextColor3=i.PrimaryTextColor or o.TextColor3
o.TextTransparency=i.PrimaryTextTransparency or o.TextTransparency
s.BackgroundColor3=i.PrimaryColor or s.BackgroundColor3
r.Color=i.StrokeColor or r.Color
r.Transparency=C.IsSelected and 1 or(i.StrokeTransparency or 0.4)
u.Image=i.Wallpaper or d
u.Visible=not(i.WallpaperEnabled==false)
end
b.Register(n,j)
return j
end
return e end function a.m():typeof(__modImpl())local b=a.cache.m if not b then b={c=__modImpl()}a.cache.m=b end return b.c end end do local function __modImpl()













local b=a.f()
local c=a.m()
local d={}
d.__index=d
function d.new(e,f)
f=b.GetTheme(f)
local g=setmetatable({},d)
g.Parent=e
g.Buttons={}
g.Selected=nil
g._hasSelection=false
g._theme=f
return g
end
function d.RadioButton(e,f)
f=f or{}
local g=c.new(e.Parent,e,f,e._theme)
table.insert(e.Buttons,g)


if f.Default then
e:Select(g)
elseif not e._hasSelection and#e.Buttons==1 then
e:Select(g)
end
return g
end
function d.Select(e,f)
if e.Selected==f then return end

if e.Selected then
e.Selected.SetSelected(e.Selected,false)
end
e.Selected=f
f.SetSelected(f,true)
e._hasSelection=true
end
function d.GetSelected(e)
return e.Selected
end
return d end function a.n():typeof(__modImpl())local b=a.cache.n if not b then b={c=__modImpl()}a.cache.n=b end return b.c end end do local function __modImpl()











local b=game:GetService"RunService"

local c={}

function c.attach(d)
local e=Instance.new"UIGradient"
e.Name="FadeGradient"
e:SetAttribute("IsVideoFade",true)
e.Transparency=NumberSequence.new(0)
e.Parent=d
return e
end

function c.set(d,e)
d.Transparency=NumberSequence.new(e)
end

function c.get(d)
local e=d.Transparency.Keypoints
if e and e[1]then
return e[1].Value
end
return 0
end




local d={
Out=function(d)return 1-(1-d)*(1-d)end,
InOut=function(d)
if d<0.5 then
return 2*d*d
end
return 1-((-2*d+2)^2)/2
end,
Linear=function(d)return d end,
}




function c.fade(e,f,g,h,i)
g=g or 0.3
local j=d[h or"Out"]or d.Out
local k=c.get(e)
task.spawn(function()
local l=os.clock()
while true do
if not e.Parent then
break
end
local m=math.clamp((os.clock()-l)/g,0,1)
c.set(e,k+(f-k)*j(m))
if m>=1 then
break
end
b.Heartbeat:Wait()
end
if i then
i()
end
end)
end

return c end function a.o():typeof(__modImpl())local b=a.cache.o if not b then b={c=__modImpl()}a.cache.o=b end return b.c end end do local function __modImpl()















local b=a.o()
local c=a.f()
local d={}
d.__index=d
function d.new(e,f,g)
g=c.GetTheme(g)
f=f or{}
local h=setmetatable({},d)
h._theme=g
local i=f.VideoId or"rbxassetid://5670794788"
local j=f.Loop or true
local k=f.Height or 100

local l=Instance.new"Frame"
l.Name="Video"
l.BorderSizePixel=0
l.BackgroundColor3=(g and g.ComponentBackgroundColor)
l.BackgroundTransparency=(g and g.ComponentBackgroundTransparency)or 0.985
l.Size=UDim2.new(1,0,0,k)
l.Position=UDim2.new(0,0,0.8891,0)
l.AnchorPoint=Vector2.new(0,0)
l.BorderColor3=Color3.fromRGB(0,0,0)
l:SetAttribute("IsComponentContainer",true)
l.Parent=e

local m=Instance.new"UICorner"
m.CornerRadius=UDim.new(0,6)
m.Parent=l

local n=Instance.new"UIStroke"
n.Transparency=(g and g.StrokeTransparency)or 0.95
n.Color=(g and g.StrokeColor)
n.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
n.Parent=l

local o=Instance.new"VideoFrame"
o.Name="VideoFrame"
o.BorderSizePixel=0
o.BackgroundColor3=Color3.fromRGB(255,255,255)
o.BackgroundTransparency=1
o.AnchorPoint=Vector2.new(0.5,0.5)
o.Size=UDim2.new(1,0,1,0)
o.Position=UDim2.new(0.5,0,0.5,0)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Parent=l
local p=Instance.new"UICorner"
p.CornerRadius=UDim.new(0,6)
p.Parent=o



local q=b.attach(o)
h.FadeGradient=q

o.Video=i
o.Looped=j
o:Play()
h.Frame=l
h.VideoFrame=o

h.SetVideo=function(r)
o.Video=r
o:Play()
end
h.Play=function()
o:Play()
end
h.Pause=function()
o:Pause()
end
h.Stop=function()
o:Stop()
end
h.SetLoop=function(r)
o.Looped=r
end
h.SetHeight=function(r)
l.Size=UDim2.new(1,0,0,r)
end
h.SetVisibility=function(r)
l.Visible=r
end

h.SetFade=function(r,s)
b.fade(q,r,s)
end

function h.ApplyTheme(r,s)
g=c.GetTheme(s)
r._theme=g
l.BackgroundColor3=g.ComponentBackgroundColor or l.BackgroundColor3
l.BackgroundTransparency=g.ComponentBackgroundTransparency or l.BackgroundTransparency
n.Color=g.StrokeColor or n.Color
n.Transparency=g.StrokeTransparency or n.Transparency
end
c.Register(l,h)
return h
end
return d end function a.p():typeof(__modImpl())local b=a.cache.p if not b then b={c=__modImpl()}a.cache.p=b end return b.c end end do local function __modImpl()a.a()




















local b=a.f()

local c={}
c.__index=c
c.MAX_ENTRIES=8

local d={
green=Color3.fromRGB(0,255,0),
orange=Color3.fromRGB(255,165,0),
red=Color3.fromRGB(255,0,0),
}


local function colorToString(e)
if typeof(e)=="string"then
local f=string.lower(e)
if d[f]then
local g=d[f]
return string.format("#%02X%02X%02X",math.round(g.R*255),math.round(g.G*255),math.round(g.B*255))
else

return e
end
elseif typeof(e)=="Color3"then
return string.format("#%02X%02X%02X",math.round(e.R*255),math.round(e.G*255),math.round(e.B*255))
else
return"#FFFFFF"
end
end
function c.new(e,f,g)
g=b.GetTheme(g)
f=f or{}
local h=setmetatable({},c)
h._theme=g
local i=f.Name or"Status"
local j=f.Entries or{}

if#j>c.MAX_ENTRIES then
for k=c.MAX_ENTRIES+1,#j do
table.remove(j,k)
end
end

local k=Instance.new"Frame"
k.Name="Status"
k.BorderSizePixel=0
k.BackgroundColor3=(g and g.ComponentBackgroundColor)
k.BackgroundTransparency=(g and g.ComponentBackgroundTransparency)or 0.985
k.AutomaticSize=Enum.AutomaticSize.Y
k.Size=UDim2.new(1,0,0,0)
k.Position=UDim2.new(0,0,0,0)
k.BorderColor3=Color3.fromRGB(0,0,0)
k:SetAttribute("IsComponentContainer",true)
k.Parent=e

local l=Instance.new"UICorner"
l.CornerRadius=UDim.new(0,6)
l.Parent=k

local m=Instance.new"UIStroke"
m.Transparency=(g and g.StrokeTransparency)or 0.95
m.Color=(g and g.StrokeColor)
m.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
m.Parent=k

local n=Instance.new"TextLabel"
n.Name="ElementName"
n.TextWrapped=true
n.BorderSizePixel=0
n.TextSize=14
n.TextXAlignment=Enum.TextXAlignment.Left
n.TextTransparency=(g and g.PrimaryTextTransparency)or 0.3
n.BackgroundColor3=Color3.fromRGB(55,55,55)
n.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
n.TextColor3=(g and g.PrimaryTextColor)
n.BackgroundTransparency=1
n.Size=UDim2.new(0.90908,0,0,20)
n.Position=UDim2.new(0.043,0,0,8)
n.BorderColor3=Color3.fromRGB(0,0,0)
n.Text=i
n.Parent=k

local o=Instance.new"Frame"
o.Name="StatusTextHolder"
o.BorderSizePixel=0
o.BackgroundColor3=Color3.fromRGB(255,255,255)
o.BackgroundTransparency=1
o.AutomaticSize=Enum.AutomaticSize.Y
o.Size=UDim2.new(0.90756,0,0,0)
o.Position=UDim2.new(0.043,0,0,38)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Parent=k

local p=Instance.new"UIListLayout"
p.SortOrder=Enum.SortOrder.LayoutOrder
p.Parent=o

local q=Instance.new"UIPadding"
q.PaddingBottom=UDim.new(0,15)
q.Parent=o

local r={}
for s,t in ipairs(j)do
local u=t[1]or""
local v=t[2]or""
local w=t[3]
local x=Instance.new"TextLabel"
x.Name="StatusText"
x.TextWrapped=true
x.TextTruncate=Enum.TextTruncate.AtEnd
x.BorderSizePixel=0
x.TextSize=13
x.TextXAlignment=Enum.TextXAlignment.Left
x.TextTransparency=(g and g.SecondaryTextTransparency)or 0.45
x.BackgroundColor3=Color3.fromRGB(55,55,55)
x.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
x.TextColor3=(g and g.SecondaryTextColor)
x.BackgroundTransparency=1
x.RichText=true
x.Size=UDim2.new(1,0,0,20)
x.BorderColor3=Color3.fromRGB(0,0,0)
x.Position=UDim2.new(0,0,-0.4,8)
x.Parent=o

local y=colorToString(w)
x.Text=string.format('<font weight="SemiBold">%s: </font><font color="%s">%s</font>',u,y,v)
table.insert(r,x)
end
h.Frame=k
h.Label=n
h.Holder=o
h.StatusLabels=r
h.Entries=j

h.SetVisibility=function(s)
k.Visible=s
end
h.UpdateName=function(s)
n.Text=s
end
h.SetEntries=function(s)

for t,u in ipairs(r)do
u:Destroy()
end
r={}

if#s>c.MAX_ENTRIES then
for t=c.MAX_ENTRIES+1,#s do
table.remove(s,t)
end
end
h.Entries=s

for t,u in ipairs(s)do
local v=u[1]or""
local w=u[2]or""
local x=u[3]
local y=Instance.new"TextLabel"
y.Name="StatusText"
y.TextWrapped=true
y.TextTruncate=Enum.TextTruncate.AtEnd
y.BorderSizePixel=0
y.TextSize=13
y.TextXAlignment=Enum.TextXAlignment.Left
y.TextTransparency=0.45
y.BackgroundColor3=Color3.fromRGB(55,55,55)
y.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
y.TextColor3=Color3.fromRGB(255,255,255)
y.BackgroundTransparency=1
y.RichText=true
y.Size=UDim2.new(1,0,0,20)
y.BorderColor3=Color3.fromRGB(0,0,0)
y.Position=UDim2.new(0,0,-0.4,8)
y.Parent=h.Holder
local z=colorToString(x)
y.Text=string.format('<font weight="SemiBold">%s: </font><font color="%s">%s</font>',v,z,w)
table.insert(r,y)
end
h.StatusLabels=r
end

function h.ApplyTheme(s,t)
g=b.GetTheme(t)
s._theme=g
k.BackgroundColor3=g.ComponentBackgroundColor or k.BackgroundColor3
k.BackgroundTransparency=g.ComponentBackgroundTransparency or k.BackgroundTransparency
n.TextColor3=g.PrimaryTextColor or n.TextColor3
if m then m.Color=g.StrokeColor or m.Color end
for u,v in ipairs(s.StatusLabels or{})do
v.TextColor3=g.SecondaryTextColor or v.TextColor3
v.TextTransparency=g.SecondaryTextTransparency or v.TextTransparency
end
end
b.Register(k,h)
return h
end
return c end function a.q():typeof(__modImpl())local b=a.cache.q if not b then b={c=__modImpl()}a.cache.q=b end return b.c end end do local function __modImpl()





















local b=a.c()
local c=a.f()
local d={}
d.__index=d
local e=0
function d.new(f,g,h,i)
i=c.GetTheme(i)
g=g or{}
local j=setmetatable({},d)
j._theme=i
e=e+1
local k=g.Name or"Dropdown"

j._id=k..e
local l=g.Items or{}
local m=g.Default or{}
local n=g.MaxItemsChoosable or math.huge local o=
g.Placeholder or"Select..."
local p=g.Callback or function()end

local q=Instance.new"Frame"
q.Name=k.."Dropdown"
q.BorderSizePixel=0
q.BackgroundColor3=(i and i.ComponentBackgroundColor)
q.BackgroundTransparency=(i and i.ComponentBackgroundTransparency)or 0.985
q.AnchorPoint=Vector2.new(0.5,0.5)
q.ClipsDescendants=true
q.Size=UDim2.new(1,0,0,45)
q:SetAttribute("IsComponentContainer",true)
q.Parent=f
local r=Instance.new"UICorner"
r.CornerRadius=UDim.new(0,6)
r.Parent=q
local s=Instance.new"UIStroke"
s.Transparency=(i and i.StrokeTransparency)or 0.95
s.Color=(i and i.StrokeColor)
s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
s.Parent=q

local t=Instance.new"TextButton"
t.Name="Interact"
t.BorderSizePixel=0
t.TextSize=14
t.TextColor3=Color3.fromRGB(0,0,0)
t.BackgroundTransparency=1
t.FontFace=Font.new"rbxasset://fonts/families/SourceSansPro.json"
t.Size=UDim2.new(1,0,1,0)
t.Text=""
t.Parent=q

local u=Instance.new"ImageLabel"
u.Name="DropdownImage"
u.BorderSizePixel=0
u.BackgroundTransparency=1
u.ImageTransparency=0.5
u.AnchorPoint=Vector2.new(1,0.5)
u.Image=b["chevron-down"]or"rbxassetid://134243273101015"
u.ImageColor3=(i and i.AccentColor)
u.Size=UDim2.new(0,14,0,14)
u.Position=UDim2.new(0.9,0,0.5,0)
u.Parent=q

local v=Instance.new"TextLabel"
v.Name="ElementName"
v.TextWrapped=true
v.BorderSizePixel=0
v.TextSize=14
v.TextXAlignment=Enum.TextXAlignment.Left
v.TextTransparency=(i and i.PrimaryTextTransparency)or 0.45
v.BackgroundTransparency=1
v.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
v.TextColor3=(i and i.PrimaryTextColor)
v.AnchorPoint=Vector2.new(0,0.5)
v.Size=UDim2.new(0.82748,0,0.71359,0)
v.Position=UDim2.new(0,10,0.5,0)
v.BorderColor3=Color3.fromRGB(0,0,0)
v.Text=k
v.Parent=q

local w={}

for x,y in ipairs(m)do
for z,A in ipairs(l)do
if A.value==y then
table.insert(w,{name=A.name,value=A.value})
break
end
end
end
local x

local function openPopup()
if x and x.IsOpen then

return
end
if not h then
warn"[Dropdown] ShowPopup function not provided"
return
end
local y={}
for z,A in ipairs(w)do
table.insert(y,A.value)
end
x=h(j._id,{
Title=k,
Items=l,
Default=y,
MaxItemsChoosable=n,
Theme=j._theme,
OnConfirm=function(z)
w=z
if p then
p(w)
end
x=nil
end,
OnCancel=function()

x=nil
end,
})
x:Open()
end

t.MouseButton1Click:Connect(function()
openPopup()
end)

q.InputBegan:Connect(function(y)
if y.UserInputType==Enum.UserInputType.MouseButton1 then
openPopup()
end
end)

j.SetItems=function(y)
l=y
w={}
end
j.GetSelected=function()
return w
end
j.SetVisibility=function(y)
q.Visible=y
end
j.UpdateName=function(y)
v.Text=y

end
j.OpenPopup=openPopup

function j.ApplyTheme(y,z)
i=c.GetTheme(z)
y._theme=i
q.BackgroundColor3=i.ComponentBackgroundColor or q.BackgroundColor3
q.BackgroundTransparency=i.ComponentBackgroundTransparency or q.BackgroundTransparency
s.Color=i.StrokeColor or s.Color
s.Transparency=i.StrokeTransparency or s.Transparency
v.TextColor3=i.PrimaryTextColor or v.TextColor3
v.TextTransparency=i.PrimaryTextTransparency or v.TextTransparency
u.ImageColor3=i.AccentColor or u.ImageColor3
end
c.Register(q,j)
return j
end
return d end function a.r():typeof(__modImpl())local b=a.cache.r if not b then b={c=__modImpl()}a.cache.r=b end return b.c end end do local function __modImpl()
















local b=a.f()
local c=a.a()
local d=a.l().FallbackImage
local e={}
e.__index=e

e.SpinningEnabled=true
function e.new(f,g,h)
h=b.GetTheme(h)
g=g or{}
local i=setmetatable({},e)
i._theme=h
local j=g.Name or"Progress Bar"
local k=g.MinValue or 0
local l=g.MaxValue or 100
local m=g.Value or 0
local n=(g.ShowPercentage==nil)and true or g.ShowPercentage
local o=g.ShowFraction or false
local p=g.Color
local q=(g.Animate==nil)and true or g.Animate
local r=(g.SpinningEnabled==nil)and true or g.SpinningEnabled

local s=Instance.new"Frame"
s.Name=j.."ProgressBar"
s.BorderSizePixel=0
s.BackgroundColor3=Color3.fromRGB(31,32,34)
s.BackgroundTransparency=1
s.Size=UDim2.new(1,0,0,45)
s.AnchorPoint=Vector2.new(0.5,0.5)
s.Position=UDim2.new(0.5,0,0.5,0)
s.BorderColor3=Color3.fromRGB(0,0,0)
s.Parent=f
local t=Instance.new"TextLabel"
t.Name="ElementName"
t.TextWrapped=true
t.TextTruncate=Enum.TextTruncate.AtEnd
t.BorderSizePixel=0
t.TextSize=14
t.TextXAlignment=Enum.TextXAlignment.Left
t.TextTransparency=h.PrimaryTextTransparency
t.BackgroundColor3=Color3.fromRGB(55,55,55)
t.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
t.TextColor3=h.PrimaryTextColor
t.BackgroundTransparency=1
t.Size=UDim2.new(0.59985,0,0.31745,0)
t.BorderColor3=Color3.fromRGB(0,0,0)
t.Text=j
t.Position=UDim2.new(0,0,0.12063,0)
t.Parent=s
local u=Instance.new"Frame"
u.Name="ProgressBarHolder"
u.BorderSizePixel=0
u.BackgroundColor3=h.Undercolor
u.AnchorPoint=Vector2.new(0.5,0.5)
u.Size=UDim2.new(1,0,0.07,0)
u.Position=UDim2.new(0.5003,0,0.72338,0)
u.BorderColor3=Color3.fromRGB(255,255,255)
u.Parent=s
local v=Instance.new"UICorner"
v.CornerRadius=UDim.new(0,5)
v.Parent=u
local w=Instance.new"UIShadow"
w.Parent=u
local x=Instance.new"Frame"
x.Name="Visual"
x.BorderSizePixel=0
x.BackgroundColor3=(h and h.PrimaryColor)
x.Size=UDim2.new(0,0,1,0)
x.BorderColor3=Color3.fromRGB(0,0,0)
x.Parent=u
local y=Instance.new"UICorner"
y.CornerRadius=UDim.new(0,6)
y.Parent=x
local z=Instance.new"ImageLabel"
z.Name="BackImage"
z.BorderSizePixel=0
z.BackgroundColor3=Color3.fromRGB(255,255,255)
z.ImageTransparency=0.5
z.AnchorPoint=Vector2.new(0.5,0.5)
local A=(h and h.Wallpaper)or d
z.Image=A
z:SetAttribute("IsThemeSheen",true)
z.Size=UDim2.new(1,0,1,0)
z.BorderColor3=Color3.fromRGB(0,0,0)
z.BackgroundTransparency=1
z.Position=UDim2.new(0.5,0,0.5,0)
z.Parent=x

z.Visible=not(h and h.WallpaperEnabled==false)
local B=Instance.new"UICorner"
B.CornerRadius=UDim.new(0,6)
B.Parent=z
local C=Instance.new"UIGradient"
C.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(0.324,0.80625),
NumberSequenceKeypoint.new(0.600,0.6875),
NumberSequenceKeypoint.new(0.726,0.55),
NumberSequenceKeypoint.new(0.844,0.36875),
NumberSequenceKeypoint.new(1.000,0)
}
C.Parent=z
local D=Instance.new"TextLabel"
D.Name="ProgressBarStats"
D.TextTruncate=Enum.TextTruncate.AtEnd
D.BorderSizePixel=0
D.TextSize=12
D.TextXAlignment=Enum.TextXAlignment.Right
D.TextTransparency=h.PrimaryTextTransparency
D.BackgroundColor3=Color3.fromRGB(55,55,55)
D.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
D.TextColor3=h.PrimaryTextColor
D.BackgroundTransparency=1
D.RichText=true
D.AnchorPoint=Vector2.new(1,0)
D.Size=UDim2.new(0.43,0,0,14)
D.BorderColor3=Color3.fromRGB(0,0,0)
D.Text=""
D.Position=UDim2.new(1,0,0.12063,0)
D.Parent=s

i.Row=s
i.Label=t
i.Holder=u
i.Visual=x
i.BackImage=z
i.Gradient=C
i.Stats=D
i.MinValue=k
i.MaxValue=l
i.Color=p
i.Animate=q
i._spinTween=nil
i._currentValue=nil

local function updateStats(E)
if n and o then
local F=(E-k)/(l-k)*100
D.Text=string.format("<b>%d%%</b> | %d/%d",math.round(F),E,l)
elseif n then
local F=(E-k)/(l-k)*100
D.Text=string.format("<b>%d%%</b>",math.round(F))
elseif o then
D.Text=string.format("%d/%d",E,l)
else
D.Text=""
end
end

function i.SetValue(E,F,G)
F=math.clamp(F,E.MinValue,E.MaxValue)
E._currentValue=F
local H=(F-E.MinValue)/(E.MaxValue-E.MinValue)
local I=UDim2.new(H,0,1,0)
local J=(G==nil)and E.Animate or not G
if J then
c.Play(E.Visual,"Smooth",{Size=I})
else
E.Visual.Size=I
end
updateStats(F)
if g.Callback then
g.Callback(F)
end
end

i:SetValue(m,true)

local function startSpin()
if not e.SpinningEnabled then return end
i.Gradient.Rotation=0
i._spinTween=c.StartSpin(i.Gradient,{Rotation=360},"SpinIdle")
end
local function stopSpin()
c.StopSpin(i.Gradient)
i._spinTween=nil
end
if r and e.SpinningEnabled then
startSpin()
end

i.GetValue=function()
return i._currentValue
end
i.SetMin=function(E)
i.MinValue=E
i:SetValue(i._currentValue,true)
end
i.SetMax=function(E)
i.MaxValue=E
i:SetValue(i._currentValue,true)
end
i.SetColor=function(E)
i.Color=E
i.Visual.BackgroundColor3=E
end
i.SetVisibility=function(E)
i.Row.Visible=E
end
i.UpdateName=function(E)
i.Label.Text=E
end
i.EnableSpinning=function(E)
if E then
startSpin()
else
stopSpin()
end
end

function i.ApplyTheme(E,F)
h=b.GetTheme(F)
E._theme=h
t.TextColor3=h.PrimaryTextColor or t.TextColor3
t.TextTransparency=h.PrimaryTextTransparency or t.TextTransparency
D.TextColor3=h.PrimaryTextColor or D.TextColor3
D.TextTransparency=h.PrimaryTextTransparency or D.TextTransparency
u.BackgroundColor3=h.Undercolor or u.BackgroundColor3

x.BackgroundColor3=E.Color or h.PrimaryColor or x.BackgroundColor3
z.Image=h.Wallpaper or d
z.Visible=not(h.WallpaperEnabled==false)
w.Color=h.ComponentShadowColor or w.Color
end
b.Register(s,i)
return i
end
return e end function a.s():typeof(__modImpl())local b=a.cache.s if not b then b={c=__modImpl()}a.cache.s=b end return b.c end end do local function __modImpl()

















local b=a.a()
local c=a.c()
local d=a.f()
local e=a.e()
local f={}
f.__index=f
function f.new(g,h,i)
i=d.GetTheme(i)
h=h or{}
local j=setmetatable({},f)
j._theme=i
local k=h.Name or"Stepper"
local l=h.Min or 0
local m=h.Max or 100
local n=h.Default or 50
local o=h.Step or 1
local p=h.Callback or function()end
local q=(h.Integer==nil)and true or h.Integer

local r=Instance.new"Frame"
r.Name=k.."Stepper"
r.BorderSizePixel=0
r.BackgroundColor3=Color3.fromRGB(31,32,34)
r.BackgroundTransparency=1
r.Size=UDim2.new(1,0,0,45)
r.AnchorPoint=Vector2.new(0.5,0.5)
r.Position=UDim2.new(0.5,0,0.5,0)
r.BorderColor3=Color3.fromRGB(0,0,0)
r.Parent=g

local s=Instance.new"TextLabel"
s.Name="ElementName"
s.TextWrapped=true
s.BorderSizePixel=0
s.TextSize=14
s.TextXAlignment=Enum.TextXAlignment.Left
s.TextTransparency=(i and i.PrimaryTextTransparency)or 0.45
s.BackgroundColor3=Color3.fromRGB(55,55,55)
s.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
s.TextColor3=(i and i.PrimaryTextColor)
s.BackgroundTransparency=1
s.AnchorPoint=Vector2.new(0,0.5)
s.Size=UDim2.new(0.48591,0,0.71359,0)
s.BorderColor3=Color3.fromRGB(0,0,0)
s.Text=k
s.Position=UDim2.new(0,0,0.5,0)
s.Parent=r

local t=Instance.new"TextBox"
t.Name="StepperInputBox"
t.PlaceholderColor3=Color3.fromRGB(100,100,100)
t.BorderSizePixel=0
t.TextWrapped=true
t.TextTransparency=(i and i.SecondaryTextTransparency)or 0.4
t.TextSize=13
t.TextColor3=(i and i.SecondaryTextColor)
t.BackgroundColor3=i.InputBackgroundColor
t.BackgroundTransparency=i.InputBackgroundTransparency
t:SetAttribute("IsInputBackground",true)
t.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
t.AnchorPoint=Vector2.new(1,0.5)
t.ClearTextOnFocus=false
t.PlaceholderText=tostring(n)
t.Size=UDim2.new(0.24189,0,0.563,0)
t.Position=UDim2.new(0.89655,0,0.5,0)
t.BorderColor3=Color3.fromRGB(0,0,0)
t.Text=""
t.Parent=r
local u=Instance.new"UICorner"
u.CornerRadius=UDim.new(0,6)
u.Parent=t
local v=Instance.new"UIStroke"
v.Transparency=(i and i.StrokeTransparency)or 0.95
v.Thickness=0.7
v.Color=(i and i.StrokeColor)
v.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
v.Parent=t

local w=Instance.new"ImageButton"
w.Name="StepUp"
w.BorderSizePixel=0
w.ImageTransparency=0.6
w.BackgroundTransparency=1
w.BackgroundColor3=(i and i.AccentColor)
w.AnchorPoint=Vector2.new(1,0.5)
w.Image=c["chevron-up"]
w.ImageColor3=(i and i.AccentColor)
w.Size=UDim2.new(0,15,0,15)
w.BorderColor3=Color3.fromRGB(0,0,0)
w.Position=UDim2.new(1,0,0.28,0)
w.Parent=r
local x=Instance.new"UIAspectRatioConstraint"
x.Parent=w
local y=Instance.new"UICorner"
y.CornerRadius=UDim.new(0,4)
y.Parent=w
local z=Instance.new"UIStroke"
z.Transparency=0.95
z.Color=i.StrokeColor
z.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
z.Parent=w

local A=Instance.new"ImageButton"
A.Name="StepDown"
A.BorderSizePixel=0
A.ImageTransparency=0.6
A.BackgroundTransparency=1
A.BackgroundColor3=(i and i.AccentColor)
A.AnchorPoint=Vector2.new(1,0.5)
A.Image=c["chevron-down"]
A.ImageColor3=(i and i.AccentColor)
A.Size=UDim2.new(0,15,0,15)
A.BorderColor3=Color3.fromRGB(0,0,0)
A.Position=UDim2.new(1,0,0.7,0)
A.Parent=r
local B=Instance.new"UIAspectRatioConstraint"
B.Parent=A
local C=Instance.new"UICorner"
C.CornerRadius=UDim.new(0,4)
C.Parent=A
local D=Instance.new"UIStroke"
D.Transparency=0.95
D.Color=i.StrokeColor
D.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
D.Parent=A

j.Row=r
j.Label=s
j.InputBox=t
j.InputStroke=v
j.StepUp=w
j.StepDown=A
j.Min=l
j.Max=m
j.Step=o
j.IsInteger=q
j.Callback=p
j._currentValue=math.clamp(n,l,m)

local function updateDisplay(E)
local F=q and math.round(E)or E
t.Text=tostring(F)
t.PlaceholderText=tostring(F)
end

function j.SetValue(E,F,G)
local H=E._currentValue
local I=math.clamp(F,E.Min,E.Max)
if E.IsInteger then
I=math.round(I)
end
if I==H then
return
end
E._currentValue=I
updateDisplay(I)
if not G then
E.Callback(I)
end
end

local function stepValue(E)
local F=j._currentValue+E*j.Step
j:SetValue(F,false)
end

local function flashButton(E)
b.CancelAll(E)
b.Play(E,"Fast",{BackgroundTransparency=0})
task.wait(0.2)
b.Play(E,"Fast",{BackgroundTransparency=1})
end
w.MouseButton1Click:Connect(function()
stepValue(1)
flashButton(w)
end)
A.MouseButton1Click:Connect(function()
stepValue(-1)
flashButton(A)
end)

t.FocusLost:Connect(function()
local E=t.Text
local F=tonumber(E)
if F then
j:SetValue(F,false)
else
updateDisplay(j._currentValue)
end
end)

local function setStrokeBright(E)
if not j.InputStroke then return end
local F=e.theme or i
local G=E and 0.3 or(F and F.StrokeTransparency or 0.95)
local H=F.StrokeColor
b.Play(j.InputStroke,"Fast",{
Transparency=G,
Color=H
})
end
t.MouseEnter:Connect(function()
setStrokeBright(true)
end)
t.MouseLeave:Connect(function()
if not t:IsFocused()then
setStrokeBright(false)
end
end)
t.Focused:Connect(function()
setStrokeBright(true)
end)
t.FocusLost:Connect(function()
setStrokeBright(false)
end)

local function onButtonHover(E,F)
local G=F and 0.3 or 0.6
b.Play(E,"Fast",{ImageTransparency=G})
end
w.MouseEnter:Connect(function()onButtonHover(w,true)end)
w.MouseLeave:Connect(function()onButtonHover(w,false)end)
A.MouseEnter:Connect(function()onButtonHover(A,true)end)
A.MouseLeave:Connect(function()onButtonHover(A,false)end)

updateDisplay(j._currentValue)

j.GetValue=function()
return j._currentValue
end
j.SetMin=function(E)
j.Min=E
j:SetValue(j._currentValue,true)
end
j.SetMax=function(E)
j.Max=E
j:SetValue(j._currentValue,true)
end
j.SetStep=function(E)
j.Step=E
end
j.SetVisibility=function(E)
r.Visible=E
end
j.UpdateName=function(E)
s.Text=E
end

function j.ApplyTheme(E,F)
i=d.GetTheme(F)
E._theme=i
s.TextColor3=i.PrimaryTextColor or s.TextColor3
s.TextTransparency=i.PrimaryTextTransparency or s.TextTransparency
t.TextColor3=i.SecondaryTextColor or t.TextColor3
t.TextTransparency=i.SecondaryTextTransparency or t.TextTransparency
t.BackgroundColor3=i.InputBackgroundColor or t.BackgroundColor3
t.BackgroundTransparency=i.InputBackgroundTransparency or t.BackgroundTransparency
v.Color=i.StrokeColor or v.Color
v.Transparency=i.StrokeTransparency or v.Transparency
w.ImageColor3=i.AccentColor or w.ImageColor3
w.BackgroundColor3=i.AccentColor or w.BackgroundColor3
A.ImageColor3=i.AccentColor or A.ImageColor3
A.BackgroundColor3=i.AccentColor or A.BackgroundColor3
z.Color=i.StrokeColor or z.Color
D.Color=i.StrokeColor or D.Color
end
d.Register(r,j)
return j
end
return f end function a.t():typeof(__modImpl())local b=a.cache.t if not b then b={c=__modImpl()}a.cache.t=b end return b.c end end do local function __modImpl()













local b=a.f()
local c=a.a()
local d=a.c()
local e={}
e.__index=e
function e.new(f,g,h)
h=b.GetTheme(h)
g=g or{}
local i=setmetatable({},e)
i._theme=h
local j=g.Name or"Button"
local k=g.Callback or function()end
local l=d["fingerprint-pattern"]

local m=Instance.new"TextButton"
m.Name=j.." [Button]"
m.BorderSizePixel=0
m.BackgroundColor3=(h and h.ComponentBackgroundColor)
m.BackgroundTransparency=(h and h.ComponentBackgroundTransparency)or 0.985
m.Size=UDim2.new(1,0,0,45)
m.AnchorPoint=Vector2.new(0.5,0.5)
m.Position=UDim2.new(0.5,0,0.5,0)
m.Text=""
m.TextTransparency=1
m.AutoButtonColor=false
m:SetAttribute("IsComponentContainer",true)
m.Parent=f

local n=Instance.new"UICorner"
n.Name="UICorner"
n.CornerRadius=UDim.new(0,6)
n.Parent=m

local o=Instance.new"TextLabel"
o.Name="ElementName"
o.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
o.Text=j
o.TextColor3=(h and h.PrimaryTextColor)
o.TextSize=14
o.TextTransparency=(h and h.PrimaryTextTransparency)or 0.45
o.TextTruncate=Enum.TextTruncate.AtEnd
o.TextWrapped=true
o.TextXAlignment=Enum.TextXAlignment.Left
o.AnchorPoint=Vector2.new(0,0.5)
o.BackgroundTransparency=1
o.Size=UDim2.new(0.486,0,0.714,0)
o.Position=UDim2.new(0,10,0.5,0)
o.ZIndex=2
o.Parent=m

local p=Instance.new"Frame"
p.Name="ButtonColor"
p.BorderSizePixel=0
p.BackgroundColor3=(h and h.PrimaryColor)
p.BackgroundTransparency=1
p.AnchorPoint=Vector2.new(0.5,0.5)
p.Size=UDim2.new(1,0,1,0)
p.Position=UDim2.new(0.5,0,0.5,0)
p.Parent=m
local q=Instance.new"UICorner"
q.CornerRadius=UDim.new(0,6)
q.Parent=p

local r=Instance.new"ImageLabel"
r.Name="Fingerprint"
r.BorderSizePixel=0
r.BackgroundTransparency=1
r.ImageTransparency=0.5
r.AnchorPoint=Vector2.new(0.5,0.5)
r.Image=l
r.ImageColor3=(h and h.AccentColor)
r.Size=UDim2.new(0,24,0,24)
r.Position=UDim2.new(1,-30,0.5,0)
r.Parent=m
local s=Instance.new"UIAspectRatioConstraint"
s.DominantAxis=Enum.DominantAxis.Height
s.Parent=r

local t=Instance.new"UIStroke"
t.Transparency=(h and h.StrokeTransparency)or 0.95
t.Thickness=0.7
t.Color=(h and h.StrokeColor)
t.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
t.Parent=m

i.Row=m
i.Label=o
i.ButtonColor=p
i.Fingerprint=r
i.Callback=k
i._clicking=false

local u=0.5
local v=1

local w=false

m.MouseEnter:Connect(function()
w=true
c.CancelAll(r)
c.Play(r,"Smooth",{
ImageTransparency=0.2
})
end)
m.MouseLeave:Connect(function()
w=false
c.CancelAll(r)
c.Play(r,"Smooth",{
ImageTransparency=u
})
end)

local function performClick()

c.CancelAll(p)
c.CancelAll(r)

c.Play(p,"Click",{
BackgroundTransparency=0.15
})
c.Play(r,"Click",{
ImageTransparency=0.1
})


task.delay(0.12,function()
if not m.Parent then
return
end
c.Play(p,"Release",{
BackgroundTransparency=v
})
c.Play(r,"Smooth",{
ImageTransparency=w and 0.2 or u
})
end)

i.Callback()
end
m.MouseButton1Click:Connect(performClick)

i.SetVisibility=function(x)
m.Visible=x
end
i.UpdateName=function(x)
o.Text=x
end
i.Click=function()
performClick()
end

function i.ApplyTheme(x,y)
h=b.GetTheme(y)
x._theme=h
m.BackgroundColor3=h.ComponentBackgroundColor or m.BackgroundColor3
o.TextColor3=h.PrimaryTextColor or o.TextColor3
p.BackgroundColor3=h.PrimaryColor or p.BackgroundColor3
r.ImageColor3=h.AccentColor or r.ImageColor3
t.Color=h.StrokeColor or t.Color
t.Transparency=h.StrokeTransparency or t.Transparency
end
b.Register(m,i)
return i
end
return e end function a.u():typeof(__modImpl())local b=a.cache.u if not b then b={c=__modImpl()}a.cache.u=b end return b.c end end do local function __modImpl()
















local b=a.f()
local c={}
c.__index=c

local function getFontWeight(d)
if typeof(d)=="EnumItem"then return d end
local e={
Regular=Enum.FontWeight.Regular,
Medium=Enum.FontWeight.Medium,
SemiBold=Enum.FontWeight.SemiBold,
Bold=Enum.FontWeight.Bold,
Heavy=Enum.FontWeight.Heavy,
ExtraBold=Enum.FontWeight.ExtraBold,
}
return e[d]or Enum.FontWeight.Regular
end
function c.new(d,e,f)
f=b.GetTheme(f)
e=e or{}
local g=setmetatable({},c)
g._theme=f
local h=e.Text or e.Name or"Label"
local i=(e.ShowContainer==nil)and true or e.ShowContainer
local j=(e.ShowStroke==nil)and true or e.ShowStroke
local k=getFontWeight(e.FontWeight or"Regular")

local l=Instance.new"Frame"
l.Name=h.." [Label]"
l.BorderSizePixel=0
l.BackgroundColor3=(f and f.ComponentBackgroundColor)
l.BackgroundTransparency=(f and f.ComponentBackgroundTransparency)or(i and 0.985 or 1)
l.AutomaticSize=Enum.AutomaticSize.Y
l.Size=UDim2.new(1,0,0,0)
l:SetAttribute("IsComponentContainer",true)
l.Parent=d

local m=Instance.new"UICorner"
m.CornerRadius=UDim.new(0,6)
m.Parent=l


local n=Instance.new"UIStroke"
if j then
n.Transparency=(f and f.StrokeTransparency)or 0.95
else
n.Transparency=1
n:SetAttribute("HiddenStroke",true)
end
n.Color=(f and f.StrokeColor)
n.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
n.Parent=l

local o=Instance.new"UIPadding"
o.PaddingTop=UDim.new(0,15)
o.PaddingBottom=UDim.new(0,15)
o.PaddingLeft=UDim.new(0,11)
o.PaddingRight=UDim.new(0,11)
o.Parent=l

local p=Instance.new"TextLabel"
p.Name="ElementName"
p.FontFace=Font.new("rbxassetid://12187365364",k,Enum.FontStyle.Normal)
p.Text=h
p.RichText=true
p.TextColor3=(f and f.PrimaryTextColor)
p.TextSize=14
p.AnchorPoint=Vector2.new(0,0.5)
p.Position=UDim2.new(0,0,0.5,0)
p.TextTransparency=(f and f.PrimaryTextTransparency)or 0.45
p.TextTruncate=Enum.TextTruncate.AtEnd
p.TextWrapped=true
p.TextXAlignment=Enum.TextXAlignment.Left
p.BackgroundTransparency=1
p.Size=UDim2.new(1,0,0,0)
p.AutomaticSize=Enum.AutomaticSize.Y
p.Parent=l

g.Container=l
g.Corner=m
g.Stroke=n
g.Padding=o
g.Label=p
g._showContainer=i
g._showStroke=j
g._fontWeight=k

g.SetVisibility=function(q)
l.Visible=q
end
g.SetText=function(q)
p.Text=q
end
g.SetTextTransparency=function(q)
p.TextTransparency=q
end
g.SetFontWeight=function(q)
local r=getFontWeight(q)
g._fontWeight=r
p.FontFace=Font.new("rbxassetid://12187365364",r,Enum.FontStyle.Normal)
end
g.SetShowContainer=function(q)
g._showContainer=q
l.BackgroundTransparency=q and 0.985 or 1


end
g.SetShowStroke=function(q)
g._showStroke=q
n:SetAttribute("HiddenStroke",not q)
n.Transparency=q and((g._theme and g._theme.StrokeTransparency)or 0.95)or 1
end

function g.ApplyTheme(q,r)
f=b.GetTheme(r)
q._theme=f
l.BackgroundColor3=f.ComponentBackgroundColor or l.BackgroundColor3
if q._showContainer then
l.BackgroundTransparency=f.ComponentBackgroundTransparency or l.BackgroundTransparency
else
l.BackgroundTransparency=1
end
p.TextColor3=f.PrimaryTextColor or p.TextColor3
p.TextTransparency=f.PrimaryTextTransparency or p.TextTransparency
n.Color=f.StrokeColor or n.Color
if q._showStroke then
n.Transparency=f.StrokeTransparency or 0.95
else
n.Transparency=1
end
end
b.Register(l,g)
return g
end
return c end function a.v():typeof(__modImpl())local b=a.cache.v if not b then b={c=__modImpl()}a.cache.v=b end return b.c end end do local function __modImpl()













local b=a.f()
local c={}
c.__index=c
function c.new(d,e,f)
f=b.GetTheme(f)
e=e or{}
local g=setmetatable({},c)
g._theme=f
local h=e.Title or e.Name or"Paragraph"
local i=e.Description or e.Text or""

local j=Instance.new"Frame"
j.Name=h.." [Paragraph]"
j.BorderSizePixel=0
j.BackgroundColor3=(f and f.ComponentBackgroundColor)
j.BackgroundTransparency=(f and f.ComponentBackgroundTransparency)or 0.985
j.AutomaticSize=Enum.AutomaticSize.Y
j.Size=UDim2.new(1,0,0,0)
j:SetAttribute("IsComponentContainer",true)
j.Parent=d

local k=Instance.new"UICorner"
k.CornerRadius=UDim.new(0,6)
k.Parent=j

local l=Instance.new"UIStroke"
l.Transparency=(f and f.StrokeTransparency)or 0.95
l.Color=(f and f.StrokeColor)
l.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
l.Parent=j

local m=Instance.new"TextLabel"
m.Name="ElementName"
m.TextWrapped=true
m.BorderSizePixel=0
m.TextSize=15
m.TextXAlignment=Enum.TextXAlignment.Left
m.TextTransparency=(f and f.PrimaryTextTransparency)or 0.3
m.BackgroundColor3=Color3.fromRGB(55,55,55)
m.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
m.TextColor3=(f and f.PrimaryTextColor)
m.BackgroundTransparency=1
m.Size=UDim2.new(0.909,0,0,20)
m.Text=h
m.Position=UDim2.new(0.043,0,0,8)
m.Parent=j

local n=Instance.new"TextLabel"
n.Name="LabelDescription"
n.TextWrapped=true
n.BorderSizePixel=0
n.TextSize=14
n.TextXAlignment=Enum.TextXAlignment.Left
n.TextTransparency=(f and f.SecondaryTextTransparency)or 0.45
n.BackgroundColor3=Color3.fromRGB(55,55,55)
n.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
n.TextColor3=(f and f.SecondaryTextColor)
n.BackgroundTransparency=1
n.Size=UDim2.new(0.91,0,0,0)
n.AutomaticSize=Enum.AutomaticSize.Y
n.Text=i
n.Position=UDim2.new(0,11,0,38)
n.Parent=j

local o=Instance.new"UIPadding"
o.PaddingBottom=UDim.new(0,15)
o.Parent=n

g.Container=j
g.TitleLabel=m
g.DescLabel=n

g.SetVisibility=function(p)
j.Visible=p
end
g.SetTitle=function(p)
m.Text=p
j.Name=p.." [Paragraph]"
end
g.SetDescription=function(p)
n.Text=p
end

function g.ApplyTheme(p,q)
f=b.GetTheme(q)
p._theme=f
j.BackgroundColor3=f.ComponentBackgroundColor or j.BackgroundColor3
j.BackgroundTransparency=f.ComponentBackgroundTransparency or j.BackgroundTransparency
l.Color=f.StrokeColor or l.Color
l.Transparency=f.StrokeTransparency or l.Transparency
m.TextColor3=f.PrimaryTextColor or m.TextColor3
m.TextTransparency=f.PrimaryTextTransparency or m.TextTransparency
n.TextColor3=f.SecondaryTextColor or n.TextColor3
n.TextTransparency=f.SecondaryTextTransparency or n.TextTransparency
end
b.Register(j,g)
return g
end
return c end function a.w():typeof(__modImpl())local b=a.cache.w if not b then b={c=__modImpl()}a.cache.w=b end return b.c end end do local function __modImpl()















local b=a.a()
local c=a.c()
local d=a.f()
local e={}
e.__index=e



function e.new(f,g,h,i)
i=d.GetTheme(i)
g=g or{}
local j=setmetatable({},e)
j._theme=i
local k=g.Name or"Color"
local l=g.Default or Color3.fromRGB(255,0,0)
local m=g.Callback or function()end

local n=Instance.new"TextButton"
n.Name=k.." [ColorPicker]"
n.BorderSizePixel=0
n.BackgroundColor3=Color3.fromRGB(31,32,34)
n.BackgroundTransparency=1
n.Size=UDim2.new(1,0,0,45)
n.AnchorPoint=Vector2.new(0.5,0.5)
n.Position=UDim2.new(0.5,0,0.5,0)
n.Text=""
n.TextTransparency=1
n.AutoButtonColor=false
n.Parent=f

local o=Instance.new"TextLabel"
o.Name="ElementName"
o.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
o.Text=k
o.TextColor3=(i and i.PrimaryTextColor)
o.TextSize=14
o.TextTransparency=(i and i.PrimaryTextTransparency)or 0.45
o.TextTruncate=Enum.TextTruncate.AtEnd
o.TextWrapped=true
o.TextXAlignment=Enum.TextXAlignment.Left
o.AnchorPoint=Vector2.new(0,0.5)
o.BackgroundTransparency=1
o.Size=UDim2.new(0.486,0,0.714,0)
o.Position=UDim2.new(0,0,0.5,0)
o.Parent=n

local p=Instance.new"Frame"
p.Name="HeaderBar"
p.BorderSizePixel=0
p.BackgroundTransparency=1
p.AnchorPoint=Vector2.new(0.5,0.5)
p.Size=UDim2.new(1,0,0,32)
p.Position=UDim2.new(0.5,0,0.5,0)
p.Parent=n

local q=Instance.new"TextButton"
q.Name="ColorDisplay"
q.BorderSizePixel=0
q.AutoButtonColor=false
q.BackgroundColor3=l
q.AnchorPoint=Vector2.new(1,0.5)
q.Size=UDim2.new(0,24,0,24)
q.Position=UDim2.new(1,0,0.5,0)
q.Text=""
q.Parent=p
local r=Instance.new"UICorner"
r.CornerRadius=UDim.new(0,6)
r.Parent=q
local s=Instance.new"UIStroke"
s.Transparency=0.8
s.Color=Color3.fromRGB(255,255,255)
s.Parent=q
local t=Instance.new"UIShadow"
t.Color=l
t.Transparency=0.5
t.BlurRadius=UDim.new(0,20)
t.Parent=q

local u=Instance.new"ImageLabel"
u.Name="Chevron"
u.BorderSizePixel=0
u.BackgroundTransparency=1
u.ImageTransparency=0.5
u.ImageColor3=(i and i.AccentColor)
u.AnchorPoint=Vector2.new(1,0.5)
u.Image=c.paintbrush
u.Size=UDim2.new(0,20,0,20)
u.Position=UDim2.new(1,-40,0.5,0)
u.Rotation=-90
u.Parent=p

j.Row=n
j.Label=o
j.HeaderBar=p
j.Display=q
j.DisplayShadow=t
j.Chevron=u
j._currentColor=l
j._isOpen=false
j.Callback=m
j.ShowPopup=h
j._popupId=k.."ColorPicker"

local function updateDisplay(v)
q.BackgroundColor3=v
t.Color=v
end

function j.SetColor(v,w,x)
if typeof(w)~="Color3"then return end
if w==v._currentColor then return end
v._currentColor=w
updateDisplay(w)
if not x then
v.Callback(w)
end
end
function j.GetColor(v)
return v._currentColor
end

function j.TogglePopup(v)
v._isOpen=not v._isOpen
local w=v._isOpen and 0 or-90
b.Play(v.Chevron,"Smooth",{Rotation=w})
if v._isOpen and v.ShowPopup then

v._popup=v.ShowPopup(v._popupId,{
Title=v.Label.Text,
CurrentColor=v._currentColor,
OnConfirm=function(x)
v:SetColor(x,false)
v:ClosePopup()
end,
OnCancel=function()
v:ClosePopup()
end,
})
elseif v._popup and v._popup.Close then


v._popup:Close()
end
end
function j.ClosePopup(v)
v._isOpen=false
b.Play(v.Chevron,"Smooth",{Rotation=-90})


end

function j.SetVisibility(v,w)
n.Visible=w
end
function j.UpdateName(v,w)
o.Text=w
v._popupId=w.."ColorPicker"
end

n.MouseButton1Click:Connect(function()
j:TogglePopup()
end)



function j.ApplyTheme(v,w)
i=d.GetTheme(w)
v._theme=i
o.TextColor3=i.PrimaryTextColor or o.TextColor3
o.TextTransparency=i.PrimaryTextTransparency or o.TextTransparency
u.ImageColor3=i.AccentColor or u.ImageColor3
end
d.Register(n,j)

updateDisplay(l)
return j
end
return e end function a.x():typeof(__modImpl())local b=a.cache.x if not b then b={c=__modImpl()}a.cache.x=b end return b.c end end do local function __modImpl()a.a()













local b=a.g()
local c=a.h()
local d=a.i()
local e=a.j()
local f=a.k()
local g=a.n()
local h=a.p()
local i=a.q()
local j=a.r()
local k=a.s()
local l=a.t()
local m=a.u()
local n=a.v()
local o=a.w()
local p=a.x()
local q=a.f()

local r={}
r.__index=r
function r.new(s,t,u)
u=q.GetTheme(u)
t=t or{}

if not u or type(u)~="table"then
u=q.GetTheme(nil)
end
local v=setmetatable({},r)
v._theme=u

local w=Instance.new"Frame"
w.Name=t.Name or"Section"
w.BorderSizePixel=0
w.BackgroundColor3=u.SectionBackgroundColor
w.BackgroundTransparency=u.SectionBackgroundTransparency
w.ClipsDescendants=true
w.AutomaticSize=Enum.AutomaticSize.Y
w.Size=UDim2.new(1,0,0,0)
w.BorderColor3=Color3.fromRGB(0,0,0)
w:SetAttribute("IsSection",true)
w.Parent=s
local x=Instance.new"UICorner"
x.Name="SectionUICorner"
x.Parent=w
local y=Instance.new"UIStroke"
y.Name="SectionUIStroke"
y.Transparency=u.StrokeTransparency
y.Color=u.StrokeColor
y.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
y.Parent=w
local z=Instance.new"UIListLayout"
z.Name="SectionUIListLayout"
z.HorizontalAlignment=Enum.HorizontalAlignment.Center
z.Padding=UDim.new(0,10)
z.VerticalAlignment=Enum.VerticalAlignment.Center
z.SortOrder=Enum.SortOrder.LayoutOrder
z.Parent=w
local A=Instance.new"UIPadding"
A.Name="SectionUIPadding"
A.PaddingTop=UDim.new(0,20)
A.PaddingRight=UDim.new(0,15)
A.PaddingLeft=UDim.new(0,15)
A.PaddingBottom=UDim.new(0,20)
A.Parent=w
v.Frame=w
v.Layout=z
v.Padding=A
v.Parent=s


q.Register(w,v)
return v
end













function r.Toggle(s,t,u)
return b.new(s.Frame,t,u,s._theme)
end







function r.Slider(s,t)
return c.new(s.Frame,t,s._theme)
end
function r.Keybind(s,t)
return d.new(s.Frame,t,s._theme)
end
function r.Button(s,t)
return m.new(s.Frame,t,s._theme)
end
function r.Label(s,t)
return n.new(s.Frame,t,s._theme)
end
function r.Divider(s,t)
return e.new(s.Frame,t,s._theme)
end
function r.TextInput(s,t)
return f.new(s.Frame,t,s._theme)
end
function r.RadioButtonGroup(s)
return g.new(s.Frame,s._theme)
end
function r.Video(s,t)
return h.new(s.Frame,t,s._theme)
end
function r.Status(s,t)
return i.new(s.Frame,t,s._theme)
end
function r.Dropdown(s,t,u)
return j.new(s.Frame,t,u,s._theme)
end
function r.ProgressBar(s,t)
return k.new(s.Frame,t,s._theme)
end
function r.Stepper(s,t)
return l.new(s.Frame,t,s._theme)
end
function r.Paragraph(s,t)
return o.new(s.Frame,t,s._theme)
end
function r.ColorPicker(s,t,u)
return p.new(s.Frame,t,u,s._theme)
end




function r.ApplyTheme(s,t)
local u=q.GetTheme(t)
s._theme=u
s.Frame.BackgroundColor3=u.SectionBackgroundColor or s.Frame.BackgroundColor3
if u.SectionBackgroundTransparency~=nil then
s.Frame.BackgroundTransparency=u.SectionBackgroundTransparency
end
local v=s.Frame:FindFirstChild"SectionUIStroke"
if v then
v.Color=u.StrokeColor or v.Color
v.Transparency=u.SectionStrokeTransparency or u.StrokeTransparency or v.Transparency
end
end


return r end function a.y():typeof(__modImpl())local b=a.cache.y if not b then b={c=__modImpl()}a.cache.y=b end return b.c end end do local function __modImpl()













local b={}

local function colorToHex(c)
local d=math.floor(c.R*255+0.5)
local e=math.floor(c.G*255+0.5)
local f=math.floor(c.B*255+0.5)
return string.format("#%02X%02X%02X",d,e,f)
end

local function escapeRich(c)
c=string.gsub(c,"&","&amp;")
c=string.gsub(c,"<","&lt;")
c=string.gsub(c,">","&gt;")
return c
end

local function buildHighlight(c,d,e,f)
local g={}
local h=1
while true do
local i,j=string.find(d,e,h,true)
if not i then
table.insert(g,escapeRich(string.sub(c,h)))
break
end
table.insert(g,escapeRich(string.sub(c,h,i-1)))
table.insert(g,'<font color="'..f..'">'..escapeRich(string.sub(c,i,j)).."</font>")
h=j+1
end
return table.concat(g)
end




function b.Highlight(c,d,e)
if not c or c==""then return nil end
local f=string.lower(d or"")
if f==""then return nil end
local g=string.lower(c)
if not string.find(g,f,1,true)then return nil end
local h=colorToHex(e or Color3.fromRGB(96,165,250))
return buildHighlight(c,g,f,h)
end

local function nearestSection(c)
local d=c.Parent
while d do
if d:GetAttribute"IsSection"then
return d
end
d=d.Parent
end
return nil
end

function b.Apply(c,d,e)
if not c then return end
d=string.lower(d or"")
if d==""then
b.Clear(c)
return
end
local f=(e and e.AccentColor)or Color3.fromRGB(96,165,250)
local g=colorToHex(f)

local h={}
local i={}
for j,k in ipairs(c:GetDescendants())do
if k:GetAttribute"IsSection"then
h[k]=false
elseif k:IsA"TextLabel"and k.Name=="ElementName"then
table.insert(i,k)
end
end

for j,k in ipairs(i)do
local l=k:GetAttribute"SearchBaseText"
if l==nil then
l=k.Text
k:SetAttribute("SearchBaseText",l)
k:SetAttribute("SearchBaseRich",k.RichText)
end
local m=string.lower(l)
if string.find(m,d,1,true)then
local n=nearestSection(k)
if n and h[n]~=nil then
h[n]=true
end
k.RichText=true
k.Text=buildHighlight(l,m,d,g)
else
k.Text=l
local n=k:GetAttribute"SearchBaseRich"
if n~=nil then
k.RichText=n
end
end
end

for j,k in pairs(h)do
j.Visible=k
end
end

function b.Clear(c)
if not c then return end
for d,e in ipairs(c:GetDescendants())do
if e:GetAttribute"IsSection"then
e.Visible=true
elseif e:IsA"TextLabel"and e.Name=="ElementName"then
local f=e:GetAttribute"SearchBaseText"
if f~=nil then
e.Text=f
local g=e:GetAttribute"SearchBaseRich"
if g~=nil then e.RichText=g end
e:SetAttribute("SearchBaseText",nil)
e:SetAttribute("SearchBaseRich",nil)
end
end
end
end

return b end function a.z():typeof(__modImpl())local b=a.cache.z if not b then b={c=__modImpl()}a.cache.z=b end return b.c end end do local function __modImpl()
















local b=a.a()
local c=a.y()
local d=a.l().FallbackImage
local e=a.f()
local f=a.z()
local g=a.o()
local h={}
h.__index=h

local i={}
i.__index=i
function i.Section(j,k)
k=k or{}
local l=k.Side or"Left"
local m=l=="Left"and j.ColumnLeft or j.ColumnRight
return c.new(m,k,j._theme)
end
function h.new(j,k)
k=e.GetTheme(k)
local l=setmetatable({},h)
l.Window=j
l._theme=k or{}
l.Tabs={}
l.ActiveTab=nil
l._fadeCaches={}
l._transitioning=false
l._spinHandles={}




e.Register(l.Window.TabList,l)
return l
end







function h._captureCache(j,k)
local l={}
local function scan(m)

if m:IsA"UIGradient"and m:GetAttribute"IsVideoFade"then
table.insert(l,{instance=m,isVideo=true,base=g.get(m)})
return
end
local n={}
local function addProp(o)
local p,q=pcall(function()return m[o]end)
if p and q~=nil then
table.insert(n,{o,q})
end
end
if m:IsA"GuiObject"then
addProp"BackgroundTransparency"
addProp"TextTransparency"
addProp"ImageTransparency"
end
if m:IsA"UIStroke"or m:IsA"UIShadow"then
addProp"Transparency"
end
if#n>0 then
table.insert(l,{instance=m,props=n})
end
for o,p in ipairs(m:GetChildren())do
scan(p)
end
end
scan(k.ContentScroller)
return l
end




function h._getFadeCache(j,k)
if k._cache then
return k._cache
end

if j.Window and not j.Window.MainFrame.Visible then
return{}
end
k._cache=j:_captureCache(k)
return k._cache
end



function h.PrimeCaches(j)
for k,l in ipairs(j.Tabs)do
if not l._cache then
l._cache=j:_captureCache(l)
end
end
end







function h.InvalidateCaches(j)
for k,l in ipairs(j.Tabs)do
l._cache=nil
end
j._fadeCaches={}
if j.Window and j.Window.MainFrame and j.Window.MainFrame.Visible then
j:PrimeCaches()
end
end


function h._fadeElements(j,k,l,m,n)
if not k or#k==0 then
if m then m()end
return
end
local o=0
local p=0
local function onComplete()
p=p+1
if p>=o and m then
m()
end
end
for q,r in ipairs(k)do
local s=r.instance
if r.isVideo then
if s.Parent then
local t=l
if t==nil then t=r.base end
if n then
g.set(s,t)
else
o=o+1
g.fade(s,t,0.2,"Out",onComplete)
end
end
elseif s.Parent then
for t,u in ipairs(r.props)do
local v=u[1]
local w=u[2]
local x=l
if x==nil then
x=w
end
if n then
s[v]=x
elseif s[v]~=x then
o=o+1
local y=b.Play(s,"Fast",{[v]=x})
y.Tween.Completed:Connect(onComplete)
end
end
end
end
if o==0 and m then
m()
end
end




function h._pauseSpin(j,k)
b.StopSpin(k)
end



function h._resumeSpin(j,k,l)
b.StartSpin(k,{Rotation=360},"SpinIdle")
end












function h.Tab(j,k)
k=k or{}
local l=k.Name or"Tab"
local m=#j.Tabs==0

local n=j._theme or{}

if not next(n)then
local o=a.f()
n=o.GetTheme(nil)
j._theme=n
end



local o=Instance.new"TextButton"
o.Name=l.."Tab"
o.BorderSizePixel=0
o.AutoButtonColor=false
o.BackgroundColor3=n.InactiveTabButtonColor
o.BackgroundTransparency=n.InactiveTabButtonTransparency
o.Size=UDim2.new(0.849,0,0,40)
o.BorderColor3=Color3.fromRGB(0,0,0)
o.Text=""
o.LayoutOrder=#j.Tabs+1
o.Parent=j.Window.TabList
local p=Instance.new"UICorner"
p.Parent=o
local q=Instance.new"TextLabel"
q.Name="TabName"
q.BorderSizePixel=0
q.TextSize=13
q.TextXAlignment=Enum.TextXAlignment.Left
q.TextTransparency=n.InactiveTabTextTransparency
q.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
q.TextColor3=n.InactiveTabTextColor
q.BackgroundTransparency=1
q.AnchorPoint=Vector2.new(0.5,0.5)
q.Size=UDim2.new(0.636,0,0.714,0)
q.BorderColor3=Color3.fromRGB(0,0,0)
q.Text=l
q.Position=UDim2.new(0.647,0,0.5,0)
q.Parent=o
local r=Instance.new"ImageLabel"
r.Name="BackImage"
r.BorderSizePixel=0
r.BackgroundColor3=Color3.fromRGB(255,255,255)
r.ImageTransparency=1
r.AnchorPoint=Vector2.new(0.5,0.5)

local s=n.Wallpaper or d
r.Image=s
r.Size=UDim2.new(1,0,1,0)
r.BorderColor3=Color3.fromRGB(0,0,0)
r.BackgroundTransparency=1
r.Position=UDim2.new(0.5,0,0.5,0)
r.Parent=o


r:SetAttribute("IsTabBackdrop",true)

r.Visible=n.WallpaperEnabled
local t=Instance.new"UICorner"
t.CornerRadius=UDim.new(0,6)
t.Parent=r
local u=Instance.new"UIGradient"
u.Rotation=0
u.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0),
NumberSequenceKeypoint.new(0.134,0.3),
NumberSequenceKeypoint.new(0.242,0.53125),
NumberSequenceKeypoint.new(0.371,0.69375),
NumberSequenceKeypoint.new(0.484,0.80625),
NumberSequenceKeypoint.new(0.590,0.91875),
NumberSequenceKeypoint.new(0.681,0.975),
NumberSequenceKeypoint.new(1.000,1),
}
u.Parent=r
local v=Instance.new"ImageLabel"
v.Name="TabImage"
v.BorderSizePixel=0
v.BackgroundColor3=Color3.fromRGB(255,255,255)
v.ImageTransparency=n.InactiveTabIconTransparency
v.AnchorPoint=Vector2.new(0,0.5)
v.Image=k.Icon or"rbxassetid://8445470392"
v.ImageColor3=n.InactiveTabIconColor
v.Size=UDim2.new(0,15,0,15)
v.BorderColor3=Color3.fromRGB(0,0,0)
v.BackgroundTransparency=1
v.Position=UDim2.new(0,15,0.5,0)
v.Parent=o



local w=Instance.new"Frame"
w.Name="SelectionStatus"
w.BorderSizePixel=0
w.BackgroundColor3=n.SecondaryColor
w.BackgroundTransparency=1
w.AnchorPoint=Vector2.new(0.5,0.5)
w.Size=UDim2.new(0,2,0,0)
w.Position=UDim2.new(0,-5,0.5,0)
w.BorderColor3=Color3.fromRGB(0,0,0)
w.Parent=o




local x=Instance.new"ScrollingFrame"
x.Name=l.."Scroller"
x.BorderSizePixel=0
x.CanvasSize=UDim2.new(0,0,0,0)
x.TopImage=""
x.BottomImage=""
x.ScrollBarImageTransparency=1
x.BackgroundTransparency=1
x.AutomaticCanvasSize=Enum.AutomaticSize.Y
x.ClipsDescendants=false
x.Size=UDim2.new(1,0,1,0)
x.BorderColor3=Color3.fromRGB(0,0,0)
x.ScrollBarThickness=1
x.ScrollBarImageColor3=n.TertiaryColor
x.Visible=false
x.Parent=j.Window.TabContent

local y
x:GetPropertyChangedSignal"CanvasPosition":Connect(function()
b.Play(x,"Fast",{ScrollBarImageTransparency=0.5})
if y then
task.cancel(y)
end
y=task.delay(1.5,function()
b.Play(x,"Fast",{ScrollBarImageTransparency=1})
y=nil
end)
end)
local z=Instance.new"UIPadding"
z.PaddingTop=UDim.new(0,5)
z.PaddingRight=UDim.new(0,3)
z.PaddingBottom=UDim.new(0,5)
z.Parent=x
local A=Instance.new"UIListLayout"
A.Padding=UDim.new(0,12)
A.SortOrder=Enum.SortOrder.LayoutOrder
A.FillDirection=Enum.FillDirection.Horizontal
A.Parent=x
local B=Instance.new"Frame"
B.Name="Left"
B.BorderSizePixel=0
B.BackgroundTransparency=1
B.AutomaticSize=Enum.AutomaticSize.Y
B.Size=UDim2.new(0.5,-10,0,0)
B.Position=UDim2.new(0.512,0,0,0)
B.BorderColor3=Color3.fromRGB(0,0,0)
B.Parent=x
local C=Instance.new"UIListLayout"
C.Padding=UDim.new(0,15)
C.SortOrder=Enum.SortOrder.LayoutOrder
C.Parent=B
local D=Instance.new"Frame"
D.Name="Right"
D.BorderSizePixel=0
D.BackgroundTransparency=1
D.AutomaticSize=Enum.AutomaticSize.Y
D.Size=UDim2.new(0.5,-10,0,0)
D.Position=UDim2.new(0.512,0,0,0)
D.LayoutOrder=1
D.BorderColor3=Color3.fromRGB(0,0,0)
D.Parent=x
local E=Instance.new"UIListLayout"
E.Padding=UDim.new(0,15)
E.SortOrder=Enum.SortOrder.LayoutOrder
E.Parent=D



local F=setmetatable({
Name=l,
Button=o,
TabName=q,
BackImage=r,
BackImageGradient=u,
TabImage=v,
SelectionStatus=w,
ContentScroller=x,
ColumnLeft=B,
ColumnRight=D,
_theme=n,
},i)
o.MouseButton1Click:Connect(function()

j.Window.SettingsPages.Visible=false
j.Window.TabContent.Visible=true
j:SetActiveTab(F)
end)
table.insert(j.Tabs,F)
if k.Active or m then
j:SetActiveTab(F)
end
return F
end

function h.Divider(j)
local k=j._theme or{}
local l=Instance.new"Frame"
l.Name="Divider"
l.BorderSizePixel=0
l.BackgroundColor3=k.TertiaryColor
l.BackgroundTransparency=0.5
l.Size=UDim2.new(0.85227,0,0,1)
l.LayoutOrder=#j.Tabs+1
l.BorderColor3=Color3.fromRGB(0,0,0)
l:SetAttribute("IsDivider",true)
l.Parent=j.Window.TabList
return l
end


function h.RefreshVisuals(j)
local k=j._theme or{}
for l,m in ipairs(j.Tabs)do
local n=(m==j.ActiveTab)
if n then
b.Play(m.Button,"Fast",{BackgroundColor3=k.ActiveTabButtonColor,BackgroundTransparency=k.ActiveTabButtonTransparency})
b.Play(m.TabName,"Fast",{TextTransparency=k.ActiveTabTextTransparency or 0.2,TextColor3=k.ActiveTabTextColor or Color3.fromRGB(255,255,255)})
b.Play(m.BackImage,"Fast",{ImageTransparency=0})
b.Play(m.TabImage,"Fast",{ImageTransparency=k.ActiveTabIconTransparency or 0.2,ImageColor3=k.ActiveTabIconColor or Color3.fromRGB(255,255,255)})
b.Play(m.SelectionStatus,"OnOff",{BackgroundTransparency=0,Size=UDim2.new(0,2,0.7,0)})
j:_resumeSpin(m.BackImageGradient,true)
else
b.Play(m.Button,"Fast",{BackgroundColor3=k.InactiveTabButtonColor,BackgroundTransparency=k.InactiveTabButtonTransparency})
b.Play(m.TabName,"Fast",{TextTransparency=k.InactiveTabTextTransparency or 0.6,TextColor3=k.InactiveTabTextColor or Color3.fromRGB(200,200,200)})
b.Play(m.BackImage,"Fast",{ImageTransparency=1})
b.Play(m.TabImage,"Fast",{ImageTransparency=k.InactiveTabIconTransparency or 0.6,ImageColor3=k.InactiveTabIconColor or Color3.fromRGB(200,200,200)})
b.Play(m.SelectionStatus,"OnOff",{BackgroundTransparency=1,Size=UDim2.new(0,2,0,0)})
j:_pauseSpin(m.BackImageGradient)
end
end
end





function h.RestoreActiveTab(j)
local k=j.ActiveTab
if not k then return end
for l,m in ipairs(j.Tabs)do
if m~=k then
m.ContentScroller.Visible=false
end
end
local l=j:_getFadeCache(k)
k.ContentScroller.Visible=true
j:_fadeElements(l,nil,nil,true)
k._faded=false
if j.Window and j.Window.PageTitle then
j.Window.PageTitle.TextTransparency=0.4
end
end


function h._applyTabVisuals(j,k,l)
local m=j._theme or{}
if l then
b.Play(k.Button,"Fast",{BackgroundColor3=m.ActiveTabButtonColor,BackgroundTransparency=m.ActiveTabButtonTransparency})
b.Play(k.TabName,"Fast",{TextTransparency=m.ActiveTabTextTransparency or 0.2,TextColor3=m.ActiveTabTextColor or Color3.fromRGB(255,255,255)})
b.Play(k.BackImage,"Fast",{ImageTransparency=0})
b.Play(k.TabImage,"Fast",{ImageTransparency=m.ActiveTabIconTransparency or 0.2,ImageColor3=m.ActiveTabIconColor or Color3.fromRGB(255,255,255)})
b.Play(k.SelectionStatus,"OnOff",{BackgroundTransparency=0,Size=UDim2.new(0,2,0.7,0)})
j:_resumeSpin(k.BackImageGradient,true)
else
b.Play(k.Button,"Fast",{BackgroundColor3=m.InactiveTabButtonColor,BackgroundTransparency=m.InactiveTabButtonTransparency})
b.Play(k.TabName,"Fast",{TextTransparency=m.InactiveTabTextTransparency or 0.6,TextColor3=m.InactiveTabTextColor or Color3.fromRGB(200,200,200)})
b.Play(k.BackImage,"Fast",{ImageTransparency=1})
b.Play(k.TabImage,"Fast",{ImageTransparency=m.InactiveTabIconTransparency or 0.6,ImageColor3=m.InactiveTabIconColor or Color3.fromRGB(200,200,200)})
b.Play(k.SelectionStatus,"OnOff",{BackgroundTransparency=1,Size=UDim2.new(0,2,0,0)})
j:_pauseSpin(k.BackImageGradient)
end
end

function h.SetActiveTab(j,k)
local l=j.ActiveTab
if l==k then return end
j.ActiveTab=k



if l and l.ContentScroller then
f.Clear(l.ContentScroller)
end
local m=j.Window
if m and m.SearchBox and m.SearchBox.Text~=""then
f.Apply(k.ContentScroller,m.SearchBox.Text,m._theme)
end
local n=j._theme or{}
if not next(n)then
n=e.GetTheme(nil)
j._theme=n
end
local o=j.Window and j.Window.PageTitle

if l then j:_applyTabVisuals(l,false)end
j:_applyTabVisuals(k,true)





if j.Window and j.Window._windowFaded then
for p,q in ipairs(j.Tabs)do
q.ContentScroller.Visible=(q==k)
end
if o then o.Text=j:_titleText(k)end
return
end

local p=j:_getFadeCache(k)

if l==nil then

k.ContentScroller.Visible=true
j:_fadeElements(p,1,nil,true)
if o then o.TextTransparency=1 end
j:_fadeElements(p,nil,nil,false)
if o then
o.Text=j:_titleText(k)
b.Play(o,"Fast",{TextTransparency=0.4})
end
return
end




local q=j:_getFadeCache(l)
j:_fadeElements(p,1,nil,true)
k.ContentScroller.Visible=false
if o then b.Play(o,"Fast",{TextTransparency=1})end
j:_fadeElements(q,1,function()
l.ContentScroller.Visible=false
j:_fadeElements(q,nil,nil,true)
k.ContentScroller.Visible=true
if o then o.Text=j:_titleText(k)end
j:_fadeElements(p,nil,nil,false)
if o then b.Play(o,"Fast",{TextTransparency=0.4})end
end,false)
end




function h._titleText(j,k)
return'<font weight="500">'..k.Name.."</font>"
end





function h.ApplyTheme(j,k)
local l=e.GetTheme(k)
j._theme=l
for m,n in ipairs(j.Tabs)do
n._theme=l
local o=(n==j.ActiveTab)
if o then
n.Button.BackgroundColor3=l.ActiveTabButtonColor or n.Button.BackgroundColor3
if l.ActiveTabButtonTransparency~=nil then
n.Button.BackgroundTransparency=l.ActiveTabButtonTransparency
end
n.TabName.TextColor3=l.ActiveTabTextColor or n.TabName.TextColor3
if l.ActiveTabTextTransparency~=nil then
n.TabName.TextTransparency=l.ActiveTabTextTransparency
end
n.TabImage.ImageColor3=l.ActiveTabIconColor or n.TabImage.ImageColor3
if l.ActiveTabIconTransparency~=nil then
n.TabImage.ImageTransparency=l.ActiveTabIconTransparency
end
else
n.Button.BackgroundColor3=l.InactiveTabButtonColor or n.Button.BackgroundColor3
if l.InactiveTabButtonTransparency~=nil then
n.Button.BackgroundTransparency=l.InactiveTabButtonTransparency
end
n.TabName.TextColor3=l.InactiveTabTextColor or n.TabName.TextColor3
if l.InactiveTabTextTransparency~=nil then
n.TabName.TextTransparency=l.InactiveTabTextTransparency
end
n.TabImage.ImageColor3=l.InactiveTabIconColor or n.TabImage.ImageColor3
if l.InactiveTabIconTransparency~=nil then
n.TabImage.ImageTransparency=l.InactiveTabIconTransparency
end
end
n.SelectionStatus.BackgroundColor3=l.SecondaryColor or n.SelectionStatus.BackgroundColor3
n.BackImage.Image=l.Wallpaper or d
n.BackImage.Visible=l.WallpaperEnabled~=false
n.ContentScroller.ScrollBarImageColor3=l.TertiaryColor or n.ContentScroller.ScrollBarImageColor3
end

for m,n in ipairs(j.Window.TabList:GetChildren())do
if n:GetAttribute"IsDivider"then
n.BackgroundColor3=l.TertiaryColor or n.BackgroundColor3
end
end
end

return h end function a.A():typeof(__modImpl())local b=a.cache.A if not b then b={c=__modImpl()}a.cache.A=b end return b.c end end do local function __modImpl()a.f()




















local b=a.a()
local c=a.b()
local d={}
d.__index=d
local function colorToString(e)

if typeof(e)=="string"then
return e
elseif typeof(e)=="Color3"then
return string.format(
"#%02X%02X%02X",
math.round(e.R*255),
math.round(e.G*255),
math.round(e.B*255)
)
end
return"#FFFFFF"
end
function d.new(e,f)

if type(f)~="table"then
warn"[UINotification] Settings is not a table, defaulting to empty table"
f={}
end
local g=setmetatable({},d)
local h=f.Theme
local i=f.Title or"Notification"
local j=f.Description or""
local k=
f.TitleColor
or(h and h.TitleTextColor)
or Color3.fromRGB(255,255,255)
local l=f.ConfirmText or"Confirm"
local m=f.CancelText or"Cancel"
local n=f.OnConfirm or function()end
local o=f.OnCancel or function()end
g.IsOpen=false
g._resolved=false



local p=Instance.new"ImageButton"
p.Name="UINotification"
p.Image="rbxassetid://9313765853"
p.ImageColor3=Color3.fromRGB(0,0,0)
p.BackgroundTransparency=1
p.ImageTransparency=1
p.BorderSizePixel=0
p.Size=UDim2.new(1,0,1,0)
p.Position=UDim2.new(0,0,0,0)
p.AutoButtonColor=false
p.Visible=false
p.ZIndex=10
p.Parent=e



local q=Instance.new"Frame"
q.Name="NotificationPopup"
q.BorderSizePixel=0
q.BackgroundColor3=(h and h.PopupBackgroundColor)
q.BackgroundTransparency=(h and h.PopupBackgroundTransparency)or 1
q.AnchorPoint=Vector2.new(0.5,0.5)
q.AutomaticSize=Enum.AutomaticSize.Y
q.Size=UDim2.new(0.611,0,0,0)
q.Position=UDim2.new(0.5,0,0.5,0)
q.BorderColor3=Color3.fromRGB(0,0,0)
q.Visible=false
q.ZIndex=11
q.Parent=p



local r=Instance.new"UIShadow"
r.BlurRadius=UDim.new(0,20)
r.Transparency=1
r.Color=(h and h.PopupShadowColor)
r.Parent=q



local s=Instance.new"UICorner"
s.CornerRadius=UDim.new(0,6)
s.Parent=q



local t=Instance.new"UISizeConstraint"
t.MinSize=Vector2.new(320,277)
t.MaxSize=Vector2.new(320,336)
t.Parent=q



local u=Instance.new"TextLabel"
u.Name="Header"
u.BorderSizePixel=0
u.TextSize=16
u.TextXAlignment=Enum.TextXAlignment.Left
u.TextTransparency=(h and h.PopupTextTransparency)or 0.4
u.BackgroundColor3=Color3.fromRGB(255,255,255)
u.BackgroundTransparency=1
u.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.SemiBold,
Enum.FontStyle.Normal
)
u.RichText=true
u.AnchorPoint=Vector2.new(0.5,0.5)
u.Size=UDim2.new(0.26291,0,0.03775,0)
u.AutomaticSize=Enum.AutomaticSize.X
u.Position=UDim2.new(0.5,0,0,25)
u.TextColor3=(h and h.PopupTextColor)
u.Parent=q
u.Text=string.format(
'<font color="%s">%s</font>',
colorToString(k),
i
)



local v=Instance.new"TextLabel"
v.Name="NotificationText"
v.TextWrapped=true
v.BorderSizePixel=0
v.TextSize=14
v.TextTransparency=(h and h.PopupTextTransparency)or 0.45
v.BackgroundTransparency=1
v.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.Medium,
Enum.FontStyle.Normal
)
v.TextColor3=(h and h.PopupTextColor)
v.RichText=true
v.AnchorPoint=Vector2.new(0.5,0.5)
v.Size=UDim2.new(0.91,0,0.1358,0)
v.AutomaticSize=Enum.AutomaticSize.Y
v.Position=UDim2.new(0.5,0,0.4,0)
v.BackgroundColor3=Color3.fromRGB(55,55,55)
v.BorderColor3=Color3.fromRGB(0,0,0)
v.Text=j
v.ZIndex=12
v.Parent=q
local w=Instance.new"UIPadding"
w.PaddingBottom=UDim.new(0,15)
w.Parent=v



local x=Instance.new"Frame"
x.Name="ComponentDivider"
x.BorderSizePixel=0
x.BackgroundColor3=(h and h.AccentColor)
x.BackgroundTransparency=0.9
x.AnchorPoint=Vector2.new(0.5,0.5)
x.Size=UDim2.new(0.8,0,0,1)
x.Position=UDim2.new(0.5,0,1.7,0)
x.ZIndex=12
x.Parent=v



local y=Instance.new"Frame"
y.Name="Interactions"
y.BorderSizePixel=0
y.BackgroundTransparency=1
y.AnchorPoint=Vector2.new(0.5,0.5)
y.Size=UDim2.new(0.9375,0,0.20291,0)
y.Position=UDim2.new(0.5,0,0.87569,0)
y.ZIndex=12
y.Parent=q



local z=Instance.new"TextButton"
z.Name="Confirm"
z.BorderSizePixel=0
z.TextTransparency=(h and h.PopupTextTransparency)or 0.2
z.TextSize=12
z.AutoButtonColor=false
z.TextColor3=(h and h.PopupTextColor)
z.BackgroundColor3=(h and h.PrimaryColor)
z.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.Bold,
Enum.FontStyle.Normal
)
z.AnchorPoint=Vector2.new(0.5,0)
z.Size=UDim2.new(1,0,0.43911,0)
z.Text=l
z.Position=UDim2.new(0.5,0,0,0)
z.ZIndex=13
z.Parent=y
local A=Instance.new"UICorner"
A.CornerRadius=UDim.new(0,4)
A.Parent=z
local B=Instance.new"UIShadow"
B.BlurRadius=UDim.new(0,20)
B.Color=(h and h.PrimaryColor)
B.Transparency=1
B.Parent=z



local C=Instance.new"TextButton"
C.Name="Cancel"
C.BorderSizePixel=0
C.TextTransparency=(h and h.PopupTextTransparency)or 0.5
C.TextSize=12
C.AutoButtonColor=false
C.TextColor3=(h and h.PopupTextColor)
C.BackgroundColor3=(h and h.PopupNeutralColor)
C.BackgroundTransparency=0.5
C.FontFace=Font.new(
"rbxassetid://12187365364",
Enum.FontWeight.Regular,
Enum.FontStyle.Normal
)
C.AnchorPoint=Vector2.new(0.5,1)
C.Size=UDim2.new(1,0,0.43882,0)
C.Text=m
C.Position=UDim2.new(0.5,0,1,0)
C.ZIndex=13
C.Parent=y
local D=Instance.new"UICorner"
D.CornerRadius=UDim.new(0,4)
D.Parent=C
local E=Instance.new"UIShadow"
E.BlurRadius=UDim.new(0,20)
E.Color=(h and h.PopupNeutralColor)
E.Transparency=1
E.Parent=C



g.Scrim=p
g.Popup=q
g.Shadow=r
g.ConfirmShadow=B
g.CancelShadow=E
g.Header=u
g.NotifText=v
g.Divider=x
g.Interactions=y
g.ConfirmBtn=z
g.CancelBtn=C
g.OnConfirm=n
g.OnCancel=o
g.Settings=f



function g._Confirm(F)
if F._resolved then
return
end
F._resolved=true
F:Close()
task.spawn(function()
F.OnConfirm()
end)
end
function g._Cancel(F)
if F._resolved then
return
end
F._resolved=true
F:Close()
task.spawn(function()
F.OnCancel()
end)
end



z.MouseButton1Click:Connect(function()
g:_Confirm()
end)
C.MouseButton1Click:Connect(function()
g:_Cancel()
end)



p.MouseButton1Click:Connect(function()
g:_Cancel()
end)




z.MouseEnter:Connect(function()
b.Play(B,"Smooth",{
BlurRadius=UDim.new(0,50),
Transparency=0
})
end)
z.MouseLeave:Connect(function()
b.Play(B,"Smooth",{
BlurRadius=UDim.new(0,20),
Transparency=1
})
end)



local F=0.5
local G=0.2
C.MouseEnter:Connect(function()
b.Play(C,"Smooth",{TextTransparency=G})
end)
C.MouseLeave:Connect(function()
b.Play(C,"Smooth",{TextTransparency=F})
end)







return g
end



function d.Open(e)
if e.IsOpen then
return
end
e.IsOpen=true
e._resolved=false
c.Play"Notification"

e.Scrim.ImageTransparency=1
e.Popup.BackgroundTransparency=1

e.Header.TextTransparency=1
e.NotifText.TextTransparency=1
e.Divider.BackgroundTransparency=1
e.Interactions.BackgroundTransparency=1
e.ConfirmBtn.TextTransparency=1
e.CancelBtn.TextTransparency=1
e.Scrim.Visible=true
e.Popup.Visible=true





b.Play(e.Popup,"Smooth",{
BackgroundTransparency=0.07
})

b.Play(e.Shadow,"Smooth",{
Transparency=0.5
})

b.Play(e.Header,"Smooth",{
TextTransparency=0.4
})
b.Play(e.NotifText,"Smooth",{
TextTransparency=0.45
})
b.Play(e.Divider,"Smooth",{
BackgroundTransparency=0.9
})
b.Play(e.Interactions,"Smooth",{
BackgroundTransparency=1
})
b.Play(e.ConfirmBtn,"Smooth",{
TextTransparency=0.2
})
b.Play(e.CancelBtn,"Smooth",{
TextTransparency=0.5
})
end



function d.Close(e)
if not e.IsOpen then
return
end
e.IsOpen=false

b.Play(e.Header,"Smooth",{
TextTransparency=1
})
b.Play(e.NotifText,"Smooth",{
TextTransparency=1
})
b.Play(e.Divider,"Smooth",{
BackgroundTransparency=1
})
b.Play(e.Interactions,"Smooth",{
BackgroundTransparency=1
})
b.Play(e.ConfirmBtn,"Smooth",{
TextTransparency=1,
BackgroundTransparency=1
})
b.Play(e.CancelBtn,"Smooth",{
TextTransparency=1,
BackgroundTransparency=1
})

b.Play(e.Shadow,"Smooth",{
Transparency=1
})


b.Play(e.ConfirmShadow,"Smooth",{
BlurRadius=UDim.new(0,20),
Transparency=1
})


b.Play(e.CancelShadow,"Smooth",{
Transparency=1
})

b.Play(e.Popup,"Smooth",{
BackgroundTransparency=1
})




task.delay(0.35,function()
if not e.IsOpen then
e.Popup.Visible=false
e.Scrim.Visible=false
end
end)
end

function d.SetContent(e,f)

if type(f)~="table"then
warn"[UINotification:SetContent] Settings is not a table, defaulting to empty table"
f={}
end
local g=f.Title or"Notification"
local h=f.Description or""
local i=f.TitleColor or Color3.fromRGB(255,255,255)
local j=f.ConfirmText or"Confirm"
local k=f.CancelText or"Cancel"
e.OnConfirm=f.OnConfirm or function()end
e.OnCancel=f.OnCancel or function()end

local l=colorToString(i)
e.Header.Text=string.format('<font color="%s">%s</font>',l,g)

e.NotifText.Text=h

e.ConfirmBtn.Text=j
e.CancelBtn.Text=k

e._resolved=false
end



function d.SetTitle(e,f,g)
local h
if g then
h=colorToString(g)
else


h=colorToString(Color3.fromRGB(255,255,255))
end
e.Header.Text=string.format(
'<font color="%s">%s</font>',
h,
f
)
end



function d.SetDescription(e,f)
e.NotifText.Text=f
end



function d.Destroy(e)
if e.Scrim then
e.Scrim:Destroy()
end
end

function d.Hide(e)
e.Popup.Visible=false
e.Scrim.Visible=false
e.IsOpen=false
end
return d end function a.B():typeof(__modImpl())local b=a.cache.B if not b then b={c=__modImpl()}a.cache.B=b end return b.c end end do local function __modImpl()











local b=a.a()a.b()

local c=a.c()
local d=a.l().FallbackImage
local e=a.f()
local f=a.z()
local g={}
g.__index=g
local function sanitizeName(h)
return h:gsub("[^%w_]","_")
end



local function itemsEqual(h,i)
if#h~=#i then return false end
for j=1,#h do
local k,l=h[j],i[j]
if k.name~=l.name or k.value~=l.value or k.icon~=l.icon then
return false
end
end
return true
end
function g.new(h,i,j)
i=i or{}
local k=setmetatable({},g)
local l=i.Theme
k._theme=l
local m=i.Title or"Select Items"
local n=i.TitleColor or(l and l.TitleTextColor)
local o=i.Items or{}
local p=i.Default or{}
local q=i.MaxItemsChoosable or math.huge
local r=i.OnConfirm or function()end
local s=i.OnCancel or function()end



local t=Instance.new"Frame"
t.Name=sanitizeName(m).."DropdownPopup"
t.BorderSizePixel=0
t.BackgroundColor3=(l and l.PopupBackgroundColor)
t.BackgroundTransparency=(l and l.PopupBackgroundTransparency)or 1
t.AnchorPoint=Vector2.new(0.5,0.5)
t.Size=UDim2.new(0.694,0,1.02153,0)
t.Position=UDim2.new(0.5,0,0.5,0)
t.BorderColor3=Color3.fromRGB(0,0,0)
t.Visible=false
t.ZIndex=11
t.Parent=h
local u=Instance.new"UIShadow"
u.Color=(l and l.PopupShadowColor)
u.BlurRadius=UDim.new(0,20)
u.Transparency=1
u.Parent=t
local v=Instance.new"UICorner"
v.CornerRadius=UDim.new(0,6)
v.Parent=t
local w=Instance.new"UIScale"
w.Scale=0.9
w.Parent=t
local x=Instance.new"TextLabel"
x.Name="Header"
x.BorderSizePixel=0
x.TextSize=16
x.TextXAlignment=Enum.TextXAlignment.Center
x.TextTransparency=1
x.BackgroundColor3=Color3.fromRGB(255,255,255)
x.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
x.TextColor3=n or(l and l.PopupTextColor)or Color3.fromRGB(255,255,255)
x.BackgroundTransparency=1
x.AnchorPoint=Vector2.new(0.5,0.5)
x.Size=UDim2.new(0.26291,0,0.03775,0)
x.AutomaticSize=Enum.AutomaticSize.X
x.Position=UDim2.new(0.5,0,0,25)
x.Parent=t
x.Text=m
local y=Instance.new"Frame"
y.Name="Interactions"
y.BorderSizePixel=0
y.BackgroundTransparency=1
y.AnchorPoint=Vector2.new(0.5,0.5)
y.Size=UDim2.new(0.9375,0,0.16328,0)
y.Position=UDim2.new(0.5,0,0.89551,0)
y.Parent=t
local z=Instance.new"TextButton"
z.Name="Confirm"
z.BorderSizePixel=0
z.TextTransparency=1
z.TextStrokeColor3=Color3.fromRGB(255,255,255)
z.TextSize=12
z.Text="Confirm"
z.AutoButtonColor=false
z.TextColor3=(l and l.PopupTextColor)
z.BackgroundColor3=(l and l.PrimaryColor)
z.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
z.AnchorPoint=Vector2.new(0.5,0)
z.Size=UDim2.new(1,0,0.43911,0)
z.Position=UDim2.new(0.5,0,0,0)
z.Parent=y
local A=Instance.new"UICorner"
A.CornerRadius=UDim.new(0,4)
A.Parent=z
local B=Instance.new"UIShadow"
B.BlurRadius=UDim.new(0,20)
B.Color=(l and l.PrimaryColor)
B.Transparency=1
B.Parent=z
local C=Instance.new"TextButton"
C.Name="Cancel"
C.BorderSizePixel=0
C.TextTransparency=1
C.TextStrokeColor3=Color3.fromRGB(255,255,255)
C.TextSize=12
C.Text="Cancel"
C.AutoButtonColor=false
C.TextColor3=(l and l.PopupTextColor)
C.BackgroundColor3=(l and l.PopupNeutralColor)
C.BackgroundTransparency=0.5
C.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
C.AnchorPoint=Vector2.new(0.5,1)
C.Size=UDim2.new(1,0,0.43882,0)
C.Position=UDim2.new(0.5,0,1,0)
C.Parent=y
local D=Instance.new"UICorner"
D.CornerRadius=UDim.new(0,4)
D.Parent=C
local E=Instance.new"UIShadow"
E.BlurRadius=UDim.new(0,20)
E.Color=(l and l.PopupNeutralColor)
E.Transparency=1
E.Parent=C
local F=Instance.new"ScrollingFrame"
F.Name="DropdownList"
F.Active=true
F.BorderSizePixel=0
F.ScrollBarImageTransparency=0.5
F.BackgroundTransparency=1
F.VerticalScrollBarPosition=Enum.VerticalScrollBarPosition.Left
F.AnchorPoint=Vector2.new(0.5,0.5)
F.AutomaticCanvasSize=Enum.AutomaticSize.Y
F.Size=UDim2.new(0.938,0,0.43668,0)
F.Position=UDim2.new(0.5,0,0.48976,0)
F.ScrollBarThickness=1
F.ScrollBarImageColor3=(l and l.TertiaryColor)
F.Parent=t
local G=Instance.new"UIListLayout"
G.Padding=UDim.new(0,15)
G.SortOrder=Enum.SortOrder.LayoutOrder
G.Parent=F
local H=Instance.new"UIPadding"
H.PaddingTop=UDim.new(0,2)
H.PaddingRight=UDim.new(0,8)
H.PaddingLeft=UDim.new(0,8)
H.Parent=F
local I=Instance.new"TextLabel"
I.Name="SelectedItemsText"
I.TextWrapped=true
I.BorderSizePixel=0
I.TextSize=13
I.TextXAlignment=Enum.TextXAlignment.Left
I.TextTransparency=1
I.BackgroundTransparency=1
I.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
I.TextColor3=(l and l.PopupTextColor)
I.RichText=true
I.AnchorPoint=Vector2.new(0.5,0.5)
I.Size=UDim2.new(0.91,0,0,26)
I.Position=UDim2.new(0.5,0,0.76384,0)
I.Parent=t
I.Text="None selected"
local J=Instance.new"UIPadding"
J.PaddingTop=UDim.new(0,3)
J.PaddingLeft=UDim.new(0,5)
J.PaddingBottom=UDim.new(0,15)
J.Parent=I
local K=Instance.new"Frame"
K.Name="ComponentDivider"
K.BorderSizePixel=0
K.BackgroundColor3=(l and l.AccentColor)
K.BackgroundTransparency=0.9
K.AnchorPoint=Vector2.new(0.5,0.5)
K.Size=UDim2.new(0.8,0,0,2)
K.Position=UDim2.new(0.5,0,2.6,0)
K.Parent=I
local L=Instance.new"Frame"
L.Name="InteractionOrganizer"
L.BorderSizePixel=0
L.BackgroundTransparency=1
L.AnchorPoint=Vector2.new(0.5,0.5)
L.Size=UDim2.new(0.91879,0,0.0779,0)
L.Position=UDim2.new(0.5,0,0.1868,0)
L.Parent=t
local M=Instance.new"TextBox"
M.Name="SearchBox"
M.TextXAlignment=Enum.TextXAlignment.Left
M.PlaceholderColor3=Color3.fromRGB(100,100,100)
M.BorderSizePixel=0
M.TextTruncate=Enum.TextTruncate.AtEnd
M.TextTransparency=1
M.TextSize=14
M.TextColor3=(l and l.PopupTextColor)
M.BackgroundTransparency=1
M.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
M.AnchorPoint=Vector2.new(0.5,0.5)
M.PlaceholderText="Search..."
M.Size=UDim2.new(0.38996,0,1,0)
M.Position=UDim2.new(0.26484,0,0.5,0)
M.Parent=L


local N=Instance.new"Frame"
N.Name="SearchDividerBottom"
N.BorderSizePixel=0
N.BackgroundColor3=(l and l.TertiaryColor)or Color3.fromRGB(160,160,160)
N.BackgroundTransparency=0.9
N.AnchorPoint=Vector2.new(0,0.5)
N.Size=UDim2.new(0.6,0,0,1)
N.Position=UDim2.new(0,0,1,0)
N.Parent=L
local O=Instance.new"ImageLabel"
O.Name="SearchImage"
O.BorderSizePixel=0
O.BackgroundTransparency=1
O.ImageTransparency=0.7
O.AnchorPoint=Vector2.new(0.5,0.5)
O.Image=c.search
O.ImageColor3=(l and l.SecondaryColor)or Color3.fromRGB(200,200,200)
O.Size=UDim2.new(0,17,0,15)
O.Position=UDim2.new(0.01759,0,0.5,0)
O.Parent=L
local P=Instance.new"TextButton"
P.Name="ClearSelection"
P.BorderSizePixel=0
P.TextTransparency=1
P.AutoButtonColor=false
P.BackgroundColor3=(l and l.TertiaryColor)or Color3.fromRGB(100,116,139)
P.AnchorPoint=Vector2.new(0.5,0.5)
P.Size=UDim2.new(0.09462,0,1,0)
P.Position=UDim2.new(0.96018,0,0.5,0)
P.Parent=L
local Q=Instance.new"UICorner"
Q.CornerRadius=UDim.new(0,6)
Q.Parent=P
local R=Instance.new"ImageLabel"
R.Name="ButtonImage"
R.ImageTransparency=0.2
R.AnchorPoint=Vector2.new(0.5,0.5)
R.Position=UDim2.new(0.5,0,0.5,0)
R.Image=c.eraser
R.ImageColor3=(l and l.PopupTextColor)or Color3.fromRGB(255,255,255)
R.Size=UDim2.new(0,17,0,17)
R.BackgroundTransparency=1
R.Parent=P
local S=Instance.new"UIAspectRatioConstraint"
S.DominantAxis=Enum.DominantAxis.Height
S.Parent=R
local T=Instance.new"UIShadow"
T.BlurRadius=UDim.new(0,20)
T.Color=(l and l.TertiaryColor)or Color3.fromRGB(100,116,139)
T.Transparency=1
T.Parent=P
local U=Instance.new"TextButton"
U.Name="SelectAll"
U.BorderSizePixel=0
U.TextTransparency=1
U.AutoButtonColor=false
U.BackgroundColor3=(l and l.AccentColor)or Color3.fromRGB(96,165,250)
U.AnchorPoint=Vector2.new(0.5,0.5)
U.Size=UDim2.new(0.09462,0,1,0)
U.Position=UDim2.new(0.83689,0,0.5,0)
U.Parent=L
local V=Instance.new"UICorner"
V.CornerRadius=UDim.new(0,6)
V.Parent=U
local W=Instance.new"ImageLabel"
W.Name="ButtonImage"
W.ImageTransparency=0.2
W.AnchorPoint=Vector2.new(0.5,0.5)
W.Position=UDim2.new(0.5,0,0.5,0)
W.Image=c["list-check"]
W.ImageColor3=(l and l.PopupTextColor)or Color3.fromRGB(255,255,255)
W.Size=UDim2.new(0,17,0,17)
W.BackgroundTransparency=1
W.Parent=U
local X=Instance.new"UIAspectRatioConstraint"
X.DominantAxis=Enum.DominantAxis.Height
X.Parent=W
local Y=Instance.new"UIShadow"
Y.BlurRadius=UDim.new(0,20)
Y.Color=(l and l.AccentColor)or Color3.fromRGB(96,165,250)
Y.Transparency=1
Y.Parent=U

if q~=math.huge then
U.Visible=false
end



k.Popup=t
k.Shadow=u
k.Header=x
k.ConfirmBtn=z
k.ConfirmShadow=B
k.CancelBtn=C
k.CancelShadow=E
k.List=F
k.ListLayout=G
k.SelectedText=I
k.SearchBox=M
k.SelectAllBtn=U
k.SelectAllShadow=Y
k.ClearBtn=P
k.ClearShadow=T
k.SearchIcon=O
k.SearchDivider=N
k.SelectAllIcon=W
k.ClearBtnIcon=R
k.Divider=K
k.Items=o
k.MaxItems=q
k.OnConfirm=r
k.OnCancel=s
k._cleanupCallback=j
k.IsOpen=false
k._resolved=false
k._itemObjects={}
k._selectedValues={}
k._inputConnection=nil
k._scrollbarTimer=nil
k._hideTimer=nil



M.Focused:Connect(function()
b.Play(N,"Fast",{BackgroundTransparency=0.2})
b.Play(O,"Fast",{ImageTransparency=0.2})
end)
M.FocusLost:Connect(function()
b.Play(N,"Fast",{BackgroundTransparency=0.9})
b.Play(O,"Fast",{ImageTransparency=0.7})
end)






function k.ApplyTheme(Z,_)
if not Z.Popup then return end
local aa=e.GetTheme(_)
Z._theme=aa
Z.Popup.BackgroundColor3=aa.PopupBackgroundColor or Z.Popup.BackgroundColor3
Z.Shadow.Color=aa.PopupShadowColor or Z.Shadow.Color
Z.Header.TextColor3=aa.PopupTextColor or Z.Header.TextColor3
Z.ConfirmBtn.TextColor3=aa.PopupTextColor or Z.ConfirmBtn.TextColor3
Z.ConfirmBtn.BackgroundColor3=aa.PrimaryColor or Z.ConfirmBtn.BackgroundColor3
Z.ConfirmShadow.Color=aa.PrimaryColor or Z.ConfirmShadow.Color
Z.CancelBtn.TextColor3=aa.PopupTextColor or Z.CancelBtn.TextColor3
Z.CancelBtn.BackgroundColor3=aa.PopupNeutralColor or Z.CancelBtn.BackgroundColor3
Z.CancelShadow.Color=aa.PopupNeutralColor or Z.CancelShadow.Color
Z.SelectedText.TextColor3=aa.PopupTextColor or Z.SelectedText.TextColor3
Z.Divider.BackgroundColor3=aa.AccentColor or Z.Divider.BackgroundColor3
Z.SearchBox.TextColor3=aa.PopupTextColor or Z.SearchBox.TextColor3
Z.SearchDivider.BackgroundColor3=aa.TertiaryColor or Z.SearchDivider.BackgroundColor3
Z.SearchIcon.ImageColor3=aa.SecondaryColor or Z.SearchIcon.ImageColor3
Z.ClearBtn.BackgroundColor3=aa.TertiaryColor or Z.ClearBtn.BackgroundColor3
Z.ClearShadow.Color=aa.TertiaryColor or Z.ClearShadow.Color
Z.ClearBtnIcon.ImageColor3=aa.PopupTextColor or Z.ClearBtnIcon.ImageColor3
Z.SelectAllBtn.BackgroundColor3=aa.AccentColor or Z.SelectAllBtn.BackgroundColor3
Z.SelectAllShadow.Color=aa.AccentColor or Z.SelectAllShadow.Color
Z.SelectAllIcon.ImageColor3=aa.PopupTextColor or Z.SelectAllIcon.ImageColor3
Z.List.ScrollBarImageColor3=aa.TertiaryColor or Z.List.ScrollBarImageColor3

for ab,ac in ipairs(Z._itemObjects)do
if ac.button then ac.button.BackgroundColor3=aa.AccentColor or ac.button.BackgroundColor3 end
if ac.nameLabel then ac.nameLabel.TextColor3=aa.PopupTextColor or ac.nameLabel.TextColor3 end
if ac.icon then
ac.icon.ImageColor3=ac.selected and(aa.ActiveTabIconColor or ac.icon.ImageColor3)
or(aa.InactiveTabIconColor or ac.icon.ImageColor3)
end
if ac.stroke then ac.stroke.Color=aa.StrokeColor or ac.stroke.Color end
if ac.shadow then ac.shadow.Color=aa.ComponentShadowColor or ac.shadow.Color end



if ac.backImage then
ac.backImage.Image=aa.Wallpaper or d
ac.backImage.Visible=not(aa.WallpaperEnabled==false)
end
end
end




function k._toggleItem(aa,ab)
local ac=ab.selected
if aa.MaxItems==1 then
if not ac then
for Z,_ in ipairs(aa._itemObjects)do
if _.selected then
aa:_setItemSelected(_,false)
end
end
aa._selectedValues={}
aa:_setItemSelected(ab,true)
table.insert(aa._selectedValues,ab.value)
else
aa:_setItemSelected(ab,false)
for Z,_ in ipairs(aa._selectedValues)do
if _==ab.value then
table.remove(aa._selectedValues,Z)
break
end
end
end
else
if not ac then
if#aa._selectedValues>=aa.MaxItems then
return
end
aa:_setItemSelected(ab,true)
table.insert(aa._selectedValues,ab.value)
else
aa:_setItemSelected(ab,false)
for Z,_ in ipairs(aa._selectedValues)do
if _==ab.value then
table.remove(aa._selectedValues,Z)
break
end
end
end
end
aa:_updateSelectedText()
end
function k._setItemSelected(aa,ab,ac)
ab.selected=ac
if ac then
ab.button.Name="SelectedItem"
if ab.button then b.Play(ab.button,"Smooth",{BackgroundTransparency=0})end
if ab.nameLabel then b.Play(ab.nameLabel,"Smooth",{TextTransparency=0})end
if ab.backImage then b.Play(ab.backImage,"Smooth",{ImageTransparency=0.5})end
if ab.icon then
ab.icon.ImageColor3=(l and l.ActiveTabIconColor)or ab.icon.ImageColor3
b.Play(ab.icon,"Smooth",{ImageTransparency=0})
end
if ab.stroke then b.Play(ab.stroke,"Smooth",{Transparency=0.95})end
if ab.shadow then b.Play(ab.shadow,"Smooth",{Transparency=0.5})end
if ab.gradient then b.StartSpin(ab.gradient,{Rotation=360},"SpinIdle")end
else
ab.button.Name="DeselectedItem"
if ab.button then b.Play(ab.button,"Smooth",{BackgroundTransparency=1})end
if ab.nameLabel then b.Play(ab.nameLabel,"Smooth",{TextTransparency=0.6})end
if ab.backImage then b.Play(ab.backImage,"Smooth",{ImageTransparency=1})end
if ab.icon then
ab.icon.ImageColor3=(l and l.InactiveTabIconColor)or ab.icon.ImageColor3
b.Play(ab.icon,"Smooth",{ImageTransparency=0.9})
end
if ab.stroke then b.Play(ab.stroke,"Smooth",{Transparency=0.95})end
if ab.shadow then b.Play(ab.shadow,"Smooth",{Transparency=1})end
if ab.gradient then b.StopSpin(ab.gradient)end
end
end
function k.SetSelection(aa,ab)
for ac,Z in ipairs(aa._itemObjects)do
if Z.selected then
aa:_setItemSelected(Z,false)
end
end
aa._selectedValues={}
for ac,Z in ipairs(ab)do
for _,ad in ipairs(aa._itemObjects)do
if ad.value==Z then
aa:_setItemSelected(ad,true)
table.insert(aa._selectedValues,Z)
break
end
end
end
aa:_updateSelectedText()
end
function k.ClearSelection(aa)
for ab,ac in ipairs(aa._itemObjects)do
if ac.selected then
aa:_setItemSelected(ac,false)
end
end
aa._selectedValues={}
aa:_updateSelectedText()
end
function k.SelectAll(aa)
if aa.MaxItems~=math.huge then
local ab=aa.MaxItems
local ac=#aa._selectedValues
local ad=ab-ac
if ad<=0 then return end
local Z=0
for _,ae in ipairs(aa._itemObjects)do
if not ae.selected and Z<ad then
aa:_setItemSelected(ae,true)
table.insert(aa._selectedValues,ae.value)
Z=Z+1
end
end
else
for ab,ac in ipairs(aa._itemObjects)do
if not ac.selected then
aa:_setItemSelected(ac,true)
table.insert(aa._selectedValues,ac.value)
end
end
end
aa:_updateSelectedText()
end
function k._filterItems(aa,ab)
local ac=string.lower(ab or"")
local ad=(aa._theme and aa._theme.AccentColor)or Color3.fromRGB(96,165,250)


for ae,Z in ipairs(aa._itemObjects)do
local _=(ac=="")or(string.find(string.lower(Z.name),ac,1,true)~=nil)
Z.button.Visible=_


if Z.nameLabel then
local af=_ and ac~=""and f.Highlight(Z.name,ac,ad)or nil
if af then
Z.nameLabel.RichText=true
Z.nameLabel.Text=af
else
Z.nameLabel.Text=Z.name
end
end
end
end
function k._updateSelectedText(aa)
local ab={}
for ac,ad in ipairs(aa._itemObjects)do
if ad.selected then
table.insert(ab,ad.name)
end
end
if#ab>0 then
aa.SelectedText.Text=string.format("{ %s }",table.concat(ab,", "))
else
aa.SelectedText.Text="None selected"
end
end
function k._Confirm(aa)
if aa._resolved then return end
aa._resolved=true
local ab={}
for ac,ad in ipairs(aa._itemObjects)do
if ad.selected then
table.insert(ab,{name=ad.name,value=ad.value})
end
end
aa:Close()
aa.OnConfirm(ab)
end
function k._Cancel(aa)
if aa._resolved then return end
aa._resolved=true
aa:Close()
aa.OnCancel()
end



function k._buildItems(aa)

for ab,ac in ipairs(aa._itemObjects)do
ac.button:Destroy()
end
aa._itemObjects={}
aa._selectedValues={}
for ab,ac in ipairs(aa.Items)do
local ad=ac.name or"Item"
local ae=ac.icon or c.circle or"rbxassetid://130359823580534"
local af=ac.value or ad
local Z=Instance.new"TextButton"
Z.Name="DeselectedItem"
Z.BorderSizePixel=0
Z.TextTransparency=1
Z.AutoButtonColor=false
Z.BackgroundColor3=(l and l.AccentColor)or Color3.fromRGB(96,165,250)
Z.BackgroundTransparency=1
Z.Size=UDim2.new(1,0,0,40)
Z.Parent=aa.List
local _=Instance.new"UICorner"
_.CornerRadius=UDim.new(0,6)
_.Parent=Z
local ag=Instance.new"ImageLabel"
ag.Name="BackImage"
ag.BorderSizePixel=0
ag.BackgroundColor3=Color3.fromRGB(255,255,255)
ag.ImageTransparency=1
ag.AnchorPoint=Vector2.new(0.5,0.5)
local ah=i.Theme
local ai=(ah and ah.Wallpaper)or d
ag.Image=ai
ag:SetAttribute("IsThemeSheen",true)
ag.Size=UDim2.new(1,0,1,0)
ag.BackgroundTransparency=1
ag.Position=UDim2.new(0.5,0,0.5,0)
ag.Parent=Z

ag.Visible=not(ah and ah.WallpaperEnabled==false)
local aj=Instance.new"UICorner"
aj.CornerRadius=UDim.new(0,6)
aj.Parent=ag
local ak=Instance.new"UIGradient"
ak.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0.72131),
NumberSequenceKeypoint.new(0.110,0.68306),
NumberSequenceKeypoint.new(0.240,0.63388),
NumberSequenceKeypoint.new(0.349,0.57923),
NumberSequenceKeypoint.new(0.461,0.48087),
NumberSequenceKeypoint.new(0.583,0.37158),
NumberSequenceKeypoint.new(0.676,0.2459),
NumberSequenceKeypoint.new(0.770,0.0929),
NumberSequenceKeypoint.new(0.867,0),
NumberSequenceKeypoint.new(1.000,0)
}
ak.Parent=ag
local al=Instance.new"ImageLabel"
al.Name="ItemImage"
al.ImageTransparency=0.9
al.AnchorPoint=Vector2.new(0.5,0.5)
al.Image=ae


al.ImageColor3=(ah and ah.InactiveTabIconColor)or Color3.fromRGB(255,255,255)
al.Size=UDim2.new(0,24,0,24)
al.BackgroundTransparency=1
al.Position=UDim2.new(0,20,0.5,0)
al.Parent=Z
local am=Instance.new"UIAspectRatioConstraint"
am.DominantAxis=Enum.DominantAxis.Height
am.Parent=al
local an=Instance.new"TextLabel"
an.Name="ItemName"
an.TextWrapped=true
an.BorderSizePixel=0
an.TextSize=16
an.TextXAlignment=Enum.TextXAlignment.Left
an.TextTransparency=0.6
an.BackgroundColor3=Color3.fromRGB(55,55,55)
an.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
an.TextColor3=(ah and ah.PopupTextColor)or Color3.fromRGB(255,255,255)
an.BackgroundTransparency=1
an.AnchorPoint=Vector2.new(0,0.5)
an.Size=UDim2.new(0.48591,0,0.71359,0)
an.BorderColor3=Color3.fromRGB(0,0,0)
an.Text=ad
an.Position=UDim2.new(0,40,0.5,0)
an.Parent=Z
local ao=Instance.new"UIStroke"
ao.Transparency=0.95
ao.Thickness=0.7
ao.Color=(ah and ah.StrokeColor)or Color3.fromRGB(255,255,255)
ao.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
ao.Parent=Z
local ap=Instance.new"UIShadow"
ap.Color=(ah and ah.ComponentShadowColor)or Color3.fromRGB(0,0,0)
ap.Transparency=1
ap.BlurRadius=UDim.new(0,20)
ap.Parent=Z
local aq={
button=Z,
nameLabel=an,
backImage=ag,
gradient=ak,
icon=al,
stroke=ao,
shadow=ap,
value=af,
name=ad,
selected=false,
}
table.insert(aa._itemObjects,aq)

Z.MouseButton1Click:Connect(function()
aa:_toggleItem(aq)
end)

Z.MouseEnter:Connect(function()
if aq.selected then
if aq.icon then b.Play(aq.icon,"HoverIn",{ImageTransparency=0.2})end
if aq.shadow then b.Play(aq.shadow,"HoverIn",{Transparency=0.35})end
else
if aq.icon then b.Play(aq.icon,"HoverIn",{ImageTransparency=0.7})end
end
end)
Z.MouseLeave:Connect(function()
local ar=aq.selected and 0.4 or 0.9
if aq.icon then b.Play(aq.icon,"HoverOut",{ImageTransparency=ar})end
if aq.shadow then b.Play(aq.shadow,"HoverOut",{Transparency=1})end
end)
end
end

k:_buildItems()
if#p>0 then
k:SetSelection(p)
end
k:_updateSelectedText()



z.MouseButton1Click:Connect(function()
k:_Confirm()
end)
C.MouseButton1Click:Connect(function()
k:_Cancel()
end)
U.MouseButton1Click:Connect(function()
k:SelectAll()
end)
P.MouseButton1Click:Connect(function()
k:ClearSelection()
end)
M:GetPropertyChangedSignal"Text":Connect(function()
k:_filterItems(M.Text)
end)

z.MouseEnter:Connect(function()
b.Play(B,"Smooth",{
BlurRadius=UDim.new(0,50),
Transparency=0
})
end)
z.MouseLeave:Connect(function()
b.Play(B,"Smooth",{
BlurRadius=UDim.new(0,20),
Transparency=1
})
end)

C.MouseEnter:Connect(function()
b.Play(C,"Smooth",{
TextTransparency=0.2
})
end)
C.MouseLeave:Connect(function()
b.Play(C,"Smooth",{
TextTransparency=0.5
})
end)



function k.SetContent(aa,ab)
if not aa.Popup then return end
ab=ab or{}
local ac=ab.Title or"Select Items"



local ad=e.GetTheme(ab.Theme or aa._theme)
local ae=ab.TitleColor or(ad and ad.PopupTextColor)or Color3.fromRGB(255,255,255)
local af=ab.Items or{}
local ag=ab.Default or{}
local ah=ab.MaxItemsChoosable or math.huge
local ai=aa.Items or{}
aa.MaxItems=ah
aa.Items=af
aa.OnConfirm=ab.OnConfirm or function()end
aa.OnCancel=ab.OnCancel or function()end
aa.Title=ac

aa.Header.Text=ac
aa.Header.TextColor3=ae or Color3.fromRGB(255,255,255)

aa.Popup.Name=sanitizeName(ac).."DropdownPopup"



if not itemsEqual(ai,af)then
aa:_buildItems()
end
aa:SetSelection(ag)
aa:_updateSelectedText()

aa._resolved=false

if ah~=math.huge then
aa.SelectAllBtn.Visible=false
else
aa.SelectAllBtn.Visible=true
end
end
function k.Open(aa)
if not aa.Popup then return end

if aa._hideTimer then
task.cancel(aa._hideTimer)
aa._hideTimer=nil
end


aa.IsOpen=true
aa._resolved=false

if aa.SearchBox then aa.SearchBox.Text=""end
for ab,ac in ipairs(aa._itemObjects)do
ac.button.Visible=true
end

aa.Popup.Visible=true

for ab,ac in ipairs(aa._itemObjects)do
if ac.selected then
if ac.button then ac.button.BackgroundTransparency=0 end
if ac.nameLabel then ac.nameLabel.TextTransparency=0.2 end
if ac.backImage then ac.backImage.ImageTransparency=0.5 end
if ac.icon then ac.icon.ImageTransparency=0.4 end
if ac.stroke then ac.stroke.Transparency=0.95 end
if ac.shadow then ac.shadow.Transparency=0.5 end
if ac.gradient then b.StartSpin(ac.gradient,{Rotation=360},"SpinIdle")end
else
if ac.button then ac.button.BackgroundTransparency=1 end
if ac.nameLabel then ac.nameLabel.TextTransparency=0.6 end
if ac.backImage then ac.backImage.ImageTransparency=1 end
if ac.icon then ac.icon.ImageTransparency=0.9 end
if ac.stroke then ac.stroke.Transparency=0.95 end
if ac.shadow then ac.shadow.Transparency=1 end
if ac.gradient then b.StopSpin(ac.gradient)end
end
end

aa.Popup.BackgroundTransparency=1
aa.Shadow.Transparency=1
if aa.ConfirmShadow then aa.ConfirmShadow.Transparency=1 end
if aa.CancelShadow then aa.CancelShadow.Transparency=1 end
if aa.SelectAllShadow then aa.SelectAllShadow.Transparency=1 end
if aa.ClearShadow then aa.ClearShadow.Transparency=1 end
aa.Header.TextTransparency=1
aa.SearchBox.TextTransparency=1
aa.SelectedText.TextTransparency=1
aa.ConfirmBtn.TextTransparency=1
aa.ConfirmBtn.BackgroundTransparency=1
aa.CancelBtn.TextTransparency=1
aa.CancelBtn.BackgroundTransparency=1
aa.SelectAllBtn.TextTransparency=1
aa.SelectAllBtn.BackgroundTransparency=1
aa.ClearBtn.TextTransparency=1
aa.ClearBtn.BackgroundTransparency=1

if aa.SearchIcon then aa.SearchIcon.ImageTransparency=1 end
if aa.SelectAllIcon then aa.SelectAllIcon.ImageTransparency=1 end
if aa.ClearBtnIcon then aa.ClearBtnIcon.ImageTransparency=1 end
if aa.Divider then aa.Divider.BackgroundTransparency=1 end
aa.Popup.Visible=true

if aa.Popup then b.Play(aa.Popup,"Smooth",{BackgroundTransparency=0.07})end
if aa.Shadow then b.Play(aa.Shadow,"Smooth",{Transparency=0.5})end
if aa.Header then b.Play(aa.Header,"Smooth",{TextTransparency=0.4})end
if aa.SearchBox then b.Play(aa.SearchBox,"Smooth",{TextTransparency=0.4})end
if aa.SelectedText then b.Play(aa.SelectedText,"Smooth",{TextTransparency=0.45})end
if aa.ConfirmBtn then b.Play(aa.ConfirmBtn,"Smooth",{TextTransparency=0.2,BackgroundTransparency=0})end
if aa.CancelBtn then b.Play(aa.CancelBtn,"Smooth",{TextTransparency=0.5,BackgroundTransparency=0.5})end
if aa.SelectAllBtn then b.Play(aa.SelectAllBtn,"Smooth",{TextTransparency=1,BackgroundTransparency=0})end
if aa.ClearBtn then b.Play(aa.ClearBtn,"Smooth",{TextTransparency=1,BackgroundTransparency=0})end
if aa.SelectAllShadow then b.Play(aa.SelectAllShadow,"Smooth",{Transparency=0.5})end
if aa.ClearShadow then b.Play(aa.ClearShadow,"Smooth",{Transparency=0.5})end

if aa.SearchIcon then b.Play(aa.SearchIcon,"Smooth",{ImageTransparency=0.7})end
if aa.SelectAllIcon then b.Play(aa.SelectAllIcon,"Smooth",{ImageTransparency=0.2})end
if aa.ClearBtnIcon then b.Play(aa.ClearBtnIcon,"Smooth",{ImageTransparency=0.2})end
if aa.Divider then b.Play(aa.Divider,"Smooth",{BackgroundTransparency=0.9})end

if aa.List then
b.Play(aa.List,"Fast",{ScrollBarImageTransparency=1})
aa.List.ScrollBarImageTransparency=1

if not aa._scrollConnection then
aa._scrollConnection=aa.List:GetPropertyChangedSignal"CanvasPosition":Connect(function()
aa:_showScrollbar()
end)
end
end

local ab=game:GetService"UserInputService"
local function onInputBegan(ac,ad)
if ad then return end
if not aa.Popup then return end
if ac.UserInputType==Enum.UserInputType.MouseButton1 or ac.UserInputType==Enum.UserInputType.Touch then
local ae=ac.Position
local af=aa.Popup.AbsolutePosition
local ag=aa.Popup.AbsoluteSize
local ah=ae.X>=af.X and ae.X<=af.X+ag.X
and ae.Y>=af.Y and ae.Y<=af.Y+ag.Y
if not ah then
aa:_Confirm()
end
end
end


if aa._inputConnection then
aa._inputConnection:Disconnect()
end
aa._inputConnection=ab.InputBegan:Connect(onInputBegan)
end
function k.Close(aa)
if not aa.Popup then return end
if not aa.IsOpen then return end
aa.IsOpen=false

if aa._inputConnection then
aa._inputConnection:Disconnect()
aa._inputConnection=nil
end

if aa._scrollbarTimer then
task.cancel(aa._scrollbarTimer)
aa._scrollbarTimer=nil
end

for ab,ac in ipairs(aa._itemObjects)do
if ac.button then b.Play(ac.button,"Smooth",{BackgroundTransparency=1})end
if ac.nameLabel then b.Play(ac.nameLabel,"Smooth",{TextTransparency=1})end
if ac.backImage then b.Play(ac.backImage,"Smooth",{ImageTransparency=1})end
if ac.icon then b.Play(ac.icon,"Smooth",{ImageTransparency=1})end
if ac.stroke then b.Play(ac.stroke,"Smooth",{Transparency=1})end
if ac.shadow then b.Play(ac.shadow,"Smooth",{Transparency=1})end
if ac.gradient then b.StopSpin(ac.gradient)end
end

if aa.Header then b.Play(aa.Header,"Smooth",{TextTransparency=1})end
if aa.SearchBox then b.Play(aa.SearchBox,"Smooth",{TextTransparency=1})end
if aa.SelectedText then b.Play(aa.SelectedText,"Smooth",{TextTransparency=1})end
if aa.ConfirmBtn then
b.Play(aa.ConfirmBtn,"Smooth",{TextTransparency=1})
b.Play(aa.ConfirmBtn,"Smooth",{BackgroundTransparency=1})
end
if aa.ConfirmShadow then b.Play(aa.ConfirmShadow,"Smooth",{Transparency=1,BlurRadius=UDim.new(0,20)})end
if aa.CancelBtn then
b.Play(aa.CancelBtn,"Smooth",{TextTransparency=1})
b.Play(aa.CancelBtn,"Smooth",{BackgroundTransparency=1})
end
if aa.CancelShadow then b.Play(aa.CancelShadow,"Smooth",{Transparency=1})end
if aa.SelectAllBtn then
b.Play(aa.SelectAllBtn,"Smooth",{TextTransparency=1})
b.Play(aa.SelectAllBtn,"Smooth",{BackgroundTransparency=1})
end
if aa.SelectAllShadow then b.Play(aa.SelectAllShadow,"Smooth",{Transparency=1})end
if aa.SelectAllIcon then b.Play(aa.SelectAllIcon,"Smooth",{ImageTransparency=1})end
if aa.ClearBtn then
b.Play(aa.ClearBtn,"Smooth",{TextTransparency=1})
b.Play(aa.ClearBtn,"Smooth",{BackgroundTransparency=1})
end
if aa.ClearShadow then b.Play(aa.ClearShadow,"Smooth",{Transparency=1})end
if aa.ClearBtnIcon then b.Play(aa.ClearBtnIcon,"Smooth",{ImageTransparency=1})end
if aa.SearchIcon then b.Play(aa.SearchIcon,"Smooth",{ImageTransparency=1})end
if aa.Divider then b.Play(aa.Divider,"Smooth",{BackgroundTransparency=1})end
if aa.List then b.Play(aa.List,"Smooth",{ScrollBarImageTransparency=1})end
if aa.Shadow then b.Play(aa.Shadow,"Smooth",{Transparency=1})end
if aa.Popup then b.Play(aa.Popup,"Smooth",{BackgroundTransparency=1})end

if aa._hideTimer then
task.cancel(aa._hideTimer)
aa._hideTimer=nil
end
aa._hideTimer=task.delay(0.35,function()
if not aa.IsOpen and aa.Popup then
aa.Popup.Visible=false
end
aa._hideTimer=nil
end)
end
function k.Hide(aa)
if not aa.Popup then return end
aa.Popup.Visible=false
aa.IsOpen=false
if aa._inputConnection then
aa._inputConnection:Disconnect()
aa._inputConnection=nil
end

if aa._hideTimer then
task.cancel(aa._hideTimer)
aa._hideTimer=nil
end

if aa._scrollbarTimer then
task.cancel(aa._scrollbarTimer)
aa._scrollbarTimer=nil
end
end
function k.Destroy(aa)

if aa._inputConnection then
aa._inputConnection:Disconnect()
aa._inputConnection=nil
end
if aa._scrollConnection then
aa._scrollConnection:Disconnect()
aa._scrollConnection=nil
end
if aa.Popup then
aa.Popup:Destroy()
aa.Popup=nil
end

if aa._cleanupCallback then
aa._cleanupCallback()
aa._cleanupCallback=nil
end
end

function k._showScrollbar(aa)
if aa.List then
b.Play(aa.List,"Fast",{ScrollBarImageTransparency=0.5})

if aa._scrollbarTimer then
task.cancel(aa._scrollbarTimer)
aa._scrollbarTimer=nil
end

aa._scrollbarTimer=task.delay(1.5,function()
if aa.List then
b.Play(aa.List,"Fast",{ScrollBarImageTransparency=1})
end
aa._scrollbarTimer=nil
end)
end
end
return k
end
return g end function a.C():typeof(__modImpl())local aa=a.cache.C if not aa then aa={c=__modImpl()}a.cache.C=aa end return aa.c end end do local function __modImpl()








local aa=a.f()
local ab=a.a()a.b()

local ac={}
ac.__index=ac



local function clamp(ad,ae,af)
return math.max(ae,math.min(af,ad))
end
function ac.new(ad,ae,af)
ae=ae or{}
local ag=setmetatable({},ac)
local ah=ae.Theme
ag._theme=ah

local ai=Instance.new"Frame"
ai.Name="ColorPickerPopup"
ai.BorderSizePixel=0
ai.BackgroundColor3=(ah and ah.PopupBackgroundColor)
ai.BackgroundTransparency=(ah and ah.PopupBackgroundTransparency)or 1
ai.AnchorPoint=Vector2.new(0.5,0.5)
ai.Size=UDim2.new(0.694,0,1.02153,0)
ai.Position=UDim2.new(0.5,0,0.5,0)
ai.BorderColor3=Color3.fromRGB(0,0,0)
ai.Visible=false
ai.ZIndex=11
ai.Parent=ad
local aj=Instance.new"UIShadow"
aj.Color=(ah and ah.PopupShadowColor)
aj.BlurRadius=UDim.new(0,20)
aj.Transparency=1
aj.Parent=ai
local ak=Instance.new"UICorner"
ak.CornerRadius=UDim.new(0,6)
ak.Parent=ai
local al=Instance.new"UIScale"
al.Scale=0.9
al.Parent=ai

local am=Instance.new"TextLabel"
am.Name="Header"
am.BorderSizePixel=0
am.TextSize=16
am.TextXAlignment=Enum.TextXAlignment.Left
am.TextTransparency=(ah and ah.PopupTextTransparency)or 0.4
am.BackgroundColor3=Color3.fromRGB(255,255,255)
am.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
am.TextColor3=(ah and ah.PopupTextColor)
am.BackgroundTransparency=1
am.RichText=true
am.AnchorPoint=Vector2.new(0.5,0.5)
am.Size=UDim2.new(0.21429,0,0.03775,0)
am.AutomaticSize=Enum.AutomaticSize.X
am.Position=UDim2.new(0.5,0,0,25)
am.Parent=ai
am.Text="Color Picker"

local an=Instance.new"TextButton"
an.Name="ColorSquare"
an.AutoButtonColor=false
an.BackgroundTransparency=0
an.BackgroundColor3=Color3.fromRGB(255,255,255)
an.Text=""
an.Size=UDim2.new(0.44792,0,0.43228,0)
an.ClipsDescendants=false
an.Position=UDim2.new(0.0506,0,0.16117,0)
an.Parent=ai
local ao=Instance.new"UICorner"
ao.CornerRadius=UDim.new(0,4)
ao.Parent=an
local ap=Instance.new"UIShadow"
ap.Color=(ah and ah.PopupShadowColor)
ap.Parent=an




local aq=Instance.new"Frame"
aq.Name="SaturationOverlay"
aq.BackgroundColor3=Color3.fromRGB(255,0,0)
aq.BorderSizePixel=0
aq.Size=UDim2.new(1,0,1,0)
aq.Parent=an
local ar=Instance.new"UICorner"
ar.CornerRadius=UDim.new(0,4)
ar.Parent=aq
local b=Instance.new"UIGradient"
b.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(1.000,0),
}
b.Parent=aq
local c=Instance.new"Frame"
c.Name="ValueOverlay"
c.BackgroundColor3=Color3.fromRGB(0,0,0)
c.BorderSizePixel=0
c.Size=UDim2.new(1,0,1,0)
c.Parent=an
local d=Instance.new"UICorner"
d.CornerRadius=UDim.new(0,4)
d.Parent=c
local e=Instance.new"UIGradient"
e.Rotation=90
e.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(1.000,0),
}
e.Parent=c

local f=Instance.new"TextButton"
f.Name="Target"
f.BorderSizePixel=0
f.BackgroundColor3=Color3.fromRGB(255,0,0)
f.AnchorPoint=Vector2.new(0.5,0.5)
f.Size=UDim2.new(0,15,0,15)
f.Position=UDim2.new(0.5,0,0.5,0)
f.Active=true
f.AutoButtonColor=false
f.Parent=an
local g=Instance.new"UIStroke"
g.Transparency=0
g.Thickness=2
g.Color=Color3.fromRGB(255,255,255)
g.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
g.Parent=f
local h=Instance.new"UICorner"
h.CornerRadius=UDim.new(1,0)
h.Parent=f

local i=Instance.new"TextButton"
i.Name="ColorValue"
i.BorderSizePixel=0
i.BackgroundColor3=Color3.fromRGB(255,255,255)
i.AnchorPoint=Vector2.new(0.5,0.5)
i.Size=UDim2.new(0.938,0,0.04291,0)
i.LayoutOrder=1
i.BorderColor3=Color3.fromRGB(0,0,0)
i.Position=UDim2.new(0.5,0,0.66864,0)
i.Text=""
i.AutoButtonColor=false
i.ClipsDescendants=false
i.Parent=ai
local j=Instance.new"UIGradient"
j.Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.000,Color3.fromRGB(255,0,0)),
ColorSequenceKeypoint.new(0.160,Color3.fromRGB(255,255,0)),
ColorSequenceKeypoint.new(0.330,Color3.fromRGB(0,255,0)),
ColorSequenceKeypoint.new(0.500,Color3.fromRGB(0,255,255)),
ColorSequenceKeypoint.new(0.660,Color3.fromRGB(0,81,255)),
ColorSequenceKeypoint.new(0.830,Color3.fromRGB(171,0,255)),
ColorSequenceKeypoint.new(1.000,Color3.fromRGB(255,0,171))
}
j.Parent=i
local k=Instance.new"UICorner"
k.CornerRadius=UDim.new(0,6)
k.Parent=i
local l=Instance.new"UIShadow"
l.Color=(ah and ah.PopupShadowColor)
l.Parent=i

local m=Instance.new"TextButton"
m.Name="Slide"
m.BorderSizePixel=0
m.BackgroundColor3=Color3.fromRGB(255,0,0)
m.AnchorPoint=Vector2.new(0.5,0.5)
m.Size=UDim2.new(0,15,1,0)
m.Position=UDim2.new(0,0,0.5,0)
m.Active=true
m.AutoButtonColor=false
m.Parent=i
local n=Instance.new"UIStroke"
n.Transparency=0
n.Thickness=2
n.Color=Color3.fromRGB(255,255,255)
n.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
n.Parent=m
local o=Instance.new"UICorner"
o.CornerRadius=UDim.new(1,0)
o.Parent=m

local p=Instance.new"Frame"
p.Name="Inputs"
p.BorderSizePixel=0
p.BackgroundColor3=Color3.fromRGB(255,255,255)
p.AnchorPoint=Vector2.new(1,0.5)
p.Size=UDim2.new(0.39286,0,0.37207,0)
p.Position=UDim2.new(1,0,0.35319,0)
p.BackgroundTransparency=1
p.Parent=ai
local q=Instance.new"UIListLayout"
q.Padding=UDim.new(0,7)
q.HorizontalAlignment=Enum.HorizontalAlignment.Right
q.SortOrder=Enum.SortOrder.LayoutOrder
q.Parent=p

local r=Instance.new"UIPadding"
r.PaddingRight=UDim.new(0,10)
r.Parent=p

local function createInputRow(s,t,u,v)
local w=Instance.new"Frame"
w.Name=t
w.BorderSizePixel=0
w.BackgroundColor3=Color3.fromRGB(0,0,0)
w.BackgroundTransparency=1
w.AutomaticSize=Enum.AutomaticSize.XY
w.LayoutOrder=v
w.Parent=s
local x=Instance.new"UIListLayout"
x.Padding=UDim.new(0,15)
x.VerticalAlignment=Enum.VerticalAlignment.Center
x.HorizontalAlignment=Enum.HorizontalAlignment.Right
x.SortOrder=Enum.SortOrder.LayoutOrder
x.FillDirection=Enum.FillDirection.Horizontal
x.Parent=w
local y=Instance.new"TextLabel"
y.Name="InputName"
y.TextTruncate=Enum.TextTruncate.AtEnd
y.BorderSizePixel=0
y.TextSize=13
y.TextXAlignment=Enum.TextXAlignment.Left
y.TextTransparency=0.5
y.TextYAlignment=Enum.TextYAlignment.Top
y.BackgroundColor3=Color3.fromRGB(255,255,255)
y.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
y.TextColor3=(ah and ah.PopupTextColor)or Color3.fromRGB(255,255,255)
y.BackgroundTransparency=1
y.AnchorPoint=Vector2.new(0,0.5)
y.BorderColor3=Color3.fromRGB(0,0,0)
y.Text=t
y.LayoutOrder=1
y.AutomaticSize=Enum.AutomaticSize.Y
y.Size=UDim2.new(0,40,0,0)
y.Position=UDim2.new(0,0,0.5,0)
y.Parent=w
local z=Instance.new"TextBox"
z.Name="InputBox"
z.TextXAlignment=Enum.TextXAlignment.Left
z.BorderSizePixel=0
z.TextTransparency=0.5
z.TextSize=12
z.TextColor3=(ah and ah.PopupTextColor)or Color3.fromRGB(255,255,255)
z.BackgroundColor3=(ah and ah.PopupBackgroundColor)or Color3.fromRGB(255,255,255)
z.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
z.AnchorPoint=Vector2.new(1,0.5)
z.ClearTextOnFocus=false
z.ClipsDescendants=true
z.Size=UDim2.new(0,75,0,25)
z.Position=UDim2.new(1,0,0.5,0)
z.BorderColor3=Color3.fromRGB(0,0,0)
z.Text=u
z.LayoutOrder=2
z.BackgroundTransparency=1
z.Parent=w
local A=Instance.new"UICorner"
A.Name="InputBoxUICorner"
A.CornerRadius=UDim.new(0,4)
A.Parent=z
local B=Instance.new"UIStroke"
B.Name="InputBoxUIStroke"
B.Transparency=(ah and ah.StrokeTransparency)or 0.95
B.Color=(ah and ah.StrokeColor)or Color3.fromRGB(255,255,255)
B.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
B.Parent=z
local C=Instance.new"UIPadding"
C.Name="InputBoxUIPadding"
C.PaddingRight=UDim.new(0,10)
C.PaddingLeft=UDim.new(0,8)
C.Parent=z
return w,z,B
end
local s,t,u=createInputRow(p,"Red","255",1)
local v,w,x=createInputRow(p,"Green","255",2)
local y,z,A=createInputRow(p,"Blue","255",3)
local B,C,D=createInputRow(p,"Hex","#FFFFFF",4)

local E=Instance.new"Frame"
E.Name="ColorWells"
E.BorderSizePixel=0
E.BackgroundColor3=Color3.fromRGB(255,255,255)
E.AnchorPoint=Vector2.new(0.5,0.5)
E.AutomaticSize=Enum.AutomaticSize.Y
E.Size=UDim2.new(0.9375,0,0.08267,0)
E.Position=UDim2.new(0.5,0,0.76301,0)
E.BackgroundTransparency=1
E.Parent=ai
local F=Instance.new"UIGridLayout"
F.CellSize=UDim2.new(0.5,-5,0,30)
F.SortOrder=Enum.SortOrder.LayoutOrder
F.CellPadding=UDim2.new(0,10,0,0)
F.Parent=E


local function createColorWell(G,H,I)
local J=Instance.new"Frame"
J.Name=H
J.BorderSizePixel=0
J.BackgroundColor3=Color3.fromRGB(255,255,255)
J.BackgroundTransparency=0
J.Size=UDim2.new(0,100,0,100)
J.LayoutOrder=I
J.Parent=G
local K=Instance.new"UICorner"
K.CornerRadius=UDim.new(0,6)
K.Parent=J
return J
end
local G=createColorWell(E,"OldColor",1)
local H=createColorWell(E,"NewColor",0)

local I=Instance.new"Frame"
I.Name="Interactions"
I.BorderSizePixel=0
I.BackgroundColor3=Color3.fromRGB(255,255,255)
I.AnchorPoint=Vector2.new(0.5,0.5)
I.Size=UDim2.new(0.9375,0,0.13562,0)
I.Position=UDim2.new(0.5,0,0.90934,0)
I.BackgroundTransparency=1
I.Parent=ai
local J=Instance.new"TextButton"
J.Name="Confirm"
J.BorderSizePixel=0
J.TextTransparency=0.2
J.TextStrokeColor3=Color3.fromRGB(255,255,255)
J.TextSize=12
J.AutoButtonColor=false
J.TextColor3=(ah and ah.PopupTextColor)or Color3.fromRGB(255,255,255)
J.BackgroundColor3=(ah and ah.PrimaryColor)or Color3.fromRGB(14,45,178)
J.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
J.AnchorPoint=Vector2.new(0.5,0)
J.Size=UDim2.new(1,0,0.43911,0)
J.Position=UDim2.new(0.5,0,0,0)
J.Text="Confirm"
J.Parent=I
local K=Instance.new"UICorner"
K.CornerRadius=UDim.new(0,4)
K.Parent=J
local L=Instance.new"UIShadow"
L.BlurRadius=UDim.new(0,20)
L.Color=(ah and ah.PrimaryColor)or Color3.fromRGB(13,44,177)
L.Transparency=1
L.Parent=J
local M=Instance.new"TextButton"
M.Name="Cancel"
M.BorderSizePixel=0
M.TextTransparency=0.5
M.TextStrokeColor3=Color3.fromRGB(255,255,255)
M.TextSize=12
M.AutoButtonColor=false
M.TextColor3=(ah and ah.PopupTextColor)or Color3.fromRGB(255,255,255)
M.BackgroundColor3=(ah and ah.PopupNeutralColor)or Color3.fromRGB(46,46,46)
M.BackgroundTransparency=0.5
M.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
M.AnchorPoint=Vector2.new(0.5,1)
M.Size=UDim2.new(1,0,0.43882,0)
M.Position=UDim2.new(0.5,0,1,0)
M.Text="Cancel"
M.Parent=I
local N=Instance.new"UICorner"
N.CornerRadius=UDim.new(0,4)
N.Parent=M
local O=Instance.new"UIShadow"
O.BlurRadius=UDim.new(0,20)
O.Color=(ah and ah.PopupNeutralColor)or Color3.fromRGB(0,0,0)
O.Transparency=1
O.Parent=M

ag.Popup=ai
ag.Shadow=aj
ag.Header=am
ag.ColorSquare=an
ag.SatOverlay=aq
ag.ValOverlay=c
ag.Target=f
ag.ColorValue=i
ag.Slide=m
ag.ValueGradient=j
ag.Inputs={
Red={Row=s,Input=t,Stroke=u},
Green={Row=v,Input=w,Stroke=x},
Blue={Row=y,Input=z,Stroke=A},
Hex={Row=B,Input=C,Stroke=D},
}
ag.OldWell=G
ag.NewWell=H
ag.ConfirmBtn=J
ag.ConfirmShadow=L
ag.CancelBtn=M
ag.CancelShadow=O
ag._cleanupCallback=af

ag.OnConfirm=function()end
ag.OnCancel=function()end

ag._currentColor=Color3.fromRGB(255,255,255)
ag._oldColor=Color3.fromRGB(255,255,255)
ag._hue=0
ag._sat=0
ag._val=1
ag._isOpen=false
ag._resolved=false
ag._inputConnection=nil
ag._hideTimer=nil




local function refreshVisuals()
local P,Q,R=ag._hue,ag._sat,ag._val
local S=Color3.fromHSV(P,1,1)
ag.SatOverlay.BackgroundColor3=S
ag.Slide.BackgroundColor3=S
ag.Target.BackgroundColor3=Color3.fromHSV(P,Q,R)
ag.Target.Position=UDim2.new(Q,0,1-R,0)
ag.Slide.Position=UDim2.new(P,0,0.5,0)
ag.NewWell.BackgroundColor3=Color3.fromHSV(P,Q,R)
ag.OldWell.BackgroundColor3=ag._oldColor
end

local function refreshInputsFromState()
local P=Color3.fromHSV(ag._hue,ag._sat,ag._val)
local Q=math.round(P.R*255)
local R=math.round(P.G*255)
local S=math.round(P.B*255)
ag.Inputs.Red.Input.Text=tostring(Q)
ag.Inputs.Green.Input.Text=tostring(R)
ag.Inputs.Blue.Input.Text=tostring(S)
ag.Inputs.Hex.Input.Text=string.format("#%02X%02X%02X",Q,R,S)
end
function ag._setColorAndUpdate(P,Q)
P._currentColor=Q
P._hue,P._sat,P._val=Q:ToHSV()
refreshVisuals()
refreshInputsFromState()
end



function ag._setHSVAndUpdate(P,Q,R,S)
P._hue=math.clamp(Q,0,1)
P._sat=math.clamp(R,0,1)
P._val=math.clamp(S,0,1)
P._currentColor=Color3.fromHSV(P._hue,P._sat,P._val)
refreshVisuals()
refreshInputsFromState()
end
function ag.SetContent(P,Q)
local R=Q.Title or"Color Picker"
local S=Q.CurrentColor
P.OnConfirm=Q.OnConfirm or function()end
P.OnCancel=Q.OnCancel or function()end
P.Header.Text=R
P._oldColor=S
P._currentColor=S
P._resolved=false
P:_setColorAndUpdate(S)
P.OldWell.BackgroundColor3=S
end



function ag.ApplyTheme(P,Q)
if not P.Popup then return end
Q=aa.GetTheme(Q)
P._theme=Q
P.Popup.BackgroundColor3=Q.PopupBackgroundColor or P.Popup.BackgroundColor3
if P.Shadow then P.Shadow.Color=Q.PopupShadowColor or P.Shadow.Color end
P.Header.TextColor3=Q.PopupTextColor or P.Header.TextColor3
for R,S in pairs(P.Inputs)do
S.Input.TextColor3=Q.PopupTextColor or S.Input.TextColor3
S.Input.BackgroundColor3=Q.PopupBackgroundColor or S.Input.BackgroundColor3
S.Stroke.Color=Q.StrokeColor or S.Stroke.Color
local T=S.Row:FindFirstChild"InputName"
if T then T.TextColor3=Q.PopupTextColor or T.TextColor3 end
end
local R=P.ColorSquare:FindFirstChildOfClass"UIShadow"
if R then R.Color=Q.PopupShadowColor or R.Color end
local S=P.ColorValue:FindFirstChildOfClass"UIShadow"
if S then S.Color=Q.PopupShadowColor or S.Color end

local T=P.Target:FindFirstChildOfClass"UIStroke"
if T then T.Color=Color3.fromRGB(255,255,255);T.Transparency=0 end
local U=P.Slide:FindFirstChildOfClass"UIStroke"
if U then U.Color=Color3.fromRGB(255,255,255);U.Transparency=0 end
P.ConfirmBtn.TextColor3=Q.PopupTextColor or P.ConfirmBtn.TextColor3
P.ConfirmBtn.BackgroundColor3=Q.PrimaryColor or P.ConfirmBtn.BackgroundColor3
P.ConfirmShadow.Color=Q.PrimaryColor or P.ConfirmShadow.Color
P.CancelBtn.TextColor3=Q.PopupTextColor or P.CancelBtn.TextColor3
P.CancelBtn.BackgroundColor3=Q.PopupNeutralColor or P.CancelBtn.BackgroundColor3
P.CancelShadow.Color=Q.PopupNeutralColor or P.CancelShadow.Color
end
function ag.Open(P)
if not P.Popup then return end
if P._hideTimer then
task.cancel(P._hideTimer)
P._hideTimer=nil
end
P.IsOpen=true
P._isOpen=true
P._resolved=false
P.Popup.Visible=true
P.Popup.BackgroundTransparency=1
P.Shadow.Transparency=1
local function resetTransparency(Q)
if Q:IsA"TextLabel"or Q:IsA"TextButton"or Q:IsA"TextBox"then
Q.TextTransparency=1
end
if Q:IsA"ImageLabel"or Q:IsA"ImageButton"then
Q.ImageTransparency=1
end
if Q:IsA"Frame"and Q~=P.Popup and Q~=P.Shadow then
Q.BackgroundTransparency=1
end
if Q:IsA"UIStroke"then
Q.Transparency=1
end
if Q:IsA"UIShadow"then
Q.Transparency=1
end
for R,S in ipairs(Q:GetChildren())do
resetTransparency(S)
end
end
resetTransparency(P.Popup)



P.ColorSquare.BackgroundTransparency=0
P.SatOverlay.BackgroundTransparency=0
P.ValOverlay.BackgroundTransparency=0
P.ColorValue.BackgroundTransparency=0
P.Target.BackgroundTransparency=0
P.Slide.BackgroundTransparency=0
P.OldWell.BackgroundTransparency=0
P.NewWell.BackgroundTransparency=0

local Q=P.Target:FindFirstChildOfClass"UIStroke"
if Q then Q.Color=Color3.fromRGB(255,255,255);Q.Transparency=0 end
local R=P.Slide:FindFirstChildOfClass"UIStroke"
if R then R.Color=Color3.fromRGB(255,255,255);R.Transparency=0 end


local S=aa.GetTheme(P._theme)
local T=S.StrokeTransparency or 0.95
for U,V in pairs(P.Inputs)do
V.Stroke.Color=S.StrokeColor or Color3.fromRGB(255,255,255)
V.Stroke.Transparency=T
end
ab.Play(P.Popup,"Smooth",{BackgroundTransparency=0.07})
ab.Play(P.Shadow,"Smooth",{Transparency=0.5})
ab.Play(P.Header,"Smooth",{TextTransparency=0.4})
ab.Play(P.SatOverlay,"Smooth",{BackgroundTransparency=0})
ab.Play(P.ValOverlay,"Smooth",{BackgroundTransparency=0})
ab.Play(P.ColorValue,"Smooth",{BackgroundTransparency=0})
for U,V in pairs(P.Inputs)do
ab.Play(V.Input,"Smooth",{TextTransparency=0.5})
local W=V.Row:FindFirstChild"InputName"
if W then ab.Play(W,"Smooth",{TextTransparency=0.5})end
end
ab.Play(P.ConfirmBtn,"Smooth",{TextTransparency=0.2,BackgroundTransparency=0})
ab.Play(P.CancelBtn,"Smooth",{TextTransparency=0.5,BackgroundTransparency=0.5})
ab.Play(P.ConfirmShadow,"Smooth",{Transparency=0.5})
P:_setColorAndUpdate(P._currentColor)
local U=game:GetService"UserInputService"

if P._inputConnection then
P._inputConnection:Disconnect()
P._inputConnection=nil
end
local function onInputBegan(V,W)
if W then return end
if V.UserInputType==Enum.UserInputType.MouseButton1 or V.UserInputType==Enum.UserInputType.Touch then
local X=V.Position
local Y=P.Popup.AbsolutePosition
local Z=P.Popup.AbsoluteSize
local _=X.X>=Y.X and X.X<=Y.X+Z.X
and X.Y>=Y.Y and X.Y<=Y.Y+Z.Y
if not _ then
P:_Confirm()
end
end
end
P._inputConnection=U.InputBegan:Connect(onInputBegan)
end
function ag.Close(P)
if not P.Popup or not P.IsOpen then return end
P.IsOpen=false
P._isOpen=false
if P._inputConnection then
P._inputConnection:Disconnect()
P._inputConnection=nil
end
if P._hideTimer then
task.cancel(P._hideTimer)
P._hideTimer=nil
end
ab.Play(P.Popup,"Smooth",{BackgroundTransparency=1})
ab.Play(P.Shadow,"Smooth",{Transparency=1})
local function fadeObject(Q)
local R={}
if Q:IsA"TextLabel"or Q:IsA"TextButton"or Q:IsA"TextBox"then
R.TextTransparency=1
R.BackgroundTransparency=1
end
if Q:IsA"ImageLabel"or Q:IsA"ImageButton"then
R.ImageTransparency=1
R.BackgroundTransparency=1
end
if Q:IsA"Frame"and Q~=P.Popup then
R.BackgroundTransparency=1
end
if Q:IsA"UIStroke"then
R.Transparency=1
end
if Q:IsA"UIShadow"then
R.Transparency=1
end
if next(R)then
ab.Play(Q,"Smooth",R)
end
end
for Q,R in ipairs(P.Popup:GetDescendants())do
fadeObject(R)
end
ab.Play(P.Popup:FindFirstChildOfClass"UIScale","Smooth",{Scale=0.9})
P._hideTimer=task.delay(0.35,function()
if P.Popup and not P.IsOpen then
P.Popup.Visible=false
end
P._hideTimer=nil
end)
end
function ag._Confirm(P)
if P._resolved then return end
P._resolved=true
P:Close()
P.OnConfirm(P._currentColor)
end
function ag._Cancel(P)
if P._resolved then return end
P._resolved=true
P:Close()
P.OnCancel()
end

function ag.Hide(P)
P:Close()
end
function ag.Destroy(P)
if P._inputConnection then
P._inputConnection:Disconnect()
P._inputConnection=nil
end
if P._dragChangedConnection then
P._dragChangedConnection:Disconnect()
P._dragChangedConnection=nil
end
if P._dragEndedConnection then
P._dragEndedConnection:Disconnect()
P._dragEndedConnection=nil
end
if P.Popup then
P.Popup:Destroy()
P.Popup=nil
end
if P._cleanupCallback then
P._cleanupCallback()
P._cleanupCallback=nil
end
end

ag.ConfirmBtn.MouseButton1Click:Connect(function()ag:_Confirm()end)
ag.CancelBtn.MouseButton1Click:Connect(function()ag:_Cancel()end)
ag.ConfirmBtn.MouseEnter:Connect(function()
ab.Play(ag.ConfirmShadow,"Smooth",{BlurRadius=UDim.new(0,50),Transparency=0})
end)
ag.ConfirmBtn.MouseLeave:Connect(function()
ab.Play(ag.ConfirmShadow,"Smooth",{BlurRadius=UDim.new(0,20),Transparency=1})
end)
ag.CancelBtn.MouseEnter:Connect(function()
ab.Play(ag.CancelBtn,"Smooth",{TextTransparency=0.2})
end)
ag.CancelBtn.MouseLeave:Connect(function()
ab.Play(ag.CancelBtn,"Smooth",{TextTransparency=0.5})
end)

local function setFromSquarePosition(P)
local Q=ag.ColorSquare.AbsoluteSize
if Q.X<=0 or Q.Y<=0 then return end
local R=ag.ColorSquare.AbsolutePosition
local S=clamp((P.X-R.X)/Q.X,0,1)
local T=clamp((P.Y-R.Y)/Q.Y,0,1)


ag:_setHSVAndUpdate(ag._hue,S,1-T)
end
local function setFromHuePosition(P)
local Q=ag.ColorValue.AbsoluteSize
if Q.X<=0 then return end
local R=ag.ColorValue.AbsolutePosition
local S=clamp((P.X-R.X)/Q.X,0,1)
ag:_setHSVAndUpdate(S,ag._sat,ag._val)
end



local P=game:GetService"UserInputService"
local Q=false
local R=false
an.InputBegan:Connect(function(S)
if S.UserInputType==Enum.UserInputType.MouseButton1 or S.UserInputType==Enum.UserInputType.Touch then
Q=true
setFromSquarePosition(S.Position)
end
end)
i.InputBegan:Connect(function(S)
if S.UserInputType==Enum.UserInputType.MouseButton1 or S.UserInputType==Enum.UserInputType.Touch then
R=true
setFromHuePosition(S.Position)
end
end)



ag._dragChangedConnection=P.InputChanged:Connect(function(S)
if S.UserInputType==Enum.UserInputType.MouseMovement or S.UserInputType==Enum.UserInputType.Touch then
if Q then
setFromSquarePosition(S.Position)
elseif R then
setFromHuePosition(S.Position)
end
end
end)
ag._dragEndedConnection=P.InputEnded:Connect(function(S)
if S.UserInputType==Enum.UserInputType.MouseButton1 or S.UserInputType==Enum.UserInputType.Touch then
Q=false
R=false
end
end)

local function onFocusLost(S,T)
S.FocusLost:Connect(function()
local U=S.Text
if T=="Hex"then

local V=U:gsub("#","")
if#V==6 then
local W=tonumber(V:sub(1,2),16)
local X=tonumber(V:sub(3,4),16)
local Y=tonumber(V:sub(5,6),16)
if W and X and Y then
ag:_setColorAndUpdate(Color3.fromRGB(W,X,Y))
end
end
else
local V=tonumber(U)
if V~=nil then
local W,X,Y
if T=="Red"then
W=math.clamp(V,0,255)
X=ag._currentColor.G*255
Y=ag._currentColor.B*255
ag:_setColorAndUpdate(Color3.fromRGB(W,X,Y))
elseif T=="Green"then
W=ag._currentColor.R*255
X=math.clamp(V,0,255)
Y=ag._currentColor.B*255
ag:_setColorAndUpdate(Color3.fromRGB(W,X,Y))
elseif T=="Blue"then
W=ag._currentColor.R*255
X=ag._currentColor.G*255
Y=math.clamp(V,0,255)
ag:_setColorAndUpdate(Color3.fromRGB(W,X,Y))
end
end
end
end)
end
for S,T in pairs(ag.Inputs)do
onFocusLost(T.Input,S)
local function setStrokeBright(U)



local V=aa.GetTheme(ag._theme)
local W=V.StrokeTransparency or 0.95
local X=V.StrokeColor or Color3.fromRGB(255,255,255)
local Y=U and 0.3 or W
local Z=U and(V.PrimaryColor or X)or X
ab.Play(T.Stroke,"Fast",{Transparency=Y,Color=Z})
end
T.Input.MouseEnter:Connect(function()setStrokeBright(true)end)
T.Input.MouseLeave:Connect(function()
if not T.Input:IsFocused()then setStrokeBright(false)end
end)
T.Input.Focused:Connect(function()setStrokeBright(true)end)
T.Input.FocusLost:Connect(function()setStrokeBright(false)end)
end
return ag
end
return ac end function a.D():typeof(__modImpl())local aa=a.cache.D if not aa then aa={c=__modImpl()}a.cache.D=aa end return aa.c end end do local function __modImpl()








local aa=a.a()
local ab=a.f()

local ac={}
ac.__index=ac

local ad=0.15

function ac.new(ae,af)
af=ab.GetTheme(af)
local ag=setmetatable({},ac)

local ah=Instance.new"Frame"
ah.Name="Tooltip"
ah.BorderSizePixel=0
ah.BackgroundColor3=af.PopupBackgroundColor or Color3.fromRGB(15,15,16)
ah.BackgroundTransparency=1
ah.AutomaticSize=Enum.AutomaticSize.XY
ah.Size=UDim2.new(0,0,0,0)
ah.ZIndex=2000
ah.Visible=false
ah.Parent=ae
ag.Root=ah

local ai=Instance.new"UICorner"
ai.CornerRadius=UDim.new(0,6)
ai.Parent=ah

local aj=Instance.new"UIStroke"
aj.Color=af.StrokeColor or Color3.fromRGB(255,255,255)
aj.Transparency=0.85
aj.Thickness=1
aj.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
aj.Parent=ah

local ak=Instance.new"UIShadow"
ak.Color=af.PopupShadowColor or Color3.fromRGB(0,0,0)
ak.BlurRadius=UDim.new(0,12)
ak.Transparency=1
ak.Parent=ah
ag._stroke=aj
ag._shadow=ak

local al=Instance.new"UIPadding"
al.PaddingTop=UDim.new(0,5)
al.PaddingBottom=UDim.new(0,5)
al.PaddingLeft=UDim.new(0,9)
al.PaddingRight=UDim.new(0,9)
al.Parent=ah

local am=Instance.new"TextLabel"
am.Name="Label"
am.BorderSizePixel=0
am.BackgroundTransparency=1
am.AutomaticSize=Enum.AutomaticSize.XY
am.Size=UDim2.new(0,0,0,0)
am.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
am.TextSize=12
am.TextColor3=af.PopupTextColor or Color3.fromRGB(255,255,255)
am.TextTransparency=1
am.Text=""
am.TextXAlignment=Enum.TextXAlignment.Center
am.TextYAlignment=Enum.TextYAlignment.Center
am.Parent=ah
ag.Label=am

ag._shown=false
ag._theme=af
ag._surface=af.PopupBackgroundTransparency~=nil and math.max(af.PopupBackgroundTransparency,0.05)or 0.05
return ag
end

function ac.SetTheme(ae,af)
af=ab.GetTheme(af)
ae._theme=af
ae._surface=af.PopupBackgroundTransparency~=nil and math.max(af.PopupBackgroundTransparency,0.05)or 0.05
ae.Root.BackgroundColor3=af.PopupBackgroundColor or Color3.fromRGB(15,15,16)
ae.Label.TextColor3=af.PopupTextColor or Color3.fromRGB(255,255,255)
local ag=ae.Root:FindFirstChildOfClass"UIStroke"
if ag then ag.Color=af.StrokeColor or Color3.fromRGB(255,255,255)end
local ah=ae.Root:FindFirstChildOfClass"UIShadow"
if ah then ah.Color=af.PopupShadowColor or Color3.fromRGB(0,0,0)end
end


function ac.ShowAt(ae,af,ag,ah,ai)
if not af or not af.Parent then return end
ai=ai or 8
ah=ah or"Left"
ae.Label.Text=ag or""

local aj=af.AbsolutePosition
local ak=af.AbsoluteSize
local al=aj.X+ak.X/2
local am=aj.Y+ak.Y/2

local an=UDim2.new(0,al,0,am)
local ao=Vector2.new(0.5,0.5)
if ah=="Left"then
an=UDim2.new(0,aj.X-ai,0,am)
ao=Vector2.new(1,0.5)
elseif ah=="Right"then
an=UDim2.new(0,aj.X+ak.X+ai,0,am)
ao=Vector2.new(0,0.5)
elseif ah=="Top"then
an=UDim2.new(0,al,0,aj.Y-ai)
ao=Vector2.new(0.5,1)
elseif ah=="Bottom"then
an=UDim2.new(0,al,0,aj.Y+ak.Y+ai)
ao=Vector2.new(0.5,0)
end

ae.Root.AnchorPoint=ao
ae.Root.Position=an
ae.Root.Visible=true
ae._shown=true
local ap=TweenInfo.new(ad)
aa.Play(ae.Root,ap,{BackgroundTransparency=ae._surface or 0.05})
aa.Play(ae.Label,ap,{TextTransparency=ae._theme and(ae._theme.PopupTextTransparency or 0)or 0})
if ae._stroke then aa.Play(ae._stroke,ap,{Transparency=0.85})end
if ae._shadow then aa.Play(ae._shadow,ap,{Transparency=0.5})end
end

function ac.Hide(ae)
if not ae._shown then return end
ae._shown=false
local af=TweenInfo.new(ad)
aa.Play(ae.Root,af,{BackgroundTransparency=1})
aa.Play(ae.Label,af,{TextTransparency=1})
if ae._stroke then aa.Play(ae._stroke,af,{Transparency=1})end
if ae._shadow then aa.Play(ae._shadow,af,{Transparency=1})end
task.delay(ad,function()
if not ae._shown and ae.Root then
ae.Root.Visible=false
end
end)
end

return ac end function a.E():typeof(__modImpl())local aa=a.cache.E if not aa then aa={c=__modImpl()}a.cache.E=aa end return aa.c end end do local function __modImpl()









local aa=a.a()
local ab=a.y()
local ac=a.l().FallbackImage
local ad=a.f()
local ae=a.o()

local af={}
af.__index=af

local ag={}
ag.__index=ag

function ag.Section(ah,ai)
ai=ai or{}
return ab.new(ah.Page,ai,ah._theme)
end

function af.new(ah,ai)
ai=ad.GetTheme(ai)
local aj=setmetatable({},af)
aj.Window=ah
aj._theme=ai or{}
aj.Tabs={}
aj.ActiveTab=nil
aj._fadeCaches={}
aj._transitioning=false
aj._spinHandles={}


aj.Bar=Instance.new"Frame"
aj.Bar.Name="SettingsTabBar"
aj.Bar.BorderSizePixel=0
aj.Bar.BackgroundTransparency=1
aj.Bar.Size=UDim2.new(1,0,0.07969,0)
aj.Bar.Position=UDim2.new(0,0,0,0)
aj.Bar.BorderColor3=Color3.fromRGB(0,0,0)
aj.Bar.Parent=ah.SettingsPages

local ak=Instance.new"UIListLayout"
ak.Padding=UDim.new(0,12)
ak.VerticalAlignment=Enum.VerticalAlignment.Center
ak.SortOrder=Enum.SortOrder.LayoutOrder
ak.FillDirection=Enum.FillDirection.Horizontal
ak.Parent=aj.Bar

local al=Instance.new"UIPadding"
al.PaddingLeft=UDim.new(0,7)
al.Parent=aj.Bar


aj.Content=Instance.new"Frame"
aj.Content.Name="SettingsContent"
aj.Content.BorderSizePixel=0
aj.Content.BackgroundTransparency=1
aj.Content.AnchorPoint=Vector2.new(0.5,0.5)
aj.Content.Position=UDim2.new(0.5,0,0.5,0)
aj.Content.Size=UDim2.new(0.983,0,1,0)
aj.Content.BorderColor3=Color3.fromRGB(0,0,0)
aj.Content.Parent=ah.SettingsPages




ad.Register(aj.Bar,aj)

return aj
end





function af._captureCache(ah,ai)
local aj={}
local function scan(ak)

if ak:IsA"UIGradient"and ak:GetAttribute"IsVideoFade"then
table.insert(aj,{instance=ak,isVideo=true,base=ae.get(ak)})
return
end
local al={}
local function addProp(am)
local an,ao=pcall(function()return ak[am]end)
if an and ao~=nil then
table.insert(al,{am,ao})
end
end
if ak:IsA"GuiObject"then
addProp"BackgroundTransparency"
addProp"TextTransparency"
addProp"ImageTransparency"
end
if ak:IsA"UIStroke"or ak:IsA"UIShadow"then
addProp"Transparency"
end
if#al>0 then
table.insert(aj,{instance=ak,props=al})
end
for am,an in ipairs(ak:GetChildren())do
scan(an)
end
end
scan(ai.Page)
return aj
end




function af._getFadeCache(ah,ai)
if not ai._faded then
ai._cache=ah:_captureCache(ai)
end
return ai._cache or{}
end




function af._fadeElements(ah,ai,aj,ak,al)
if not ai or#ai==0 then
if ak then ak()end
return
end
local am=0
local an=0
local function onComplete()
an=an+1
if an>=am and ak then
ak()
end
end
for ao,ap in ipairs(ai)do
local aq=ap.instance
if ap.isVideo then
if aq.Parent then
local ar=aj
if ar==nil then ar=ap.base end
if al then
ae.set(aq,ar)
else
am=am+1
ae.fade(aq,ar,0.2,"Out",onComplete)
end
end
elseif aq.Parent then
for ar,b in ipairs(ap.props)do
local c=b[1]
local d=b[2]
local e=aj
if e==nil then
e=d
end
if al then
aq[c]=e
elseif aq[c]~=e then
am=am+1
local f=aa.Play(aq,"Fast",{[c]=e})
f.Tween.Completed:Connect(onComplete)
end
end
end
end
if am==0 and ak then
ak()
end
end



function af._pauseSpin(ah,ai)
aa.StopSpin(ai)
end

function af._resumeSpin(ah,ai,aj)


aa.StartSpin(ai,{Rotation=360},"SpinIdle")
end

function af.Tab(ah,ai)
ai=ai or{}
local aj=ai.Name or"Settings"
local ak=#ah.Tabs==0
local al=ah._theme or{}


local am=Instance.new"TextButton"
am.Name=aj.."SettingsTab"
am.BorderSizePixel=0
am.AutoButtonColor=false
am.BackgroundColor3=al.InactiveTabButtonColor
am.BackgroundTransparency=al.InactiveTabButtonTransparency
am.Size=UDim2.new(0.169,0,0.83,0)
am.BorderColor3=Color3.fromRGB(0,0,0)
am.Text=""
am.LayoutOrder=#ah.Tabs+1
am.Parent=ah.Bar

local an=Instance.new"UICorner"
an.CornerRadius=UDim.new(0,4)
an.Parent=am

local ao=Instance.new"TextLabel"
ao.Name="TabName"
ao.BorderSizePixel=0
ao.TextSize=11
ao.TextXAlignment=Enum.TextXAlignment.Left
ao.TextTransparency=al.InactiveTabTextTransparency
ao.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
ao.TextColor3=al.InactiveTabTextColor
ao.BackgroundTransparency=1
ao.AnchorPoint=Vector2.new(0.5,0.5)
ao.Size=UDim2.new(0.73078,0,0.71359,0)
ao.BorderColor3=Color3.fromRGB(0,0,0)
ao.Text=aj
ao.Position=UDim2.new(0.647,0,0.5,0)
ao.Parent=am

local ap=Instance.new"ImageLabel"
ap.Name="BackImage"
ap.BorderSizePixel=0
ap.BackgroundColor3=Color3.fromRGB(255,255,255)
ap.ImageTransparency=1
ap.AnchorPoint=Vector2.new(0.5,0.5)
ap.Image=al.Wallpaper or ac
ap.Size=UDim2.new(1,0,1,0)
ap.BorderColor3=Color3.fromRGB(0,0,0)
ap.BackgroundTransparency=1
ap.Position=UDim2.new(0.5,0,0.5,0)
ap.Parent=am
ap:SetAttribute("IsTabBackdrop",true)
ap.Visible=al.WallpaperEnabled

local aq=Instance.new"UICorner"
aq.CornerRadius=UDim.new(0,4)
aq.Parent=ap

local ar=Instance.new"UIGradient"
ar.Rotation=0
ar.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0),
NumberSequenceKeypoint.new(0.134,0.3),
NumberSequenceKeypoint.new(0.242,0.53125),
NumberSequenceKeypoint.new(0.371,0.69375),
NumberSequenceKeypoint.new(0.484,0.80625),
NumberSequenceKeypoint.new(0.590,0.91875),
NumberSequenceKeypoint.new(0.681,0.975),
NumberSequenceKeypoint.new(1.000,1),
}
ar.Parent=ap

local b=Instance.new"ImageLabel"
b.Name="TabImage"
b.BorderSizePixel=0
b.BackgroundColor3=Color3.fromRGB(255,255,255)
b.ImageTransparency=al.InactiveTabIconTransparency
b.AnchorPoint=Vector2.new(0,0.5)
b.Image=ai.Icon or"rbxassetid://8445470392"
b.ImageColor3=al.InactiveTabIconColor
b.Size=UDim2.new(0,12,0,12)
b.BorderColor3=Color3.fromRGB(0,0,0)
b.BackgroundTransparency=1
b.Position=UDim2.new(0,6,0.5,0)
b.Parent=am

local c=Instance.new"Frame"
c.Name="SelectionStatus"
c.BorderSizePixel=0
c.BackgroundColor3=al.SecondaryColor
c.BackgroundTransparency=1
c.AnchorPoint=Vector2.new(0.5,0.5)
c.Size=UDim2.new(0,2,0,0)
c.Position=UDim2.new(0,-5,0.5,0)
c.BorderColor3=Color3.fromRGB(0,0,0)
c.Parent=am


local d=Instance.new"Frame"
d.Name=aj
d.BorderSizePixel=0
d.BackgroundTransparency=1
d.Size=UDim2.new(1,0,1,0)
d.BorderColor3=Color3.fromRGB(0,0,0)
d.Visible=false
d.Parent=ah.Content

local e=setmetatable({
Name=aj,
Button=am,
TabName=ao,
BackImage=ap,
BackImageGradient=ar,
TabImage=b,
SelectionStatus=c,
Page=d,
_theme=al,
},ag)

am.MouseButton1Click:Connect(function()
ah:SetActiveTab(e)
end)

table.insert(ah.Tabs,e)

if ai.Active or ak then
ah:SetActiveTab(e)
end

return e
end

function af._applyActiveVisuals(ah,ai)
local aj=ah._theme or{}
aa.Play(ai.Button,"Fast",{BackgroundColor3=aj.ActiveTabButtonColor,BackgroundTransparency=aj.ActiveTabButtonTransparency})
aa.Play(ai.TabName,"Fast",{TextTransparency=aj.ActiveTabTextTransparency or 0.2,TextColor3=aj.ActiveTabTextColor or Color3.fromRGB(255,255,255)})
ai.BackImage.Visible=aj.WallpaperEnabled
aa.Play(ai.BackImage,"Fast",{ImageTransparency=0})
aa.Play(ai.TabImage,"Fast",{ImageTransparency=aj.ActiveTabIconTransparency or 0.2,ImageColor3=aj.ActiveTabIconColor or Color3.fromRGB(255,255,255)})
aa.Play(ai.SelectionStatus,"OnOff",{BackgroundTransparency=0,Size=UDim2.new(0,2,0.7,0)})
ah:_resumeSpin(ai.BackImageGradient)
end

function af._applyInactiveVisuals(ah,ai)
local aj=ah._theme or{}
aa.Play(ai.Button,"Fast",{BackgroundColor3=aj.InactiveTabButtonColor,BackgroundTransparency=aj.InactiveTabButtonTransparency})
aa.Play(ai.TabName,"Fast",{TextTransparency=aj.InactiveTabTextTransparency or 0.6,TextColor3=aj.InactiveTabTextColor or Color3.fromRGB(200,200,200)})
aa.Play(ai.BackImage,"Fast",{ImageTransparency=1})
aa.Play(ai.TabImage,"Fast",{ImageTransparency=aj.InactiveTabIconTransparency or 0.6,ImageColor3=aj.InactiveTabIconColor or Color3.fromRGB(200,200,200)})
aa.Play(ai.SelectionStatus,"OnOff",{BackgroundTransparency=1,Size=UDim2.new(0,2,0,0)})
ah:_pauseSpin(ai.BackImageGradient)
end


function af.RefreshTitle(ah)
local ai=ah.Window
if not ai or not ai.PageTitle then return end
local aj=ah.ActiveTab and ah.ActiveTab.Name or"Settings"

ai.PageTitle.Text='<font weight="500">Settings | </font>'..aj
end

function af.SetActiveTab(ah,ai)
local aj=ah.ActiveTab
if aj==ai then
return
end
ah.ActiveTab=ai
ah:RefreshTitle()

if aj==nil then

local ak=ah:_getFadeCache(ai)
ai._faded=true
ai.Page.Visible=true
ah:_fadeElements(ak,1,nil,true)
ah:_applyActiveVisuals(ai)
ah:_resumeSpin(ai.BackImageGradient,true)
ah:_fadeElements(ak,nil,function()
ai._faded=false
end,false)
return
end


ah:_applyInactiveVisuals(aj)
ah:_applyActiveVisuals(ai)


local ak=ah:_getFadeCache(ai)
ah:_fadeElements(ak,1,nil,true)


local al=aj._cache or{}
ah:_fadeElements(al,1,function()
aj.Page.Visible=false



aj._faded=true
ai.Page.Visible=true
ai._faded=true
ah:_fadeElements(ak,nil,function()
ai._faded=false
end,false)
end,false)
end




function af.RestoreActivePage(ah)
local ai=ah.ActiveTab
if not ai then return end
for aj,ak in ipairs(ah.Tabs)do
if ak~=ai then
ak.Page.Visible=false
end
end
local aj=ah:_getFadeCache(ai)
ai.Page.Visible=true
ah:_fadeElements(aj,nil,nil,true)
ai._faded=false
ah:RefreshTitle()
end

function af.SetActiveTabByName(ah,ai)
for aj,ak in ipairs(ah.Tabs)do
if ak.Name==ai then
ah:SetActiveTab(ak)
return ak
end
end
return nil
end




function af.ApplyTheme(ah,ai)
local aj=ad.GetTheme(ai)
ah._theme=aj
for ak,al in ipairs(ah.Tabs)do
al._theme=aj
local am=(al==ah.ActiveTab)
if am then
al.Button.BackgroundColor3=aj.ActiveTabButtonColor or al.Button.BackgroundColor3
if aj.ActiveTabButtonTransparency~=nil then
al.Button.BackgroundTransparency=aj.ActiveTabButtonTransparency
end
al.TabName.TextColor3=aj.ActiveTabTextColor or al.TabName.TextColor3
if aj.ActiveTabTextTransparency~=nil then
al.TabName.TextTransparency=aj.ActiveTabTextTransparency
end
al.TabImage.ImageColor3=aj.ActiveTabIconColor or al.TabImage.ImageColor3
if aj.ActiveTabIconTransparency~=nil then
al.TabImage.ImageTransparency=aj.ActiveTabIconTransparency
end
else
al.Button.BackgroundColor3=aj.InactiveTabButtonColor or al.Button.BackgroundColor3
if aj.InactiveTabButtonTransparency~=nil then
al.Button.BackgroundTransparency=aj.InactiveTabButtonTransparency
end
al.TabName.TextColor3=aj.InactiveTabTextColor or al.TabName.TextColor3
if aj.InactiveTabTextTransparency~=nil then
al.TabName.TextTransparency=aj.InactiveTabTextTransparency
end
al.TabImage.ImageColor3=aj.InactiveTabIconColor or al.TabImage.ImageColor3
if aj.InactiveTabIconTransparency~=nil then
al.TabImage.ImageTransparency=aj.InactiveTabIconTransparency
end
end
al.SelectionStatus.BackgroundColor3=aj.SecondaryColor or al.SelectionStatus.BackgroundColor3
al.BackImage.Image=aj.Wallpaper or ac
al.BackImage.Visible=aj.WallpaperEnabled~=false
end
end

return af end function a.F():typeof(__modImpl())local aa=a.cache.F if not aa then aa={c=__modImpl()}a.cache.F=aa end return aa.c end end do local function __modImpl()










local aa=a.d()
local ab=a.f()
local ac=a.l().FallbackImage
local ad=a.a()

local ae={}

local af={
"Default",
"Black",
"Light",
"Midnight",
"Graphite",
"Pearl",
"Slate",
"Ocean",
"Nord",
"Forest",
"Amethyst",
"Rose",
"Retro",
"Glass",
"Porcelain",
"Mist",
"Sandstone",
"Dusk",
"Frost",
"Azure",
"Fjord",
"Summit",
"Blossom",
}


local ag={
Default="Balanced slate",
Black="OLED black",
Light="Clean & bright",
Midnight="Deep indigo",
Graphite="Cool gray teal",
Pearl="Warm and soft",
Slate="Cool blue-gray",
Ocean="Deep navy blue",
Nord="Arctic frost",
Forest="Deep forest",
Amethyst="Royal purple",
Rose="Soft plum pink",
Retro="Warm vintage",
Glass="Frosted glass",
Porcelain="Crisp and clean",
Mist="Frosted light",
Sandstone="Warm neutral",
Dusk="Plum twilight",
Frost="Icy blue-gray",
Azure="Deep mountain blue",
Fjord="Muted blue-grey",
Summit="Crisp alpine",
Blossom="Soft pink",
}

local function makeCard(ah,ai,aj,ak,al)
local am=Instance.new"TextButton"
am.Name=ai
am.BorderSizePixel=0
am.AutoButtonColor=false
am.BackgroundColor3=aj.WindowColor or Color3.fromRGB(16,16,17)
am.BackgroundTransparency=0
am.Size=UDim2.new(0.29,0,0.266,0)
am.Text=""
am.Parent=ah

local an=Instance.new"UICorner"
an.CornerRadius=UDim.new(0,6)
an.Parent=am

local ao=Instance.new"UIShadow"
ao.Parent=am


local ap=Instance.new"Frame"
ap.Name="Divider"
ap.BorderSizePixel=0
ap.BackgroundColor3=aj.TertiaryColor or Color3.fromRGB(150,150,150)
ap.BackgroundTransparency=ak and 0.72 or 0.9
ap.AnchorPoint=Vector2.new(0.5,0.5)
ap.Size=UDim2.new(0,1,0.7,0)
ap.Position=UDim2.new(0.5,0,0.5,0)
ap.Parent=am


local aq=Instance.new"Frame"
aq.Name="ThemeColorHolder"
aq.AnchorPoint=Vector2.new(0.5,0.5)
aq.Size=UDim2.new(0.35342,0,0.56731,0)
aq.Position=UDim2.new(0.73333,0,0.5,0)
aq.BackgroundColor3=Color3.fromRGB(255,255,255)
aq.BackgroundTransparency=1
aq.Parent=am

local ar=Instance.new"UIGridLayout"
ar.CellSize=UDim2.fromOffset(20,20)
ar.HorizontalAlignment=Enum.HorizontalAlignment.Center
ar.VerticalAlignment=Enum.VerticalAlignment.Center
ar.SortOrder=Enum.SortOrder.LayoutOrder
ar.Parent=aq

local b={}
local c={
{"PrimaryColor",aj.PrimaryColor},
{"SecondaryColor",aj.SecondaryColor},
{"TertiaryColor",aj.TertiaryColor},
{"AccentColor",aj.AccentColor},
}
for d,e in ipairs(c)do
local f=Instance.new"Frame"
f.Name=e[1]
f.LayoutOrder=d
f.Size=UDim2.fromOffset(26,18)
f.BackgroundColor3=e[2]or Color3.fromRGB(255,255,255)
f.BackgroundTransparency=ak and 0 or 0.5
f.Parent=aq

local g=Instance.new"UICorner"
g.CornerRadius=UDim.new(0,4)
g.Parent=f

local h=Instance.new"UIShadow"
h.Parent=f

b[e[1] ]=f
end


local d=Instance.new"ImageLabel"
d.Name="BackImage"
d.BorderSizePixel=0
d.BackgroundColor3=Color3.fromRGB(255,255,255)
d.BackgroundTransparency=1
d.Image=aj.Wallpaper or ac
d.ImageTransparency=ak and 0.5 or 0.7
d.AnchorPoint=Vector2.new(0.5,0.5)
d.Position=UDim2.new(0.5,0,0.5,0)
d.Size=UDim2.fromScale(1,1)
d.ScaleType=Enum.ScaleType.Stretch
d.Parent=am

local e=Instance.new"UICorner"
e.CornerRadius=UDim.new(0,6)
e.Parent=d

local f=Instance.new"UIGradient"
f.Rotation=180
f.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0),
NumberSequenceKeypoint.new(0.044,0.1625),
NumberSequenceKeypoint.new(0.087,0.34375),
NumberSequenceKeypoint.new(0.119,0.475),
NumberSequenceKeypoint.new(0.171,0.625),
NumberSequenceKeypoint.new(0.230,0.73125),
NumberSequenceKeypoint.new(0.286,0.80625),
NumberSequenceKeypoint.new(0.351,0.875),
NumberSequenceKeypoint.new(0.441,0.93125),
NumberSequenceKeypoint.new(0.533,0.9625),
NumberSequenceKeypoint.new(0.681,0.975),
NumberSequenceKeypoint.new(1.000,1),
}
f.Parent=d


local g=Instance.new"TextLabel"
g.Name="ThemeTitle"
g.TextSize=13
g.TextXAlignment=Enum.TextXAlignment.Left
g.TextTransparency=ak and 0.2 or 0.5
g.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
g.TextColor3=aj.TitleTextColor or aj.PrimaryTextColor or Color3.fromRGB(255,255,255)
g.BackgroundTransparency=1
g.AnchorPoint=Vector2.new(0,0.5)
g.Size=UDim2.new(0.49333,-20,0,18)
g.Position=UDim2.new(0,7,0.43269,0)
g.Text=ai
g.Parent=am


local h=Instance.new"TextLabel"
h.Name="ThemeDescription"
h.TextSize=9
h.TextXAlignment=Enum.TextXAlignment.Left
h.TextYAlignment=Enum.TextYAlignment.Top
h.TextTransparency=0.5
h.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
h.TextColor3=aj.TitleTextColor or aj.PrimaryTextColor or Color3.fromRGB(255,255,255)
h.BackgroundTransparency=1
h.AnchorPoint=Vector2.new(0,0.5)
h.Size=UDim2.new(0.49333,-20,-7.212000000000001E-2,18)
h.Position=UDim2.new(0,7,0.59856,0)
h.Text=ag[ai]or"A cool theme"
h.Parent=am

am.MouseButton1Click:Connect(function()
al(ai)
end)

return{
card=am,
title=g,
backImage=d,
divider=ap,
swatches=b,
}
end

function ae.Build(ah,ai)
local aj=ai.Page
local ak=ab.GetTheme(ai._theme)


aj.Size=UDim2.new(1,0,0.87857,0)
aj.Position=UDim2.new(0.5,0,0.561,0)
aj.AnchorPoint=Vector2.new(0.5,0.5)







local al=Instance.new"TextLabel"
al.Name="ThemePageText"
al.TextWrapped=true
al.TextTruncate=Enum.TextTruncate.AtEnd
al.BorderSizePixel=0
al.TextSize=15
al.TextXAlignment=Enum.TextXAlignment.Left
al.TextTransparency=0.4
al.BackgroundColor3=Color3.fromRGB(255,255,255)
al.BackgroundTransparency=1
al.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
al.TextColor3=ak.TitleTextColor or Color3.fromRGB(255,255,255)
al.RichText=true
al.Size=UDim2.new(0,0,0.06849,0)
al.AutomaticSize=Enum.AutomaticSize.X
al.Text="Native themes"
al.Position=UDim2.new(0,0,0,0)
al.Parent=aj





local am=Instance.new"ScrollingFrame"
am.Name="PageHolder"
am.BorderSizePixel=0
am.BackgroundColor3=ak.SectionBackgroundColor
am.BackgroundTransparency=1
am.Size=UDim2.new(1,0,0.89,0)
am.Position=UDim2.new(0,0,0.11,0)
am.CanvasSize=UDim2.new(0,0,0,0)
am.AutomaticCanvasSize=Enum.AutomaticSize.Y
am.ScrollingDirection=Enum.ScrollingDirection.Y
am.ScrollBarThickness=1
am.ScrollBarImageColor3=ak.TertiaryColor
am.ScrollBarImageTransparency=1
am.Parent=aj


local an
am:GetPropertyChangedSignal"CanvasPosition":Connect(function()
ad.Play(am,"Fast",{ScrollBarImageTransparency=0.5})
if an then
task.cancel(an)
end
an=task.delay(1.5,function()
ad.Play(am,"Fast",{ScrollBarImageTransparency=1})
an=nil
end)
end)

local ao=Instance.new"UIPadding"
ao.PaddingTop=UDim.new(0,10)
ao.PaddingBottom=UDim.new(0,20)
ao.Parent=am


local ap=Instance.new"UIGridLayout"
ap.CellSize=UDim2.fromOffset(155,75)
ap.CellPadding=UDim2.fromOffset(17,10)
ap.SortOrder=Enum.SortOrder.LayoutOrder
ap.FillDirection=Enum.FillDirection.Horizontal
ap.HorizontalAlignment=Enum.HorizontalAlignment.Left
ap.VerticalAlignment=Enum.VerticalAlignment.Top
ap.Parent=am


local aq={}
local ar={}
for b,c in ipairs(af)do
if aa[c]then
table.insert(aq,c)
ar[c]=true
end
end
for b in pairs(aa)do
if not ar[b]then
table.insert(aq,b)
end
end


local b=Instance.new"TextLabel"
b.Name="CurrentThemeText"
b.TextWrapped=true
b.TextTruncate=Enum.TextTruncate.AtEnd
b.BorderSizePixel=0
b.TextSize=10
b.TextXAlignment=Enum.TextXAlignment.Left
b.TextTransparency=0.5
b.BackgroundColor3=Color3.fromRGB(255,255,255)
b.BackgroundTransparency=1
b.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
b.TextColor3=ak.TitleTextColor or Color3.fromRGB(255,255,255)
b.RichText=true
b.Size=UDim2.new(0.32573,0,0.03814,0)
b.AutomaticSize=Enum.AutomaticSize.X
b.Text="<b>Current theme:</b> Light"
b.Position=UDim2.new(0,0,0.06,0)
b.Parent=aj


ai._themeCards={}
ai._activeThemeName=ah._themeName or"Default"

local function setActive(c)
if ai._activeThemeName==c then
return
end
ai._activeThemeName=c
for d,e in pairs(ai._themeCards)do
local f=(d==c)
e.title.TextTransparency=f and 0.2 or 0.5
e.backImage.ImageTransparency=f and 0.5 or 0.7
e.divider.BackgroundTransparency=f and 0.72 or 0.9
for g,h in pairs(e.swatches)do
h.BackgroundTransparency=f and 0 or 0.5
end
end
b.Text="<b>Current theme:</b> "..c
ah:SetTheme(c)
end

for c,d in ipairs(aq)do
local e=ab.GetTheme(d)
local f=(d==ai._activeThemeName)
local g=makeCard(am,d,e,f,setActive)
ai._themeCards[d]=g
end


b.Text="<b>Current theme:</b> "..ai._activeThemeName







local c={}
function c.ApplyTheme(d,e)
local f=ab.GetTheme(e)
al.TextColor3=f.TitleTextColor or al.TextColor3
b.TextColor3=f.TitleTextColor or b.TextColor3
am.ScrollBarImageColor3=f.TertiaryColor or am.ScrollBarImageColor3
end
ab.Register(aj,c)

return aj
end

return ae end function a.G():typeof(__modImpl())local aa=a.cache.G if not aa then aa={c=__modImpl()}a.cache.G=aa end return aa.c end end do local function __modImpl()















local aa=game:GetService"HttpService"

local ab={}

local ac="Aetheris_settings.json"


ab.Defaults={
Theme=nil,
UIScale=1,
MinimizeKey=nil,
SpinsEnabled=true,
ConfirmClose=true,
Volume=1,
}

ab.Data={}
for ad,ae in pairs(ab.Defaults)do
ab.Data[ad]=ae
end


local ad=(type(writefile)=="function"and type(readfile)=="function")

function ab.Load()
if not ad then
return ab.Data
end
local ae,af=pcall(function()
if isfile and not isfile(ac)then
return nil
end
return readfile(ac)
end)
if ae and af and af~=""then
local ag
local ah,ai=pcall(function()return aa:JSONDecode(af)end)
if ah and type(ai)=="table"then
ag=ai
end
if ag then
for aj in pairs(ab.Defaults)do
if ag[aj]~=nil then
ab.Data[aj]=ag[aj]
end
end
end
end
return ab.Data
end

function ab.Save()
if not ad then
return
end
local ae,af=pcall(function()return aa:JSONEncode(ab.Data)end)
if ae and af then
pcall(function()writefile(ac,af)end)
end
end


function ab.Get(ae)
local af=ab.Data[ae]
if af==nil then
return ab.Defaults[ae]
end
return af
end


function ab.Set(ae,af)
ab.Data[ae]=af
ab.Save()
end

return ab end function a.H():typeof(__modImpl())local aa=a.cache.H if not aa then aa={c=__modImpl()}a.cache.H=aa end return aa.c end end do local function __modImpl()








local aa=a.a()
local ab=a.g()
local ac=a.i()
local ad=a.h()
local ae=a.u()
local af=a.b()
local ag=a.H()
local ah=a.f()

local ai={}

function ai.Build(aj,ak)
local al=aj._theme or{}
local am=ak.Page

am.Name="UISettings"
am.BackgroundColor3=Color3.fromRGB(255,255,255)
am.BackgroundTransparency=1
am.AnchorPoint=Vector2.new(0.5,0.5)
am.Size=UDim2.new(1,0,0.87857,0)
am.Position=UDim2.new(0.5,0,0.56071,0)
am.LayoutOrder=1

local an=Instance.new"UIListLayout"
an.Padding=UDim.new(0,10)
an.SortOrder=Enum.SortOrder.LayoutOrder
an.Parent=am

local ao=Instance.new"UIPadding"
ao.PaddingTop=UDim.new(0,10)
ao.PaddingLeft=UDim.new(0,5)
ao.Parent=am

local ap=Instance.new"ScrollingFrame"
ap.Name="SettingsScroller"
ap.Active=true
ap.BorderSizePixel=0
ap.ScrollBarImageTransparency=1
ap.BackgroundColor3=Color3.fromRGB(255,255,255)
ap.BackgroundTransparency=1
ap.AnchorPoint=Vector2.new(0.5,0.5)
ap.AutomaticCanvasSize=Enum.AutomaticSize.Y
ap.Size=UDim2.new(1,0,0.87,0)
ap.Position=UDim2.new(0.5,0,0.532,0)
ap.BorderColor3=Color3.fromRGB(0,0,0)
ap.ScrollBarThickness=1
ap.ScrollBarImageColor3=al.TertiaryColor or Color3.fromRGB(160,160,160)
ap.LayoutOrder=1
ap.Parent=am


local aq
ap:GetPropertyChangedSignal"CanvasPosition":Connect(function()
aa.Play(ap,"Fast",{ScrollBarImageTransparency=0.5})
if aq then
task.cancel(aq)
end
aq=task.delay(1.5,function()
aa.Play(ap,"Fast",{ScrollBarImageTransparency=1})
aq=nil
end)
end)

local ar=Instance.new"UIListLayout"
ar.Padding=UDim.new(0,6)
ar.SortOrder=Enum.SortOrder.LayoutOrder
ar.Parent=ap

local b=Instance.new"UIPadding"
b.PaddingRight=UDim.new(0,15)
b.PaddingLeft=UDim.new(0,5)
b.Parent=ap

local c=Instance.new"TextLabel"
c.Name="PageTitle"
c.TextWrapped=true
c.BorderSizePixel=0
c.TextSize=15
c.TextXAlignment=Enum.TextXAlignment.Left
c.TextTransparency=0.4
c.BackgroundColor3=Color3.fromRGB(255,255,255)
c.BackgroundTransparency=1
c.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
c.TextColor3=al.PrimaryTextColor or Color3.fromRGB(255,255,255)
c.RichText=true
c.Size=UDim2.new(0.17008,0,0.06723,0)
c.BorderColor3=Color3.fromRGB(0,0,0)
c.Text="UI Settings"
c.AutomaticSize=Enum.AutomaticSize.X
c.Parent=am

local d=Instance.new"UIPadding"
d.PaddingBottom=UDim.new(0,10)
d.Parent=c




local e=aj._minimizeKey




ac.new(ap,{
Name="Minimize UI",
Default=e,
Callback=function()
if aj.ToggleMinimize then aj.ToggleMinimize()end
end,
OnRebind=function(f)

e=f
end,
},al)



ab.new(ap,{
Name="Spinning Animations",
Default=ag.Get"SpinsEnabled",
Callback=function(f)
aa.SetSpinsEnabled(f)
ag.Set("SpinsEnabled",f)
end,
},nil,al)


ab.new(ap,{
Name="Confirm On Close",
Default=ag.Get"ConfirmClose",
Callback=function(f)
ag.Set("ConfirmClose",f)
end,
},nil,al)


ad.new(ap,{
Name="UI Scale",
Min=80,
Max=125,
Default=math.floor((ag.Get"UIScale"or 1)*100+0.5),
Precision=0,
Callback=function(f)
local g=f/100
local h=aj.MainFrame and aj.MainFrame:FindFirstChild"WindowScale"
if h then h.Scale=g end
ag.Set("UIScale",g)
end,
},al)


ad.new(ap,{
Name="UI Volume",
Min=0,
Max=100,
Default=math.floor((ag.Get"Volume"or 1)*100+0.5),
Precision=0,
Callback=function(f)
local g=f/100
af.SetVolume(g)
ag.Set("Volume",g)
end,
},al)


ae.new(ap,{
Name="Reset Layout",
Callback=function()
if aj.ResetLayout then aj.ResetLayout()end
end,
},al)





local f={}
function f.ApplyTheme(g,h)
local i=ah.GetTheme(h)
c.TextColor3=i.PrimaryTextColor or c.TextColor3
ap.ScrollBarImageColor3=i.TertiaryColor or ap.ScrollBarImageColor3
end
ah.Register(am,f)
end

return ai end function a.I():typeof(__modImpl())local aa=a.cache.I if not aa then aa={c=__modImpl()}a.cache.I=aa end return aa.c end end do local function __modImpl()









local aa=a.G()
local ab=a.I()

local ac={}

function ac.BuildDefaultPages(ad)
local ae=ad.SettingsTabGroup

local af=ae:Tab{
Name="Themes",
Icon="rbxassetid://86350350950064",
Active=true,
}
aa.Build(ad,af)

local ag=ae:Tab{
Name="UI Settings",
Icon="rbxassetid://80758916183665",
}
ab.Build(ad,ag)
end

return ac end function a.J():typeof(__modImpl())local aa=a.cache.J if not aa then aa={c=__modImpl()}a.cache.J=aa end return aa.c end end do local function __modImpl()
















local aa=a.a()
local ab=a.f()
local ac=a.l().FallbackImage
local ad=a.c()
local ae=a.b()

local af={}
af.__index=af

local ag=2
local ah=0.25
local ai=0.2

local function new(aj,ak)
local al=Instance.new(aj)
for am,an in pairs(ak)do
if am=="Parent"then
al.Parent=an
else
al[am]=an
end
end
return al
end



local function captureFade(aj)
local ak={}
local function scan(al)
if al:IsA"GuiObject"then
for am,an in ipairs{"BackgroundTransparency","TextTransparency","ImageTransparency"}do
local ao,ap=pcall(function()return al[an]end)
if ao and type(ap)=="number"then
table.insert(ak,{al,an,ap})
end
end
end
if al:IsA"UIStroke"or al:IsA"UIShadow"then
table.insert(ak,{al,"Transparency",al.Transparency})
end
for am,an in ipairs(al:GetChildren())do
scan(an)
end
end
scan(aj)
return ak
end

local function setAll(aj,ak)
for al,am in ipairs(aj)do
am[1][am[2] ]=ak
end
end

local function tweenAll(aj,ak,al)
for am,an in ipairs(aj)do
local ao=ak
if ao==nil then
ao=an[3]
end
aa.Play(
an[1],
TweenInfo.new(al,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
{[an[2] ]=ao}
)
end
end

local aj={
Alert="NotificationAlertAccent",
Error="NotificationErrorAccent",
Variable="NotificationVariableAccent",
}

local ak={
Alert="Alert",
Error="Error",
Variable="Changes saved!",
}



local al={
Alert=ad["triangle-alert"]or"rbxassetid://125920361880643",
Error=ad["shield-alert"]or"rbxassetid://114995877719925",
Variable=ad.bell or"rbxassetid://97392696311902",
}
local am=ad["minimize-2"]or"rbxassetid://116269596042539"

function af.new(an,ao,ap)
ap=ab.GetTheme(ap)
ao=ao or{}
local aq=setmetatable({},af)

local ar=ao.Type or"Alert"
local b=ao.Title or ak[ar]or"Notification"
local c=ao.Description or""
aq.Duration=ao.Duration or 5

local d=ap[aj[ar]or"NotificationAlertAccent"]or Color3.fromRGB(96,165,250)
local e=ao.IconColor or d
local f=ao.GradientColor or d

local g=new("Frame",{
Name=ar.."Notification",
ZIndex=999,
BorderSizePixel=0,
BackgroundColor3=ap.NotificationBackgroundColor or Color3.fromRGB(16,16,17),
BackgroundTransparency=ap.NotificationBackgroundTransparency or 0.1,
AutomaticSize=Enum.AutomaticSize.Y,
Size=UDim2.new(0,233,0,ar=="Variable"and 118 or 92),
BorderColor3=Color3.fromRGB(41,41,41),
LayoutOrder=2,
Parent=an,
})
aq.Root=g

new("UICorner",{Parent=g,CornerRadius=UDim.new(0,6)})
new("UIShadow",{Parent=g,Color=ap.NotificationShadowColor or Color3.fromRGB(0,0,0)})


local h=new("Frame",{
Name="GradientBackground",
BorderSizePixel=0,
BackgroundColor3=f,
BackgroundTransparency=0.65,
AnchorPoint=Vector2.new(0.5,0.5),
Size=UDim2.new(1,0,0.5,0),
Position=UDim2.new(0.5,0,0.25,0),
ZIndex=0,
Parent=g,
})
new("UICorner",{Parent=h,CornerRadius=UDim.new(0,6)})
new("UIGradient",{
Parent=h,
Rotation=270,
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,1),
NumberSequenceKeypoint.new(0.297,1),
NumberSequenceKeypoint.new(0.531,1),
NumberSequenceKeypoint.new(0.712,0.93125),
NumberSequenceKeypoint.new(0.825,0.8625),
NumberSequenceKeypoint.new(0.881,0.7875),
NumberSequenceKeypoint.new(0.921,0.69375),
NumberSequenceKeypoint.new(0.952,0.6),
NumberSequenceKeypoint.new(0.975,0.5),
NumberSequenceKeypoint.new(1.000,0.39375),
},
})


if ao.ShowBackground then
local i=new("ImageLabel",{
Name="Background",
BorderSizePixel=0,
BackgroundTransparency=1,
ImageTransparency=0.5,


Image=ao.BackgroundImage or ap.Wallpaper or ac,
ImageColor3=Color3.fromRGB(255,255,255),
AnchorPoint=Vector2.new(0.5,0.5),
Size=UDim2.new(1,0,1,0),
Position=UDim2.new(0.5,0,0.5,0),
ZIndex=0,
Parent=g,
})
new("UICorner",{Parent=i,CornerRadius=UDim.new(0,6)})
new("UIGradient",{
Parent=i,
Rotation=180,
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0),
NumberSequenceKeypoint.new(0.134,0.3),
NumberSequenceKeypoint.new(0.242,0.53125),
NumberSequenceKeypoint.new(0.371,0.69375),
NumberSequenceKeypoint.new(0.484,0.80625),
NumberSequenceKeypoint.new(0.590,0.91875),
NumberSequenceKeypoint.new(0.681,0.975),
NumberSequenceKeypoint.new(1.000,1),
},
})
end


local i=new("TextLabel",{
Name="Header",
BorderSizePixel=0,
BackgroundTransparency=1,
TextTruncate=Enum.TextTruncate.AtEnd,
TextSize=ar=="Variable"and 13 or 15,
TextXAlignment=Enum.TextXAlignment.Left,
TextTransparency=ap.NotificationHeaderTransparency or 0.3,
TextColor3=ap.NotificationHeaderColor or Color3.fromRGB(255,255,255),
AutomaticSize=Enum.AutomaticSize.X,
FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
Size=UDim2.new(0,0,0,14),
Position=UDim2.new(0,42,0,11),
ZIndex=2,
Text=b,
Parent=g,
})
new("Frame",{
Name="Divider",
BorderSizePixel=0,
BackgroundColor3=ap.NotificationDividerColor or Color3.fromRGB(255,255,255),
BackgroundTransparency=ap.NotificationDividerTransparency or 0.7,
Size=UDim2.new(0.7,0,0,1),
Position=UDim2.new(0,0,0,22),
ZIndex=3,
Parent=i,
})


local j=new("ImageLabel",{
Name="Icon",
BorderSizePixel=0,
BackgroundTransparency=1,
ImageColor3=e,
AnchorPoint=Vector2.new(0.5,0.5),
Image=ao.Icon or al[ar]or al.Alert,
Size=UDim2.new(0,22,0,22),
Position=UDim2.new(0,21,0,24),
ZIndex=2,
Parent=g,
})
new("UIAspectRatioConstraint",{Parent=j,DominantAxis=Enum.DominantAxis.Height})


local k=new("TextLabel",{
Name="Description",
BorderSizePixel=0,
BackgroundTransparency=1,
TextWrapped=true,
TextSize=13,
TextXAlignment=Enum.TextXAlignment.Left,
TextYAlignment=Enum.TextYAlignment.Top,
TextTransparency=ap.NotificationTextTransparency or 0.5,
TextColor3=ap.NotificationTextColor or Color3.fromRGB(255,255,255),
FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal),
Size=UDim2.new(0.68,0,0,0),
AutomaticSize=Enum.AutomaticSize.Y,
Position=UDim2.new(0,42,0,40),
ZIndex=2,
Text=c,
Parent=g,
})
new("UIPadding",{
Parent=k,
PaddingTop=(ar=="Variable")and UDim.new(0,5)or UDim.new(0,0),
PaddingBottom=UDim.new(0,(ar=="Variable")and 45 or 15),
})


local l=ao.Actions or{}
if#l>0 then
local m=new("Frame",{
Name="InterractionHolder",
BorderSizePixel=0,
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,30),
Position=UDim2.new(0,0,1.25,0),
ZIndex=3,
Parent=k,
})
new("UIListLayout",{
Parent=m,
Padding=UDim.new(0,10),
SortOrder=Enum.SortOrder.LayoutOrder,
FillDirection=Enum.FillDirection.Horizontal,
})
local n=ap.NotificationActionButtonColor or Color3.fromRGB(81,81,81)

local o=n:Lerp(Color3.fromRGB(255,255,255),0.18)
for p=1,math.min(#l,ag)do
local q=l[p]
local r=new("TextButton",{
Name="Interraction",
BorderSizePixel=0,
AutoButtonColor=false,
TextSize=12,
TextColor3=ap.NotificationActionButtonTextColor or Color3.fromRGB(255,255,255),
BackgroundColor3=n,
FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal),
Size=UDim2.new(0,60,0,20),
Text=q.Text or"Click",
LayoutOrder=p,
ZIndex=4,
Parent=m,
})
new("UICorner",{Parent=r,CornerRadius=UDim.new(0,4)})


local s=new("UIShadow",{
Color=d,
Transparency=1,
BlurRadius=UDim.new(0,12),
Parent=r,
})

local function tween(t,u,v)
aa.Play(
r,
TweenInfo.new(v or 0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
t
)
end
r.MouseEnter:Connect(function()
tween{BackgroundColor3=o}
aa.Play(s,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Transparency=0.4})
end)
r.MouseLeave:Connect(function()
tween{BackgroundColor3=n}
aa.Play(s,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Transparency=1})
end)

r.MouseButton1Down:Connect(function()
tween({BackgroundColor3=n:Lerp(Color3.fromRGB(0,0,0),0.25)},0.08)
end)
r.MouseButton1Up:Connect(function()
tween({BackgroundColor3=o},0.08)
end)

r.MouseButton1Click:Connect(function()
if q.Callback then
q.Callback(aq)
end
aq:Close()
end)
end
end


local m=new("ImageButton",{
Name="DismissButton",
BorderSizePixel=0,
BackgroundTransparency=1,
ImageTransparency=0.5,
Image=am,
ImageColor3=ap.NotificationDismissColor or Color3.fromRGB(255,255,255),
Size=UDim2.new(0,16,0,16),
Position=UDim2.new(0.888,0,0.13,0),
ZIndex=3,
Parent=g,
})
new("UIAspectRatioConstraint",{Parent=m,DominantAxis=Enum.DominantAxis.Height})


local function dismissTween(n,o)
aa.Play(
m,
TweenInfo.new(o or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
n
)
end
m.MouseEnter:Connect(function()
dismissTween{ImageTransparency=0.1,Size=UDim2.new(0,18,0,18)}
end)
m.MouseLeave:Connect(function()
dismissTween{ImageTransparency=0.5,Size=UDim2.new(0,16,0,16)}
end)
m.MouseButton1Down:Connect(function()
dismissTween({Size=UDim2.new(0,14,0,14)},0.08)
end)
m.MouseButton1Up:Connect(function()
dismissTween({Size=UDim2.new(0,18,0,18)},0.08)
end)
m.MouseButton1Click:Connect(function()
aq:Close()
end)


aq.TimerFrame=new("Frame",{
Name="TimerFrame",
BorderSizePixel=0,
BackgroundColor3=d,
AnchorPoint=Vector2.new(0.5,1),
Size=UDim2.new(0.7,0,0,2),
Position=UDim2.new(0.5,0,0.97,0),
ZIndex=3,
Parent=g,
})

aq._fadeTargets=captureFade(g)
aq._shown=false
aq._closing=false

return aq
end

function af._startTimer(an)
an._timerTween=aa.Play(
an.TimerFrame,
TweenInfo.new(an.Duration,Enum.EasingStyle.Linear),
{Size=UDim2.new(0,0,0,2)}
)
end

function af.Show(an)
if an._shown then return an end
an._shown=true
ae.Play"Notification"
setAll(an._fadeTargets,1)
an.Root.Visible=true
tweenAll(an._fadeTargets,nil,ah)
an:_startTimer()
an._dismissTask=task.delay(an.Duration,function()



an._dismissTask=nil
an:Close()
end)
return an
end

function af.Close(an)
if an._closing then return end
an._closing=true
if an._timerTween then
aa.Cancel(an._timerTween)
an._timerTween=nil
end
if an._dismissTask then
task.cancel(an._dismissTask)
an._dismissTask=nil
end
tweenAll(an._fadeTargets,1,ai)
task.delay(ai,function()
if an.Root then
an.Root:Destroy()
an.Root=nil
end
end)
end

return af end function a.K():typeof(__modImpl())local aa=a.cache.K if not aa then aa={c=__modImpl()}a.cache.K=aa end return aa.c end end do local function __modImpl()





















local aa=game:GetService"UserInputService"
local ab=game:GetService"Players"

local ac=a.a()
local ad=a.b()
local ae=a.c()
local af=a.A()
local ag=a.B()
local ah=a.C()
local ai=a.D()
local aj=a.E()
local ak=a.o()
local al=a.f()
local am=a.z()
local an=a.F()
local ao=a.J()
local ap=a.H()

local aq=os.date"*t"
local ar=aq.hour
local b=aq.min

local c={}
c.__index=c



c.AnimationStyle="Smooth"
c.DragStyle="Instant"

function c.new(d)
d=d or{}




ap.Load()
local e=ap.Get"Theme"
local f=ap.Get"MinimizeKey"
if e~=nil then d.Theme=e end
if f~=nil then d.MinimizeKey=f end
ad.SetVolume(ap.Get"Volume")
ac.SpinsEnabled=ap.Get"SpinsEnabled"


local g=al.GetTheme(d.Theme)

local h=g

local i=ab.LocalPlayer



local j




local k
local l




local m=Instance.new"ScreenGui"
m.Name="Aetheris"
m.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
m.ResetOnSpawn=false
m.Parent=(i and i:WaitForChild"PlayerGui")or game:GetService"CoreGui"




local n=Instance.new"Frame"
n.Name="Window"
n.BorderSizePixel=0
n.BackgroundColor3=Color3.fromRGB(15,15,15)
n.BackgroundTransparency=0.1
n.AnchorPoint=Vector2.new(0,0)
n.Size=UDim2.new(0.72026,0,0.96995,0)
n.Position=UDim2.new(0.013,0,0.015,0)
n.BorderColor3=Color3.fromRGB(41,41,41)
n.Parent=m

local o=Instance.new"Frame"
o.AnchorPoint=Vector2.new(0.5,0)
o.Name="DragFrame"
o.Position=UDim2.new(0.5,0,0,0)
o.Size=UDim2.new(1,0,0,60)
o.BackgroundTransparency=1
o.Parent=n




do
local p=false
local q
local r

o.InputBegan:Connect(function(s)
if s.UserInputType==Enum.UserInputType.MouseButton1
or s.UserInputType==Enum.UserInputType.Touch then
p=true
q=s.Position
r=n.AbsolutePosition

s.Changed:Connect(function()
if s.UserInputState==Enum.UserInputState.End then
p=false
end
end)
end
end)

k=aa.InputChanged:Connect(function(s)
if p and(s.UserInputType==Enum.UserInputType.MouseMovement
or s.UserInputType==Enum.UserInputType.Touch)then
local t=s.Position-q
local u=r+Vector2.new(t.X,t.Y)
local v=UDim2.new(0,u.X,0,u.Y)

if c.DragStyle=="Smooth"then
ac.Play(n,"Fast",{Position=v})
else
n.Position=v
end
end
end)
end

local p=Instance.new"UICorner"
p.Parent=n



local q=Instance.new"UIScale"
q.Name="WindowScale"
q.Scale=ap.Get"UIScale"or 1
q.Parent=n

local r=Instance.new"UIShadow"
r.Transparency=0.5
r.BlurRadius=UDim.new(0,20)
r.Parent=n

local s=Instance.new"UISizeConstraint"
s.MinSize=Vector2.new(750,415)
s.Parent=n









local t=Instance.new"Frame"
t.Name="ContentBackground"
t.BorderSizePixel=0
t.BackgroundColor3=h.ContentBackgroundColor or h.WindowColor
t.BackgroundTransparency=h.ContentBackgroundTransparency~=nil and h.ContentBackgroundTransparency




t.AnchorPoint=Vector2.new(1,0.5)
t.Position=UDim2.new(1,0,0.5,0)
t.Size=UDim2.new(1,-186,1,0)
t.ZIndex=0
t.Parent=n

local u=Instance.new"UICorner"
u.TopLeftRadius=UDim.new(0,0)
u.BottomLeftRadius=UDim.new(0,0)
u.TopRightRadius=UDim.new(0,6)
u.BottomRightRadius=UDim.new(0,6)
u.Parent=t




local v=Instance.new"Frame"
v.Name="WindowControls"
v.BorderSizePixel=0
v.BackgroundColor3=Color3.fromRGB(255,255,255)
v.BackgroundTransparency=1
v.AnchorPoint=Vector2.new(1,0)
v.Size=UDim2.new(0.10926,0,0.04715,0)
v.Position=UDim2.new(0.98301,0,0.01715,0)
v.BorderColor3=Color3.fromRGB(0,0,0)
v.Parent=n

local w=Instance.new"UIListLayout"
w.HorizontalAlignment=Enum.HorizontalAlignment.Right
w.VerticalAlignment=Enum.VerticalAlignment.Center
w.Padding=UDim.new(0,3)
w.SortOrder=Enum.SortOrder.LayoutOrder
w.FillDirection=Enum.FillDirection.Horizontal
w.Parent=v



local function makeControlButton(x,y,z,A)
local B=Instance.new"ImageButton"
B.Name=x
B.BackgroundTransparency=1
B.ImageTransparency=0.5
B.ImageColor3=h.WindowControlColor or Color3.fromRGB(203,213,225)
B.Image=y
B.Size=UDim2.new(0,15,0,15)
B.LayoutOrder=z
B.Parent=A
local C=Instance.new"UIAspectRatioConstraint"
C.DominantAxis=Enum.DominantAxis.Height
C.Parent=B
local D=Instance.new"UIScale"
D.Scale=1
D.Parent=B
B.MouseEnter:Connect(function()
ac.Play(D,"HoverIn",{Scale=1.25})
ac.Play(B,"Fast",{ImageTransparency=0.1})
end)
B.MouseLeave:Connect(function()
ac.Play(D,"HoverOut",{Scale=1})
ac.Play(B,"Fast",{ImageTransparency=0.5})
end)
B.MouseButton1Down:Connect(function()
ac.Play(D,"Fast",{Scale=0.9})
end)
B.MouseButton1Up:Connect(function()
ac.Play(D,"HoverIn",{Scale=1.25})
end)
return B
end

local x=makeControlButton("MinimizeButton",ae.minimize or"rbxassetid://121304296213645",1,v)
local y=makeControlButton("MaximizeButton",ae.maximize or"rbxassetid://76045941763188",2,v)
local z=makeControlButton("CloseButton",ae.x or"rbxassetid://110786993356448",3,v)




local A=Instance.new"TextLabel"
A.Name="PageTitle"
A.TextWrapped=true
A.BorderSizePixel=0
A.TextSize=14
A.TextXAlignment=Enum.TextXAlignment.Left
A.TextTransparency=0.4
A.BackgroundTransparency=1




A.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
A.TextColor3=h.TitleTextColor
A.RichText=true
A.AutomaticSize=Enum.AutomaticSize.X
A.Size=UDim2.new(0,0,0.06849,0)


A.Position=UDim2.new(0,200,0.055,0)
A.BorderColor3=Color3.fromRGB(0,0,0)
A.Text='<font weight="500">Settings | </font>General'
A.Parent=n

local B=Instance.new"Frame"
B.Name="ComponentDivider"
B.BorderSizePixel=0
B.BackgroundColor3=h.TertiaryColor
B.BackgroundTransparency=0.9
B.Size=UDim2.new(0.8,0,0,1)
B.Position=UDim2.new(0,0,1.2,0)
B.BorderColor3=Color3.fromRGB(0,0,0)
B.Parent=A




local C=Instance.new"Frame"
C.Name="Content"
C.BorderSizePixel=0
C.BackgroundTransparency=1


C.Size=UDim2.new(1,-200,0.83149,0)
C.Position=UDim2.new(0,200,0.14851,0)
C.BorderColor3=Color3.fromRGB(0,0,0)
C.Parent=n


local D=Instance.new"Folder"
D.Name="PopUps"
D.Parent=C



local E=Instance.new"Frame"
E.Name="Notifications"
E.BorderSizePixel=0
E.BackgroundTransparency=1
E.AnchorPoint=Vector2.new(1,1)
E.Size=UDim2.new(0,260,1,0)
E.Position=UDim2.new(1,0,1,0)
E.ZIndex=999
E.Parent=m

local F=Instance.new"UIListLayout"
F.HorizontalAlignment=Enum.HorizontalAlignment.Right
F.VerticalAlignment=Enum.VerticalAlignment.Bottom
F.Padding=UDim.new(0,8)
F.SortOrder=Enum.SortOrder.LayoutOrder
F.Parent=E

local G=Instance.new"UIPadding"
G.PaddingBottom=UDim.new(0,14)
G.PaddingRight=UDim.new(0,4)
G.Parent=E



local H=Instance.new"Frame"
H.Name="SettingsPages"
H.Visible=false
H.BorderSizePixel=0
H.BackgroundTransparency=1
H.AnchorPoint=Vector2.new(0.5,0.5)
H.ClipsDescendants=true
H.Size=UDim2.new(0.983,0,1,0)
H.Position=UDim2.new(0.49148,0,0.5,0)
H.BorderColor3=Color3.fromRGB(0,0,0)
H.Parent=C

local I=Instance.new"Frame"
I.Name="TabContent"
I.BorderSizePixel=0
I.BackgroundTransparency=1
I.AnchorPoint=Vector2.new(0.5,0.5)
I.ClipsDescendants=true
I.Size=UDim2.new(1,0,1,0)
I.Position=UDim2.new(0.5,0,0.5,0)
I.BorderColor3=Color3.fromRGB(0,0,0)
I.Parent=C

local J=Instance.new"UIPadding"
J.PaddingTop=UDim.new(0,10)
J.PaddingRight=UDim.new(0,5)
J.PaddingLeft=UDim.new(0,2)
J.PaddingBottom=UDim.new(0,10)
J.Parent=I




local K=Instance.new"Frame"
K.Name="Sidebar"
K.BorderSizePixel=0
K.BackgroundColor3=Color3.fromRGB(21,21,21)
K.BackgroundTransparency=1
K.AnchorPoint=Vector2.new(0,0)
K.Size=UDim2.new(0.41348,0,1,0)
K.Position=UDim2.new(0,0,0,0)
K.BorderColor3=Color3.fromRGB(0,0,0)
K.Parent=n

local L=Instance.new"UIPadding"
L.PaddingTop=UDim.new(0,10)
L.PaddingRight=UDim.new(0,5)
L.PaddingLeft=UDim.new(0,5)
L.PaddingBottom=UDim.new(0,15)
L.Parent=K

local M=Instance.new"UIShadow"
M.BlurRadius=UDim.new(0,20)
M.Transparency=1
M.Parent=K

local N=Instance.new"UICorner"
N.TopLeftRadius=UDim.new(0,6)
N.BottomLeftRadius=UDim.new(0,6)
N.TopRightRadius=UDim.new(0,0)
N.BottomRightRadius=UDim.new(0,0)
N.Parent=K

local O=Instance.new"UISizeConstraint"
O.MinSize=Vector2.new(178,328)
O.MaxSize=Vector2.new(186,99999)
O.Parent=K

local P=Instance.new"ScrollingFrame"
P.Name="TabList"
P.Active=true
P.ScrollingDirection=Enum.ScrollingDirection.Y
P.BorderSizePixel=0
P.ScrollBarImageTransparency=1
P.BackgroundTransparency=1
P.VerticalScrollBarPosition=Enum.VerticalScrollBarPosition.Left
P.AutomaticCanvasSize=Enum.AutomaticSize.Y


P.Size=UDim2.new(1,0,1,-145)
P.Position=UDim2.new(0,0,0,94)
P.BorderColor3=Color3.fromRGB(0,0,0)
P.ScrollBarThickness=1
P.ScrollBarImageColor3=h.TertiaryColor
P.Parent=K


local Q
P:GetPropertyChangedSignal"CanvasPosition":Connect(function()
ac.Play(P,"Fast",{ScrollBarImageTransparency=0.5})
if Q then
task.cancel(Q)
end
Q=task.delay(1.5,function()
ac.Play(P,"Fast",{ScrollBarImageTransparency=1})
Q=nil
end)
end)

local R=Instance.new"UIListLayout"
R.HorizontalAlignment=Enum.HorizontalAlignment.Center
R.Padding=UDim.new(0,12)
R.SortOrder=Enum.SortOrder.LayoutOrder
R.Parent=P

local S=Instance.new"Frame"
S.Name="SearchBar"
S.BorderSizePixel=0
S.BackgroundColor3=h.SearchBarBackgroundColor
S.BackgroundTransparency=1
S:SetAttribute("IsSearchFocused",false)

S.Size=UDim2.new(1,0,0,26)
S.Position=UDim2.new(0,0,0,48)
S.BorderColor3=Color3.fromRGB(0,0,0)
S.Parent=K

local T=Instance.new"UICorner"
T.CornerRadius=UDim.new(0,6)
T.Parent=S

local U=Instance.new"UIStroke"
U.Transparency=1
U.Color=h.StrokeColor
U.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
U.Parent=S

local V=Instance.new"TextBox"
V.Name="SearchBox"
V.TextXAlignment=Enum.TextXAlignment.Left
V.PlaceholderColor3=Color3.fromRGB(100,100,100)
V.BorderSizePixel=0
V.TextTruncate=Enum.TextTruncate.AtEnd
V.TextTransparency=h.PrimaryTextTransparency
V.TextSize=12
V.TextColor3=h.PrimaryTextColor
V.BackgroundTransparency=1
V.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
V.PlaceholderText="Search..."
V.Size=UDim2.new(0.7921,0,1,0)
V.Position=UDim2.new(0.17991,0,0,0)
V.BorderColor3=Color3.fromRGB(0,0,0)
V.Text=""
V.Parent=S

local W=Instance.new"ImageLabel"
W.Name="SearchIcon"
W.BorderSizePixel=0
W.BackgroundTransparency=1
W.ImageTransparency=0.5
W.AnchorPoint=Vector2.new(0.5,0.5)
W.Image=ae.search
W.ImageColor3=h.SecondaryColor
W.Size=UDim2.new(0,12,0,12)
W.BorderColor3=Color3.fromRGB(0,0,0)
W.Position=UDim2.new(0.09543,0,0.5,0)
W.Parent=S

local X=Instance.new"Frame"
X.Name="BottomDivider"
X.BorderSizePixel=0
X.BackgroundColor3=h.TertiaryColor
X.BackgroundTransparency=0.9
X.AnchorPoint=Vector2.new(0.5,0.5)
X.Size=UDim2.new(0.8,0,0,1)
X.Position=UDim2.new(0.5,0,0,35)
X.BorderColor3=Color3.fromRGB(0,0,0)
X.Parent=S




S.BackgroundTransparency=1
V.Focused:Connect(function()
S:SetAttribute("IsSearchFocused",true)


local Y=j._theme or h
ac.Play(S,"Fast",{BackgroundTransparency=Y.SearchBarBackgroundTransparency or 0})
U.Color=Y.StrokeColor or U.Color
ac.Play(U,"Fast",{Transparency=Y.StrokeTransparency or 0.95})
ac.Play(W,"Fast",{ImageTransparency=0.2})
ac.Play(X,"Fast",{BackgroundTransparency=0.2})
end)
V.FocusLost:Connect(function()
S:SetAttribute("IsSearchFocused",false)
ac.Play(S,"Fast",{BackgroundTransparency=1})
ac.Play(U,"Fast",{Transparency=1})
ac.Play(W,"Fast",{ImageTransparency=0.5})
ac.Play(X,"Fast",{BackgroundTransparency=0.9})
end)



V:GetPropertyChangedSignal"Text":Connect(function()
if j and j.ApplySearch then
j:ApplySearch()
end
end)

local Y=Instance.new"Frame"
Y.Name="Divider"
Y.BorderSizePixel=0
Y.BackgroundColor3=h.TertiaryColor
Y.BackgroundTransparency=0.9

Y.AnchorPoint=Vector2.new(0.5,1)
Y.Size=UDim2.new(0.8,1,0,1)
Y.Position=UDim2.new(0.5,0,1,-48)
Y.BorderColor3=Color3.fromRGB(0,0,0)
Y.Parent=K




local Z=Instance.new"Frame"
Z.Name="UserInfo"
Z.BorderSizePixel=0
Z.BackgroundTransparency=1
Z.AnchorPoint=Vector2.new(0.5,1)
Z.Size=UDim2.new(1,0,0,50)
Z.Position=UDim2.new(0.5,0,1,8)
Z.BorderColor3=Color3.fromRGB(0,0,0)
Z.Parent=K

local _=Instance.new"UIPadding"
_.PaddingRight=UDim.new(0,10)
_.PaddingLeft=UDim.new(0,10)
_.Parent=Z

local as=Instance.new"Frame"
as.Name="InformationGroup"
as.BorderSizePixel=0
as.BackgroundTransparency=1
as.Size=UDim2.new(1,0,0.85,0)
as.BorderColor3=Color3.fromRGB(0,0,0)
as.Parent=Z

local at=Instance.new"UIListLayout"
at.VerticalAlignment=Enum.VerticalAlignment.Center
at.SortOrder=Enum.SortOrder.LayoutOrder
at.FillDirection=Enum.FillDirection.Horizontal
at.Parent=as

local au=Instance.new"ImageLabel"
au.Name="PlayerHeadshot"
au.BorderSizePixel=0
au.BackgroundTransparency=1
au.Image="rbxthumb://type=AvatarBust&id="..(i and i.UserId or 1).."&w=48&h=48"
au.Size=UDim2.new(0,32,0,32)
au.BorderColor3=Color3.fromRGB(0,0,0)
au.LayoutOrder=1
au.Parent=as

local av=Instance.new"UICorner"
av.CornerRadius=UDim.new(0,10)
av.Parent=au

local aw=Instance.new"ImageButton"
aw.Name="Settings"
aw.BorderSizePixel=0
aw.AutoButtonColor=false
aw.ImageTransparency=1
aw.BackgroundTransparency=1
aw.AnchorPoint=Vector2.new(0.5,0.5)
aw.Image=ae.settings
aw.ImageColor3=h.AccentColor or Color3.fromRGB(96,165,250)
aw.Size=UDim2.new(1,0,1,0)
aw.BorderColor3=Color3.fromRGB(0,0,0)
aw.Position=UDim2.new(0.5,0,0.5,0)
aw.Parent=au


au.MouseEnter:Connect(function()
ac.Play(au,"Fast",{ImageTransparency=1})
ac.Play(aw,"Fast",{ImageTransparency=0})
end)
au.MouseLeave:Connect(function()
ac.Play(au,"Fast",{ImageTransparency=0})
ac.Play(aw,"Fast",{ImageTransparency=1})
end)


aw.MouseButton1Click:Connect(function()
I.Visible=false
H.Visible=true
if j.SettingsTabGroup then
j.SettingsTabGroup:RefreshTitle()
end
end)

local ax=Instance.new"Frame"
ax.Name="NameContainer"
ax.BorderSizePixel=0
ax.BackgroundTransparency=1
ax.Size=UDim2.new(0.95823,-42,0,32)
ax.Position=UDim2.new(0.22278,0,0.19619,0)
ax.BorderColor3=Color3.fromRGB(0,0,0)
ax.LayoutOrder=2
ax.Parent=as

local ay=Instance.new"UIPadding"
ay.Name="UserAndDisplayFrameUIPadding"
ay.PaddingTop=UDim.new(0,3)
ay.PaddingLeft=UDim.new(0,8)
ay.Parent=ax

local az=Instance.new"UIListLayout"
az.Name="UserAndDisplayFrameUIListLayout"
az.Padding=UDim.new(0,4)
az.SortOrder=Enum.SortOrder.LayoutOrder
az.Parent=ax

local aA=Instance.new"TextLabel"
aA.Name="Username"
aA.TextTruncate=Enum.TextTruncate.SplitWord
aA.BorderSizePixel=0
aA.TextSize=12
aA.TextXAlignment=Enum.TextXAlignment.Left
aA.TextTransparency=0.7
aA.TextYAlignment=Enum.TextYAlignment.Top
aA.BackgroundTransparency=1
aA.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
aA.TextColor3=h.TitleTextColor
aA.Size=UDim2.new(1,0,0,0)
aA.BorderColor3=Color3.fromRGB(0,0,0)
aA.Text="@"..(i and i.Name or"Guest")
aA.LayoutOrder=1
aA.AutomaticSize=Enum.AutomaticSize.XY
aA.Parent=ax

local aB=Instance.new"TextButton"
aB.Name="DisplayName"
aB.BorderSizePixel=0
aB.TextXAlignment=Enum.TextXAlignment.Left
aB.TextTransparency=0.3
aB.TextSize=13
aB.TextColor3=h.TitleTextColor
aB.BackgroundTransparency=1
aB.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
aB.AutomaticSize=Enum.AutomaticSize.XY
aB.Size=UDim2.new(1,0,0,0)
aB.BorderColor3=Color3.fromRGB(0,0,0)
aB.Text=i and i.DisplayName or"Guest"
aB.Parent=ax

local aC=Instance.new"TextLabel"
aC.Name="TimeLabel"
aC.TextWrapped=true
aC.BorderSizePixel=0
aC.TextSize=12
aC.TextXAlignment=Enum.TextXAlignment.Left
aC.TextTransparency=0.3
aC.TextScaled=true
aC.BackgroundTransparency=1
aC.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
aC.TextColor3=h.TitleTextColor
aC.RichText=true
aC.Size=UDim2.new(0.1,0,0.7,0)
aC.BorderColor3=Color3.fromRGB(0,0,0)
aC.Text="<b>"..string.format("%02d",ar).."</b><br /><br />"..string.format("%02d",b)
aC.LayoutOrder=3
aC.AutomaticSize=Enum.AutomaticSize.XY
aC.Position=UDim2.new(0.83,0,0.89262,0)
aC.Parent=as




local aD=Instance.new"Frame"
aD.Name="ScriptInfo"
aD.BorderSizePixel=0
aD.BackgroundTransparency=1
aD.Size=UDim2.new(0.84065,0,0,42)
aD.BorderColor3=Color3.fromRGB(0,0,0)
aD.Parent=K

local aE=Instance.new"Frame"
aE.Name="InformationGroup"
aE.BorderSizePixel=0
aE.BackgroundTransparency=1
aE.Size=UDim2.new(1,0,1,0)
aE.BorderColor3=Color3.fromRGB(0,0,0)
aE.Parent=aD

local aF=Instance.new"UIListLayout"
aF.VerticalAlignment=Enum.VerticalAlignment.Center
aF.SortOrder=Enum.SortOrder.LayoutOrder
aF.FillDirection=Enum.FillDirection.Horizontal
aF.Parent=aE

local aG=Instance.new"ImageLabel"
aG.Name="ScriptLogo"
aG.BorderSizePixel=0
aG.BackgroundTransparency=1
aG.Image="rbxassetid://140238815705552"
aG.Size=UDim2.new(0,32,0,32)
aG.BorderColor3=Color3.fromRGB(0,0,0)
aG.LayoutOrder=1
aG.Parent=aE

local aH=Instance.new"UICorner"
aH.CornerRadius=UDim.new(0,6)
aH.Parent=aG

local aI=Instance.new"Frame"
aI.Name="ScriptInfoContainer"
aI.BorderSizePixel=0
aI.BackgroundTransparency=1
aI.Size=UDim2.new(0.95823,-42,0,32)
aI.Position=UDim2.new(0.22278,0,0.19619,0)
aI.BorderColor3=Color3.fromRGB(0,0,0)
aI.LayoutOrder=2
aI.Parent=aE

local aJ=Instance.new"UIPadding"
aJ.Name="UserAndDisplayFrameUIPadding"
aJ.PaddingTop=UDim.new(0,3)
aJ.PaddingLeft=UDim.new(0,8)
aJ.Parent=aI

local aK=Instance.new"UIListLayout"
aK.Name="UserAndDisplayFrameUIListLayout"
aK.Padding=UDim.new(0,4)
aK.SortOrder=Enum.SortOrder.LayoutOrder
aK.Parent=aI

local aL=Instance.new"TextLabel"
aL.Name="ScriptName"
aL.TextTruncate=Enum.TextTruncate.SplitWord
aL.BorderSizePixel=0
aL.TextSize=13
aL.TextXAlignment=Enum.TextXAlignment.Left
aL.TextTransparency=0.3
aL.TextYAlignment=Enum.TextYAlignment.Top
aL.BackgroundTransparency=1
aL.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
aL.TextColor3=h.TitleTextColor
aL.Size=UDim2.new(1.36294,0,0.44828,0)
aL.BorderColor3=Color3.fromRGB(0,0,0)
aL.Text="Aetheris | Jailbreak"
aL.LayoutOrder=1
aL.AutomaticSize=Enum.AutomaticSize.XY
aL.Position=UDim2.new(0,0,0,0)
aL.Parent=aI

local aM=Instance.new"TextLabel"
aM.Name="ScriptDescription"
aM.TextTruncate=Enum.TextTruncate.SplitWord
aM.BorderSizePixel=0
aM.TextSize=10
aM.TextXAlignment=Enum.TextXAlignment.Left
aM.TextTransparency=0.7
aM.TextYAlignment=Enum.TextYAlignment.Top
aM.BackgroundTransparency=1
aM.FontFace=Font.new("rbxassetid://12187365364",Enum.FontWeight.SemiBold,Enum.FontStyle.Normal)
aM.TextColor3=h.TitleTextColor
aM.RichText=true
aM.Size=UDim2.new(1.36294,0,0.41379,0)
aM.BorderColor3=Color3.fromRGB(0,0,0)
aM.Text="build 0.0.1 ver 1.0"
aM.LayoutOrder=2
aM.AutomaticSize=Enum.AutomaticSize.XY
aM.Position=UDim2.new(0,0,0.58621,0)
aM.Parent=aI




local aN=Instance.new"ImageButton"
aN.Name="ResizeButton"
aN.BorderSizePixel=0
aN.AutoButtonColor=false
aN.ImageTransparency=1
aN.BackgroundTransparency=1
aN.AnchorPoint=Vector2.new(1,1)
aN.Image="rbxassetid://8445471173"
aN.ImageRectSize=Vector2.new(96,96)
aN.ImageRectOffset=Vector2.new(704,804)
aN.Size=UDim2.new(0,28,0,28)
aN.BorderColor3=Color3.fromRGB(0,0,0)
aN.Position=UDim2.new(0.99,0,0.99,0)
aN.Parent=n




if d.Title then
aL.Text=d.Title
end
if d.Description then
aM.Text=d.Description
end
if d.AnimationStyle then
c.AnimationStyle=d.AnimationStyle
end
if d.DragStyle then
c.DragStyle=d.DragStyle
end




j=setmetatable({},c)



j._theme=h



if type(d.Theme)=="string"then
j._themeName=d.Theme
else
j._themeName="Default"
end




local aO=d.MinimizeKey
if type(aO)~="string"or aO==""then
j._minimizeKey="M"
else
j._minimizeKey=(#aO==1)and string.upper(aO)or aO
end

j.Base=m
j.MainFrame=n
j.Notifications=E
j.ContentBackground=t
j.Content=C
j.PopUpsFolder=D
j.SettingsPages=H
j.TabContent=I
j.Sidebar=K
j.TabList=P
j.SearchBox=V
j.PageTitle=A
j.ScriptName=aL
j.ScriptDescription=aM
j.WindowControls=v






do
local aP=false
local aQ=false
local aR
local aS


local function updateResizeVisual()
local aT=1
if aP then
aT=0
elseif aQ then
aT=0.5
end
ac.Play(aN,"Fast",{ImageTransparency=aT})
end
aN.MouseEnter:Connect(function()
aQ=true
updateResizeVisual()
end)
aN.MouseLeave:Connect(function()
aQ=false
updateResizeVisual()
end)

aN.InputBegan:Connect(function(aT)
if aT.UserInputType==Enum.UserInputType.MouseButton1
or aT.UserInputType==Enum.UserInputType.Touch then
aP=true
updateResizeVisual()
aR=aT.Position
aS=n.AbsoluteSize

aT.Changed:Connect(function()
if aT.UserInputState==Enum.UserInputState.End then
aP=false
updateResizeVisual()
end
end)
end
end)

l=aa.InputChanged:Connect(function(aT)
if aP and(aT.UserInputType==Enum.UserInputType.MouseMovement
or aT.UserInputType==Enum.UserInputType.Touch)then
local aU=aT.Position-aR
local aV=s.MinSize
local aW=math.max(aV.X,aS.X+aU.X)
local aX=math.max(aV.Y,aS.Y+aU.Y)
n.Size=UDim2.new(0,aW,0,aX)
end
end)
end





local aP=aj.new(m,h)
j.Tooltip=aP

local function minimizePreset()
return c.AnimationStyle=="Snappy"and"MinimizeSnappy"or"Minimize"
end





local function captureFade(aQ)
local aR={}
local aS={aQ}
for aT,aU in ipairs(aQ:GetDescendants())do
aS[#aS+1]=aU
end
for aT,aU in ipairs(aS)do



if aU:IsA"UIGradient"and aU:GetAttribute"IsVideoFade"then
aR[#aR+1]={instance=aU,isVideo=true,base=ak.get(aU)}
else
local aV={}
if aU:IsA"GuiObject"then
aV[#aV+1]={"BackgroundTransparency",aU.BackgroundTransparency}
local aW,aX=pcall(function()return aU.TextTransparency end)
if aW and type(aX)=="number"then aV[#aV+1]={"TextTransparency",aX}end
local aY,aZ=pcall(function()return aU.ImageTransparency end)
if aY and type(aZ)=="number"then aV[#aV+1]={"ImageTransparency",aZ}end
end
if aU:IsA"UIStroke"or aU:IsA"UIShadow"then
aV[#aV+1]={"Transparency",aU.Transparency}
end
if#aV>0 then
aR[#aR+1]={instance=aU,props=aV}
end
end
end
return aR
end




local function fadeGroup(aQ,aR,aS,aT)
aS=aS or 0.3
local aU=0
local aV=false
local function finished()
aU=aU-1
if aU<=0 and not aV then
aV=true
if aT then aT()end
end
end
for aW,aX in ipairs(aQ)do
local aY=aX.instance
if aY.Parent then
if aX.isVideo then

local aZ=aR==nil and aX.base or aR
aU=aU+1

ak.fade(aY,aZ,aS,"InOut",finished)
else
for aZ,a_ in ipairs(aX.props)do
local a0,a1=a_[1],a_[2]
local a2=aR==nil and a1 or aR
aU=aU+1
local a3=ac.Play(aY,"Smooth",{[a0]=a2})
a3.Tween.Completed:Connect(finished)
end
end
end
end
if aU==0 and aT then aT()end
end






local aQ=Instance.new"CanvasGroup"
aQ.Name="MinimizePill"
aQ.AnchorPoint=Vector2.new(1,0.5)
aQ.Position=UDim2.new(1,-12,0.5,0)
aQ.AutomaticSize=Enum.AutomaticSize.Y
aQ.Size=UDim2.new(0,56,0,0)
aQ.BackgroundColor3=h.PopupBackgroundColor or Color3.fromRGB(15,15,16)
aQ.BackgroundTransparency=1
aQ.BorderSizePixel=0
aQ.Visible=false
aQ.ZIndex=1500
aQ.Parent=m
j.MinimizePill=aQ

local aR=Instance.new"UICorner"
aR.CornerRadius=UDim.new(1,0)
aR.Parent=aQ
local aS=Instance.new"UIStroke"
aS.Color=h.StrokeColor or Color3.fromRGB(255,255,255)
aS.Transparency=0.7
aS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
aS.Parent=aQ
local aT=Instance.new"UIShadow"
aT.Color=h.PopupShadowColor or Color3.fromRGB(0,0,0)
aT.BlurRadius=UDim.new(0,16)
aT.Transparency=1
aT.Parent=aQ
local aU=Instance.new"UIScale"
aU.Scale=1
aU.Parent=aQ





local aV=0.55
local aW=0
local aX=0.85
local aY=1
aQ.GroupTransparency=aV
aQ.MouseEnter:Connect(function()
ac.Play(aQ,"Fast",{GroupTransparency=aW})
ac.Play(aU,"HoverIn",{Scale=aY})
ac.Play(aT,"Fast",{Transparency=0.5})
end)
aQ.MouseLeave:Connect(function()
ac.Play(aQ,"Fast",{GroupTransparency=aV})
ac.Play(aU,"HoverOut",{Scale=aX})
ac.Play(aT,"Fast",{Transparency=1})
end)
local aZ=Instance.new"UIPadding"
aZ.PaddingTop=UDim.new(0,8)
aZ.PaddingBottom=UDim.new(0,8)
aZ.PaddingLeft=UDim.new(0,8)
aZ.PaddingRight=UDim.new(0,8)
aZ.Parent=aQ
local a_=Instance.new"UIListLayout"
a_.Padding=UDim.new(0,8)
a_.HorizontalAlignment=Enum.HorizontalAlignment.Center
a_.SortOrder=Enum.SortOrder.LayoutOrder
a_.Parent=aQ

local a0
local a1
local a2
local a3
local a4
local a5={}

a0=function()


local a6=j._theme or h

aP:SetTheme(a6)




aQ.BackgroundColor3=a6.PopupBackgroundColor or Color3.fromRGB(15,15,16)
aQ.BackgroundTransparency=0.05
aQ.GroupTransparency=aV
aS.Color=a6.StrokeColor or Color3.fromRGB(255,255,255)
aS.Transparency=0.7
aT.Color=a6.PopupShadowColor or Color3.fromRGB(0,0,0)
aT.Transparency=1
for a7,a8 in ipairs(a5)do
a8:Destroy()
end
a5={}
if not j.TabGroup then return end
for a7,a8 in ipairs(j.TabGroup.Tabs)do
local a9=(a8==j.TabGroup.ActiveTab)
local ba=Instance.new"TextButton"
ba.Name=a8.Name.."PillButton"
ba.Size=UDim2.new(0,40,0,40)

ba.BackgroundColor3=a6.ActiveTabButtonColor or a6.PrimaryColor or Color3.fromRGB(99,102,241)
ba.BackgroundTransparency=a9 and 0.1 or 1
ba.AutoButtonColor=false
ba.Text=""
ba.LayoutOrder=a7
ba.ZIndex=1501
ba.Parent=aQ
local bb=Instance.new"UICorner"
bb.CornerRadius=UDim.new(1,0)
bb.Parent=ba

local bc=Instance.new"UIScale"
bc.Scale=1
bc.Parent=ba

local bd=Instance.new"ImageLabel"
bd.Name="BackImage"
bd.BorderSizePixel=0
bd.BackgroundTransparency=1
bd.Image=(a8.BackImage and a8.BackImage.Image)or"rbxassetid://11094025229"

bd.ImageTransparency=a9 and 0 or 1
bd.Size=UDim2.fromScale(1,1)
bd.ZIndex=1501
bd.Parent=ba
local be=Instance.new"UICorner"
be.CornerRadius=UDim.new(1,0)
be.Parent=bd
local bf=Instance.new"UIGradient"
bf.Rotation=0
bf.Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.000,0),
NumberSequenceKeypoint.new(0.134,0.3),
NumberSequenceKeypoint.new(0.242,0.53125),
NumberSequenceKeypoint.new(0.371,0.69375),
NumberSequenceKeypoint.new(0.484,0.80625),
NumberSequenceKeypoint.new(0.590,0.91875),
NumberSequenceKeypoint.new(0.681,0.975),
NumberSequenceKeypoint.new(1.000,1),
}
bf.Parent=bd
if a9 then
ac.StartSpin(bf,{Rotation=360},"SpinIdle")
end
local bg=Instance.new"ImageLabel"
bg.Name="PillIcon"
bg.BorderSizePixel=0
bg.BackgroundTransparency=1
bg.Image=(a8.TabImage and a8.TabImage.Image)or"rbxassetid://8445470392"
bg.ImageColor3=a9 and(a6.ActiveTabIconColor or Color3.fromRGB(255,255,255))or(a6.InactiveTabIconColor or Color3.fromRGB(200,200,200))
bg.ImageTransparency=a9 and(a6.ActiveTabIconTransparency or 0.2)or(a6.InactiveTabIconTransparency or 0.6)
bg.AnchorPoint=Vector2.new(0.5,0.5)
bg.Position=UDim2.fromScale(0.5,0.5)
bg.Size=UDim2.fromOffset(18,18)
bg.ZIndex=1502
bg.Parent=ba
ba.MouseEnter:Connect(function()
ac.Play(bc,"HoverIn",{Scale=1.18})
aP:ShowAt(ba,a8.Name,"Left",11)
end)
ba.MouseLeave:Connect(function()
ac.Play(bc,"HoverOut",{Scale=1})
aP:Hide()
end)
ba.MouseButton1Click:Connect(function()


if j.SettingsPages then j.SettingsPages.Visible=false end
if j.TabContent then j.TabContent.Visible=true end
if j.TabGroup then
j.TabGroup:SetActiveTab(a8)
end
a2()
end)
table.insert(a5,ba)
end
end






local a6="shown"

a1=function()
if a6~="shown"then return end
a6="minimizing"
ad.Play"UIClose"
j._windowFaded=true



if j.TabGroup and j.TabGroup.PrimeCaches then
j.TabGroup:PrimeCaches()
end
a0()



for a7,a8 in ipairs{x,y,z}do
if a8 then
a8.ImageTransparency=0.5
local a9=a8:FindFirstChildOfClass"UIScale"
if a9 then a9.Scale=1 end
end
end
a3=captureFade(n)


fadeGroup(a3,1,0.3,function()
n.Visible=false
aQ.Visible=true
aQ.BackgroundTransparency=0.05
aQ.GroupTransparency=1
aU.Scale=0.7

ac.Play(aQ,"Fast",{GroupTransparency=aV})
ac.Play(aU,"HoverIn",{Scale=aX})


task.delay(0.25,function()
a4=captureFade(aQ)
end)
a6="hidden"
end)
end

a2=function()
if a6~="hidden"then return end
a6="restoring"
ad.Play"UIOpen"
aP:Hide()



n.Visible=true
fadeGroup(a3,nil,0.3,function()


j._windowFaded=false
if j.TabGroup and j.TabGroup.RefreshVisuals then
j.TabGroup:RefreshVisuals()
end





if j.TabGroup and j.TabGroup.RestoreActiveTab then
j.TabGroup:RestoreActiveTab()
end
a6="shown"
end)

if a4 then
fadeGroup(a4,1)
else
ac.Play(aQ,"Fast",{BackgroundTransparency=1})
end
ac.Play(aU,"Fast",{Scale=0.85})
task.delay(0.3,function()
aQ.Visible=false
aU.Scale=1
end)
end






j.ToggleMinimize=function()
if j._destroyed then return end
if a6=="shown"then
a1()
elseif a6=="hidden"then
a2()
end
end

x.MouseButton1Click:Connect(function()
j.ToggleMinimize()
end)


j.ResetLayout=function()
ac.Play(n,minimizePreset(),{
Size=UDim2.new(0.72026,0,0.96995,0),
Position=UDim2.new(0.013,0,0.015,0),
})
end




local a7=false
local a8=n.Size
local a9=n.Position
y.MouseButton1Click:Connect(function()
a7=not a7
if a7 then
a8=n.Size
a9=n.Position
ac.Play(n,minimizePreset(),{
Size=UDim2.fromScale(1,1),
Position=UDim2.fromScale(0,0),
})
else
ac.Play(n,minimizePreset(),{
Size=a8,
Position=a9,
})
end
end)







j._teardown=function()
if j._destroyed then return end
j._destroyed=true

if k then
k:Disconnect()
k=nil
end
if l then
l:Disconnect()
l=nil
end

if Q then
task.cancel(Q)
Q=nil
end

ac.CancelAll(m)
for ba,bb in ipairs(m:GetDescendants())do
ac.CancelAll(bb)
end

if j._notification then
j._notification:Destroy()
j._notification=nil
end
if j._dropdownPopups then
for ba,bb in pairs(j._dropdownPopups)do bb:Destroy()end
j._dropdownPopups=nil
end
if j._colorPickerPopups then
for ba,bb in pairs(j._colorPickerPopups)do bb:Destroy()end
j._colorPickerPopups=nil
end
end

local function doClose()

local ba=captureFade(n)
fadeGroup(ba,1)
ad.Play"UIShutdown"


task.delay(0.4,function()
j._teardown()
j.Base:Destroy()
end)
end

z.MouseButton1Click:Connect(function()

if not ap.Get"ConfirmClose"then
doClose()
return
end
j:UINotification{
Title="Close Aetheris?",
Description="Are you sure you want to <font color=\"#FF0000\">close</font> the UI?",
TitleColor=Color3.fromRGB(255,0,0),
ConfirmText="Yes, close it",
CancelText="No, keep it open",
OnConfirm=doClose,
}
end)

j.TabGroup=af.new(j,h)
j.SettingsTabGroup=an.new(j,h)


ao.BuildDefaultPages(j)


if type(d.SettingsPages)=="table"then
for ba,bb in ipairs(d.SettingsPages)do
j.SettingsTabGroup:Tab{
Name=bb.Name or"Settings",
Icon=bb.Icon,
}
end
end


if d.DefaultSettingsPage then
j.SettingsTabGroup:SetActiveTabByName(d.DefaultSettingsPage)
end


al.ApplyTheme(j,h)



ad.Play"UIStart"
local ba=captureFade(n)
for bb,bc in ipairs(ba)do
if bc.isVideo then
if bc.instance.Parent then ak.set(bc.instance,1)end
elseif bc.instance.Parent then
for bd,be in ipairs(bc.props)do
bc.instance[be[1] ]=1
end
end
end
fadeGroup(ba,nil,0.35)



function j.GetActivePage(bb)
if bb.SettingsPages and bb.SettingsPages.Visible then
local bc=bb.SettingsTabGroup and bb.SettingsTabGroup.ActiveTab
return bc and bc.Page or nil
end
local bc=bb.TabGroup and bb.TabGroup.ActiveTab
return bc and bc.ContentScroller or nil
end



function j.ApplySearch(bb)
local bc=bb:GetActivePage()
if not bc then return end
am.Apply(bc,bb.SearchBox.Text,bb._theme)
end






function j.ApplyTheme(bb,bc)
local bd=al.GetTheme(bc)
bb._theme=bd


n.BackgroundColor3=bd.WindowColor or n.BackgroundColor3
if bd.WindowTransparency~=nil then
n.BackgroundTransparency=bd.WindowTransparency
end
t.BackgroundColor3=bd.ContentBackgroundColor or bd.WindowColor or t.BackgroundColor3
local be=bd.ContentBackgroundTransparency
if be==nil then be=bd.WindowTransparency end
if be~=nil then
t.BackgroundTransparency=be
end
K.BackgroundColor3=bd.SidebarColor or K.BackgroundColor3
if bd.SidebarTransparency~=nil then
K.BackgroundTransparency=bd.SidebarTransparency
end
r.Color=bd.MainframeShadowColor or r.Color


for bf,bg in ipairs{x,y,z}do
if bg then
bg.ImageColor3=bd.WindowControlColor or bg.ImageColor3
end
end


A.TextColor3=bd.TitleTextColor or A.TextColor3
B.BackgroundColor3=bd.TertiaryColor or B.BackgroundColor3


S.BackgroundColor3=bd.SearchBarBackgroundColor or S.BackgroundColor3
local bf=S:GetAttribute"IsSearchFocused"
if bf then
S.BackgroundTransparency=bd.SearchBarBackgroundTransparency or 0
U.Transparency=bd.StrokeTransparency or 0.95
else
S.BackgroundTransparency=1
U.Transparency=1
end
V.TextColor3=bd.PrimaryTextColor or V.TextColor3
V.TextTransparency=bd.PrimaryTextTransparency or V.TextTransparency
W.ImageColor3=bd.SecondaryColor or W.ImageColor3
U.Color=bd.StrokeColor or U.Color
X.BackgroundColor3=bd.TertiaryColor or X.BackgroundColor3


Y.BackgroundColor3=bd.TertiaryColor or Y.BackgroundColor3
aw.ImageColor3=bd.AccentColor or aw.ImageColor3


aL.TextColor3=bd.TitleTextColor or aL.TextColor3
aM.TextColor3=bd.TitleTextColor or aM.TextColor3
aA.TextColor3=bd.TitleTextColor or aA.TextColor3
aB.TextColor3=bd.TitleTextColor or aB.TextColor3
aC.TextColor3=bd.TitleTextColor or aC.TextColor3


P.ScrollBarImageColor3=bd.TertiaryColor or P.ScrollBarImageColor3


aQ.BackgroundColor3=bd.PopupBackgroundColor or aQ.BackgroundColor3
aS.Color=bd.StrokeColor or aS.Color
aT.Color=bd.PopupShadowColor or aT.Color


if aP and aP.SetTheme then
aP:SetTheme(bd)
end
end

return j
end

function c.SetTitle(as,at)
as.ScriptName.Text=at
end

function c.SetDescription(as,at)
as.ScriptDescription.Text=at
end


function c.SetTheme(as,at)
local au=a.f()
if type(at)=="string"then
as._themeName=at
end

au.UpdateTheme(as,at)






local function refreshPopups(av)
if not av then return end
for aw,ax in pairs(av)do
if ax.ApplyTheme then
ax:ApplyTheme(as._theme)
elseif ax.Destroy then
ax:Destroy()
av[aw]=nil
end
end
end
refreshPopups(as._dropdownPopups)
refreshPopups(as._colorPickerPopups)



if as._notification then
as._notification:Destroy()
as._notification=nil
end
end

function c.Destroy(as)
local at=c.AnimationStyle=="Snappy"and"FadeOut"or"Smooth"

ad.Play"WindowClose"

if as._teardown then as._teardown()end

local au=ac.Play(as.MainFrame,at,{BackgroundTransparency=1})
au.Tween.Completed:Wait()

ac.CancelAll(as.MainFrame)
as.Base:Destroy()
end


function c.Tab(as,at,au)
return as.TabGroup:Tab{Name=at,Icon=au}
end

function c.Divider(as)
return as.TabGroup:Divider()
end


function c.UINotification(as,at)

if type(at)~="table"then
warn"[Window:UINotification] Settings is not a table, defaulting to {}"
at={}
end


if as._notification then
as._notification:Close()
as._notification:Destroy()
as._notification=nil
end


at.Theme=as._theme
as._notification=ag.new(as.PopUpsFolder,at)
as._notification:Open()
return as._notification
end


local as=a.K()

local function spawnNotification(at,au,av)
if type(av)~="table"then
av={}
end
av.Type=au
local aw=as.new(at.Notifications,av,at._theme)
aw:Show()
return aw
end

function c.Alert(at,au)
return spawnNotification(at,"Alert",au)
end

function c.Error(at,au)
return spawnNotification(at,"Error",au)
end

function c.VariableNotification(at,au)
return spawnNotification(at,"Variable",au)
end

function c.DropdownPopUp(at,au,av)

if type(av)~="table"then
warn"[Window:DropdownPopUp] Settings is not a table, defaulting to {}"
av={}
end


av.Theme=at._theme


if not at._dropdownPopups then
at._dropdownPopups={}
end

local aw=at._dropdownPopups[au]
if not aw then

aw=ah.new(at.PopUpsFolder,av,function()

if at._dropdownPopups then
at._dropdownPopups[au]=nil
end
if at._activePopupId==au then
at._activePopupId=nil
end
end)
at._dropdownPopups[au]=aw
else
aw:SetContent(av)
end


if at._activePopupId and at._activePopupId~=au then
local ax=at._dropdownPopups[at._activePopupId]
if ax then
ax:Hide()
end
end


if aw then
aw:Open()
at._activePopupId=au
end
return aw
end

function c.ColorPickerPopUp(at,au,av)

if type(av)~="table"then
warn"[Window:ColorPickerPopUp] Settings is not a table, defaulting to {}"
av={}
end


av.Theme=at._theme

if not at._colorPickerPopups then
at._colorPickerPopups={}
end

local aw=at._colorPickerPopups[au]
if not aw then
aw=ai.new(at.PopUpsFolder,av,function()
if at._colorPickerPopups then
at._colorPickerPopups[au]=nil
end
if at._activeColorPickerId==au then
at._activeColorPickerId=nil
end
end)
at._colorPickerPopups[au]=aw
aw:SetContent(av)
else
aw:SetContent(av)
end


if at._activeColorPickerId and at._activeColorPickerId~=au then
local ax=at._colorPickerPopups[at._activeColorPickerId]
if ax then
ax:Hide()
end
end

if aw then
aw:Open()
at._activeColorPickerId=au
end
return aw
end


function c.HidePopups(at)
if at._notification then
at._notification:Hide()
end
if at._activePopupId then
local au=at._dropdownPopups and at._dropdownPopups[at._activePopupId]
if au then
au:Hide()
end
at._activePopupId=nil
end
if at._activeColorPickerId then
local au=at._colorPickerPopups and at._colorPickerPopups[at._activeColorPickerId]
if au then
au:Hide()
end
at._activeColorPickerId=nil
end
end

return c end function a.L():typeof(__modImpl())local aa=a.cache.L if not aa then aa={c=__modImpl()}a.cache.L=aa end return aa.c end end end




























local aa=a.L()
local ab=a.c()
local ac=a.f()
local ad=a.d()

local ae={}

ae.Icons=ab
ae.Window=aa
ae.ThemeManager=ac
ae.ThemeDefinitions=ad

function ae.CreateWindow(af,ag)
return aa.new(ag)
end

return ae