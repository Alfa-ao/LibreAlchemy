--------------------------------------------------------------------------------
-- Core/AlchemyContext.lua
-- Контекст зависимостей.
-- Хранит созданные экземпляры сервисов b n/l/
--------------------------------------------------------------------------------

--- @class AlchemyContext
--- @field private _state table AlchemyState
--- @field private _config table AlchemyConfig
--- @field private _widgetManager table AlchemyWidgetManager
--- @field private _textFormatter table AlchemyTextFormatter
--- @field private _services table Services
Class( "AlchemyContext", {
    _state = nil,
    _config = nil,
    _widgetManager = nil,
    _textFormatter = nil,
    _services = nil,
} )

--------------------------------------------------------------------------------
--- @class AlchemyContextParams
--- @field state table AlchemyState
--- @field config table AlchemyConfig
--- @field widgetManager table AlchemyWidgetManager
--- @field textFormatter table AlchemyTextFormatter
--- @field services table Services

--- Инициализация контекста.
--- @param params AlchemyContextParams
--------------------------------------------------------------------------------
function AlchemyContext:Init( params )
    assert( type( params ) == "table", "AlchemyContext:Init() failed: params must be a table" )

    assert( params.state ~= nil, "AlchemyContext:Init() failed: state is required" )
    assert( params.config ~= nil, "AlchemyContext:Init() failed: config is required" )
    assert( params.widgetManager ~= nil, "AlchemyContext:Init() failed: widgetManager is required" )
    assert( params.textFormatter ~= nil, "AlchemyContext:Init() failed: textFormatter is required" )
    assert( params.services ~= nil, "AlchemyContext:Init() failed: services is required" )

    self._state = params.state
    self._config = params.config
    self._widgetManager = params.widgetManager
    self._textFormatter = params.textFormatter
    self._services = params.services
end

--------------------------------------------------------------------------------
--- @return table AlchemyState
--------------------------------------------------------------------------------
function AlchemyContext:GetState()
    return self._state
end

--------------------------------------------------------------------------------
--- @return table AlchemyConfig
--------------------------------------------------------------------------------
function AlchemyContext:GetConfig()
    return self._config
end

--------------------------------------------------------------------------------
--- @return table AlchemyWidgetManager
--------------------------------------------------------------------------------
function AlchemyContext:GetWidgetManager()
    return self._widgetManager
end

--------------------------------------------------------------------------------
--- @return table AlchemyTextFormatter
--------------------------------------------------------------------------------
function AlchemyContext:GetTextFormatter()
    return self._textFormatter
end

--------------------------------------------------------------------------------
--- @return table Services
--------------------------------------------------------------------------------
function AlchemyContext:GetServices()
    return self._services
end