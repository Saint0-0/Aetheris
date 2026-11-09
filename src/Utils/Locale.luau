--[[
	Aetheris/Utils/Locale.luau

	Localization core, modelled on Rayfield's locale utility (MPL-2.0).
	English is canonical: every chrome string in src is written in it, so the
	source text is its own lookup key and a missing entry falls back to plain
	English instead of a raw key. Built-in tables sit in Locale.strings keyed
	by lowercased locale id; devs merge more with Locale.register().

	resolve() runs dev translator -> exact locale ("pt-br") -> language-only
	("pt") -> source. Only strings passed through it are copy; element values,
 slider readouts and keybind keys are data and stay untouched.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Locale = {}

-- A wrapped string carries this tag so resolve() can tell copy from a plain
-- value; property values are never plain tables, so the shape is unambiguous.
local tokenTag = {}

Locale.strings = {
	es = {
		["Search..."] = "Buscar...",
		["Themes"] = "Temas",
		["UI Settings"] = "Ajustes de interfaz",
		["Configs"] = "Configuraciones",
		["Settings"] = "Ajustes",
		["Interface"] = "Interfaz",
		["Compact Mode"] = "Modo compacto",
		["Behaviour"] = "Comportamiento",
		["Visuals"] = "Visuales",
		["Minimize Pill"] = "Píldora de minimizar",
		["Actions"] = "Acciones",
		["Save"] = "Guardar",
		["Load"] = "Cargar",
		["Options"] = "Opciones",
		["Preview"] = "Vista previa",
		["UI Scale"] = "Escala de UI",
		["Font"] = "Fuente",
		["Locale"] = "Idioma",
		["Auto Mask User/Display Name"] = "Máscara automática de nombres",
		["Spinning Animations"] = "Animaciones giratorias",
		["Page Animations"] = "Animaciones de página",
		["Confirm On Close"] = "Confirmar al cerrar",
		["Minimize UI"] = "Minimizar interfaz",
		["Aurora Background"] = "Fondo aurora",
		["Aurora Transparency"] = "Transparencia de aurora",
		["UI Volume"] = "Volumen de la interfaz",
		["Reset Layout"] = "Restablecer diseño",
		["Auto"] = "Auto",
		["Always"] = "Siempre",
		["Never"] = "Nunca",
		["Right"] = "Derecha",
		["Left"] = "Izquierda",
		["Top"] = "Arriba",
		["Bottom"] = "Abajo",
		["Config Name"] = "Nombre de configuración",
		["Save Config"] = "Guardar configuración",
		["Overwrite Config"] = "Sobrescribir configuración",
		["Config Files"] = "Archivos de configuración",
		["Load Config"] = "Cargar configuración",
		["Delete Config"] = "Eliminar configuración",
		["Auto-Save"] = "Guardado automático",
		["Config Preview"] = "Vista previa de configuración",
		["No config loaded"] = "Ninguna configuración cargada",
		["Config files need an executor file API (writefile/readfile). They are unavailable in Studio or a plain game."] = "Los archivos de configuración necesitan la API de archivos de un executor (writefile/readfile). No están disponibles en Studio ni en un juego normal.",
		["Confirm"] = "Confirmar",
		["Cancel"] = "Cancelar",
		["None selected"] = "Ninguno seleccionado",
		["Notification"] = "Notificación",
		["Alert"] = "Alerta",
		["Error"] = "Error",
		["Changes saved!"] = "¡Cambios guardados!",
		["Click"] = "Clic",
		["Confirm Action"] = "Confirmar acción",
		["Are you sure you want to change this setting?"] = "¿Seguro que quieres cambiar esta configuración?",
		["Yes"] = "Sí",
		["No"] = "No",
		["Enter your key"] = "Introduce tu clave",
		["Enter your key to continue"] = "Introduce tu clave para continuar",
		["Access granted"] = "Acceso concedido",
		["Continue"] = "Continuar",
		["Loading"] = "Cargando",
		["Loading assets"] = "Cargando recursos",
		["Loading sounds"] = "Cargando sonidos",
		["Key history"] = "Historial de claves",
		["Information"] = "Información",
		["Tap to view"] = "Toca para ver",
		["Changelog"] = "Registro de cambios",
		["Locale applied."] = "Idioma aplicado.",
		["Close %s?"] = "¿Cerrar %s?",
		['Are you sure you want to <font color="#FF0000">close</font> %s?'] = '¿Seguro que quieres <font color="#FF0000">cerrar</font> %s?',
		["Yes, close it"] = "Sí, cerrarlo",
		["No, keep it open"] = "No, mantenerlo abierto",
		["the UI"] = "la interfaz",
		["Element"] = "Elemento",
		["Text Input"] = "Campo de texto",
		["Color"] = "Color",
		["Stat"] = "Dato",
	},
	pt = {
		["Search..."] = "Pesquisar...",
		["Themes"] = "Temas",
		["UI Settings"] = "Ajustes de UI",
		["Configs"] = "Configurações",
		["Settings"] = "Ajustes",
		["Interface"] = "Interface",
		["Compact Mode"] = "Modo compacto",
		["Behaviour"] = "Comportamento",
		["Visuals"] = "Visuais",
		["Minimize Pill"] = "Pílula de minimizar",
		["Actions"] = "Ações",
		["Save"] = "Salvar",
		["Load"] = "Carregar",
		["Options"] = "Opções",
		["Preview"] = "Prévia",
		["UI Scale"] = "Escala de UI",
		["Font"] = "Fonte",
		["Locale"] = "Idioma",
		["Auto Mask User/Display Name"] = "Máscara automática de nomes",
		["Spinning Animations"] = "Animações giratórias",
		["Page Animations"] = "Animações de página",
		["Confirm On Close"] = "Confirmar ao fechar",
		["Minimize UI"] = "Minimizar UI",
		["Aurora Background"] = "Fundo aurora",
		["Aurora Transparency"] = "Transparência da aurora",
		["UI Volume"] = "Volume da UI",
		["Reset Layout"] = "Redefinir layout",
		["Auto"] = "Automático",
		["Always"] = "Sempre",
		["Never"] = "Nunca",
		["Right"] = "Direita",
		["Left"] = "Esquerda",
		["Top"] = "Topo",
		["Bottom"] = "Inferior",
		["Config Name"] = "Nome da configuração",
		["Save Config"] = "Salvar configuração",
		["Overwrite Config"] = "Sobrescrever configuração",
		["Config Files"] = "Arquivos de configuração",
		["Load Config"] = "Carregar configuração",
		["Delete Config"] = "Excluir configuração",
		["Auto-Save"] = "Salvamento automático",
		["Config Preview"] = "Prévia da configuração",
		["No config loaded"] = "Nenhuma configuração carregada",
		["Config files need an executor file API (writefile/readfile). They are unavailable in Studio or a plain game."] = "Os arquivos de configuração precisam da API de arquivos de um executor (writefile/readfile). Não estão disponíveis no Studio nem em um jogo comum.",
		["Confirm"] = "Confirmar",
		["Cancel"] = "Cancelar",
		["None selected"] = "Nenhum selecionado",
		["Notification"] = "Notificação",
		["Alert"] = "Alerta",
		["Error"] = "Erro",
		["Changes saved!"] = "Alterações salvas!",
		["Click"] = "Clique",
		["Confirm Action"] = "Confirmar ação",
		["Are you sure you want to change this setting?"] = "Tem certeza de que deseja alterar esta configuração?",
		["Yes"] = "Sim",
		["No"] = "Não",
		["Enter your key"] = "Digite sua chave",
		["Enter your key to continue"] = "Digite sua chave para continuar",
		["Access granted"] = "Acesso concedido",
		["Continue"] = "Continuar",
		["Loading"] = "Carregando",
		["Loading assets"] = "Carregando recursos",
		["Loading sounds"] = "Carregando sons",
		["Key history"] = "Histórico de chaves",
		["Information"] = "Informações",
		["Tap to view"] = "Toque para ver",
		["Changelog"] = "Log de alterações",
		["Locale applied."] = "Idioma aplicado.",
		["Close %s?"] = "Fechar %s?",
		['Are you sure you want to <font color="#FF0000">close</font> %s?'] = 'Tem certeza de que deseja <font color="#FF0000">fechar</font> %s?',
		["Yes, close it"] = "Sim, fechar",
		["No, keep it open"] = "Não, manter aberto",
		["the UI"] = "a interface",
		["Element"] = "Elemento",
		["Text Input"] = "Campo de texto",
		["Color"] = "Cor",
		["Stat"] = "Estatística",
	},
}

-- Active locale id plus the optional dev hook (source, localeId) -> string?.
-- Both start neutral, so with no setup at all everything renders in English.
Locale.current = "en"
Locale.translator = nil

local function languageOf(id)
	return string.match(id, "^(%a+)") or id
end

-- Wrap a string so it localizes. Non-strings pass through untouched so
-- callers can wrap unconditionally without special-casing nil.
function Locale.t(source)
	if type(source) ~= "string" or source == "" then
		return source
	end
	return { [tokenTag] = source }
end

-- True for a value produced by Locale.t that still carries a source string.
function Locale.isToken(value)
	return type(value) == "table" and type(value[tokenTag]) == "string"
end

function Locale.sourceOf(token)
	return token[tokenTag]
end

-- Resolve a source string (or token) to the active locale: dev translator
-- wins, then the exact-locale table, then the language-only table, then the
-- source itself. The translator is pcall'd so a bad dev hook can't take the
-- UI down.
function Locale.resolve(value)
	local source = value
	if Locale.isToken(value) then
		source = Locale.sourceOf(value)
	elseif type(value) ~= "string" then
		return value
	end
	if Locale.translator then
		local ok, translated = pcall(Locale.translator, source, Locale.current)
		if ok and type(translated) == "string" and translated ~= "" then
			return translated
		end
	end
	local exact = Locale.strings[Locale.current]
	if exact and exact[source] then
		return exact[source]
	end
	local language = Locale.strings[languageOf(Locale.current)]
	if language and language[source] then
		return language[source]
	end
	return source
end

-- Merge dev-supplied tables into the built-in set, keyed by locale id
-- (lowercased), each a map of source string -> translation. Merges rather
-- than replaces, so repeated calls accumulate instead of clobbering.
-- Entries are checked here rather than trusted: a non-string translation
-- would sail through resolve() into a Text property and only blow up at
-- render, nowhere near the register call.
function Locale.register(tables)
	if type(tables) ~= "table" then
		return
	end
	for id, entries in pairs(tables) do
		if type(id) == "string" and type(entries) == "table" then
			id = string.lower(id)
			local target = Locale.strings[id]
			if not target then
				target = {}
				Locale.strings[id] = target
			end
			for source, translated in pairs(entries) do
				if type(source) == "string" and type(translated) == "string" then
					target[source] = translated
				else
					warn("[Aetheris] skipping a '" .. id .. "' translation, entries must be string to string.")
				end
			end
		end
	end
end

-- Point the active locale at localeId (lowercased), falling back to English
-- when it isn't a usable string. Setting it alone touches nothing on screen;
-- call refresh() after it to re-resolve the live UI in place.
function Locale.setActive(localeId)
	if type(localeId) == "string" and localeId ~= "" then
		Locale.current = string.lower(localeId)
	else
		Locale.current = "en"
	end
	return Locale.current
end

-- Chrome strings stamped onto instances: one property + source list per
-- instance, in a weak-keyed registry so destroyed UI drops out on GC. Never
-- walks the instance tree -- that walk was the multi-second freeze on
-- executors.
local stamped = setmetatable({}, { __mode = "k" })

-- Set inst[property] to the resolved source and remember it, so refresh()
-- can re-resolve it when the locale changes. Callers keep passing their raw
-- source string, never the resolved copy. `wrap` (optional) formats the
-- resolved string, e.g. rich-text font tags around a page title.
function Locale.set(inst, property, source, wrap)
	if inst == nil or source == nil then
		return
	end
	local function paint(value)
		local resolved = Locale.resolve(value)
		return wrap and wrap(resolved) or resolved
	end
	local list = stamped[inst]
	if not list then
		list = {}
		stamped[inst] = list
	end
	for _, entry in ipairs(list) do
		if entry.property == property then
			entry.source = source
			entry.wrap = wrap
			inst[property] = paint(source)
			return
		end
	end
	list[#list + 1] = { property = property, source = source, wrap = wrap }
	inst[property] = paint(source)
end

-- Re-resolve every stamped string under the active locale. The UI Settings
-- locale dropdown calls this after setActive so a change lands immediately
-- instead of on the next launch.
function Locale.refresh()
	for inst, list in pairs(stamped) do
		for _, entry in ipairs(list) do
			local resolved = Locale.resolve(entry.source)
			inst[entry.property] = entry.wrap and entry.wrap(resolved) or resolved
		end
	end
end

-- The player's language from Roblox's locale id (e.g. "fr-fr"), lowercased
-- and kept whole so a translator sees the exact region; resolve() narrows to
-- the language part when it needs to.
function Locale.detect()
	local ok, id = pcall(function()
		return game:GetService("LocalizationService").RobloxLocaleId
	end)
	if ok and type(id) == "string" and id ~= "" then
		return string.lower(id)
	end
	return "en"
end

return Locale
