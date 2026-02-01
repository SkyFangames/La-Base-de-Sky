#===============================================================================
# Este módulo almacena eventos que pueden ocurrir durante el juego. Un 
# procedimiento puede suscribirse a un evento agregándose a él. Entonces, se 
# llamará cada vez que ocurra el evento. Los eventos existentes son:
#-------------------------------------------------------------------------------
#   :on_game_map_setup - Cuando se configura un Game_Map. Cambia típicamente 
#                      datos de mapa.
#   :on_new_spriteset_map - Cuando se crea un Spriteset_Map. Agrega más cosas 
#                      para mostrar en el overworld.
#   :on_frame_update - Una vez por fotograma. Contadores varios de fotogramas/
#                      tiempo.
#   :on_leave_map - Al salir de un mapa. Finaliza efectos de clima y efectos
#                      expirados.
#   :on_enter_map - Al entrar en un nuevo mapa. Configura nuevos efectos, 
#                      finaliza efectos expirados.
#   :on_map_or_spriteset_change - Al entrar en un nuevo mapa o cuando se creó 
#                      el spriteset. Muestra cosas en pantalla.
#-------------------------------------------------------------------------------
#   :on_player_change_direction - Cuando el jugador se gira en una dirección 
#                      diferente.
#   :on_leave_tile - Cuando cualquier evento o el jugador comienza a moverse 
#                      desde una casilla.
#   :on_step_taken - Cuando cualquier evento o el jugador termina de dar un paso.
#   :on_player_step_taken - Cuando el jugador termina un paso/termina de surfear,
#                      excepto como parte de una ruta de movimiento. Contadores 
#                      basados en pasos.
#   :on_player_step_taken_can_transfer - Cuando el jugador termina de dar un paso/
#                      termina de surfear, excepto como parte de una ruta de 
#                      movimiento. Efectos basados en pasos que pueden transferir 
#                      al jugador a otro lugar.
#   :on_player_interact - Cuando el jugador presiona el botón de Usar en el 
#                      overworld.
#-------------------------------------------------------------------------------
#   :on_trainer_load - Cuando se genera un NPCTrainer (para luchar contra él o 
#                      como compañero acompañante). Varias modificaciones a ese 
#                      entrenador y sus Pokémon.
#   :on_wild_species_chosen - Cuando se elige una especie/nivel para un encuentro
#                      salvaje. Cambia la especie/nivel (por ejemplo, errante, 
#                      cadena del Poké Radar).
#   :on_wild_pokemon_created - Cuando se ha creado un Pokémon como "objeto" para 
#                      un encuentro salvaje. Varias modificaciones a ese Pokémon.
#   :on_calling_wild_battle - Cuando se llama a una batalla salvaje. Evita esa 
#                      batalla salvaje y en su lugar inicia un tipo de batalla 
#                      diferente (por ejemplo, Zona Safari).
#   :on_start_battle - Justo antes de que comience una batalla. Memoriza/
#                      restablece información sobre los Pokémon del grupo, que 
#                      se utiliza después de la batalla para comprobaciones de 
#                      evolución.
#   :on_end_battle - Justo después de que termina una batalla. Comprobaciones de
#                      evolución, Recogida/Recogida de miel, desmayo.
#   :on_wild_battle_end - Después de una batalla salvaje. Actualiza la 
#                      información de la cadena del Poké Radar.
#===============================================================================

module EventHandlers
  @@events = {}

  module_function

  # Add a named callback for the given event.
  def add(event, key, proc)
    @@events[event] = NamedEvent.new if !@@events.has_key?(event)
    @@events[event].add(key, proc)
  end

  # Remove a named callback from the given event.
  def remove(event, key)
    @@events[event]&.remove(key)
  end

  # Clear all callbacks for the given event.
  def clear(key)
    @@events[key]&.clear
  end

  # Trigger all callbacks from an Event if it has been defined.
  def trigger(event, *args)
    return @@events[event]&.trigger(*args)
  end
end

#===============================================================================
# This module stores the contents of various menus. Each command in a menu is a
# hash of data (containing its name, relative order, code to run when chosen,
# etc.).
# Menus that use this module are:
#-------------------------------------------------------------------------------
# Pause menu
# Party screen main interact menu
# Pokégear main menu
# Options screen
# PC main menu
# Various debug menus (main, Pokémon, battle, battle Pokémon)
#===============================================================================
module MenuHandlers
  @@handlers = {}

  module_function

  def add(menu, option, hash)
    @@handlers[menu] = HandlerHash.new if !@@handlers.has_key?(menu)
    @@handlers[menu].add(option, hash)
  end

  def remove(menu, option)
    @@handlers[menu]&.remove(option)
  end

  def clear(menu)
    @@handlers[menu]&.clear
  end

  def get(menu, option)
    return @@handlers[menu][option]
  end

  def each(menu)
    return if !@@handlers.has_key?(menu)
    @@handlers[menu].each { |option, hash| yield option, hash }
  end

  def each_available(menu, *args)
    return if !@@handlers.has_key?(menu)
    options = @@handlers[menu]
    keys = options.keys
    sorted_keys = keys.sort_by { |option| options[option]["order"] || keys.index(option) }
    sorted_keys.each do |option|
      hash = options[option]
      next if hash["condition"] && !hash["condition"].call(*args)
      if hash["multi_options"]
        extra_options = hash["multi_options"].call(*args)
        if extra_options && extra_options.length > 0
          extra_options.each { |opt| yield opt[0], hash, opt[1] }
        end
        next
      end
      if hash["name"].is_a?(Proc)
        name = hash["name"].call(*args)
      else
        name = _INTL(hash["name"])
      end
      yield option, hash, name
    end
  end

  def call(menu, option, function, *args)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash || !option_hash[function]
    return option_hash[function].call(*args)
  end
end

#===============================================================================
# This module stores page definitions for various UI screens that have tabbed
# interfaces. Each page is a hash containing its name, display order, and
# description. Pages are organized by menu.
# UI screens that use this module:
#-------------------------------------------------------------------------------
# Options screen pages (Gameplay, Audio, Graphics, Controls, etc.)
#===============================================================================
module PageHandlers
  @@handlers = {}

  module_function

  def add(menu, page, hash)
    @@handlers[menu] = HandlerHash.new if !@@handlers.has_key?(menu)
    @@handlers[menu].add(page, hash)
  end

  def remove(menu, page)
    @@handlers[menu]&.remove(page)
  end

  def clear(menu)
    @@handlers[menu]&.clear
  end

  def get(menu, page)
    return @@handlers[menu]&.[](page)
  end

  def each(menu)
    return if !@@handlers.has_key?(menu)
    @@handlers[menu].each { |page, hash| yield page, hash }
  end

  def each_available(menu, *args)
    return if !@@handlers.has_key?(menu)
    pages = @@handlers[menu]
    keys = pages.keys
    sorted_keys = keys.sort_by { |page| pages[page][:order] || keys.index(page) }
    sorted_keys.each do |page|
      hash = pages[page]
      next if hash[:condition] && !hash[:condition].call(*args)
      if hash[:name].is_a?(Proc)
        name = hash[:name].call(*args)
      else
        name = _INTL(hash[:name])
      end
      yield page, hash, name
    end
  end

  def has_any?(menu, page)
    # Check if the page exists
    page_options = get(menu, page)
    return false if page_options.nil?
    # Check if there are any MenuHandlers registered for this page
    has_menu_handlers = false
    MenuHandlers.each(menu) do |option, hash|
      if hash["page"] == page
        has_menu_handlers = true
        break
      end
    end
    return has_menu_handlers
  end

  def call(menu, page)
    return @@handlers[menu]&.[](page)
  end
end
